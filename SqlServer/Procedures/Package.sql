USE DeliveryDB;
GO


CREATE OR ALTER PROCEDURE sp_NadajPrzesylkeV2
    @NadawcaID INT,
    @OdbiorcaEmail VARCHAR(100),
    @OdbiorcaImie VARCHAR(50),
    @OdbiorcaNazwisko VARCHAR(100),
    @OdbiorcaTelefon VARCHAR(20),
    @OdbiorcaUlica VARCHAR(100),
    @OdbiorcaKodPocztowy VARCHAR(10),
    @OdbiorcaMiasto VARCHAR(50),
    @OdbiorcaWojewodztwo VARCHAR(50),
    @Gabaryt CHAR(1),
    @PaczkomatDocelowy VARCHAR(10) = NULL, 
    @DostawaDoDomu BIT = 0 -- 0 = paczkomat (wymaga podania paczkomatu), 1 = dostawa do domu
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF NOT EXISTS (SELECT 1 FROM Gabaryty WHERE Gabaryt = @Gabaryt)
        BEGIN
            RAISERROR('Nieprawidłowy gabaryt przesyłki', 16, 1);
            RETURN;
        END
        
        IF @DostawaDoDomu = 0 AND @PaczkomatDocelowy IS NULL
        BEGIN
            RAISERROR('Dla dostawy do paczkomatu wymagane jest podanie nazwy paczkomatu docelowego', 16, 1);
            RETURN;
        END
        
        IF @DostawaDoDomu = 1 AND @PaczkomatDocelowy IS NOT NULL
        BEGIN
            RAISERROR('Dla dostawy do domu nie należy podawać paczkomatu', 16, 1);
            RETURN;
        END
        
        DECLARE @AdresOdbiorcyID INT;
        INSERT INTO Adresy (Ulica, KodPocztowy, Miasto, Wojewodztwo, Kraj)
        VALUES (@OdbiorcaUlica, @OdbiorcaKodPocztowy, @OdbiorcaMiasto, @OdbiorcaWojewodztwo, 'Polska');
        SET @AdresOdbiorcyID = SCOPE_IDENTITY();
        
        DECLARE @OdbiorcaID INT;
        SELECT @OdbiorcaID = KlientID 
        FROM Klienci 
        WHERE Email = @OdbiorcaEmail;
        
        IF @OdbiorcaID IS NULL
        BEGIN
            INSERT INTO Klienci (TypKlienta, Imie, Nazwisko, Email, Telefon, AdresID)
            VALUES ('Osoba', @OdbiorcaImie, @OdbiorcaNazwisko, @OdbiorcaEmail, @OdbiorcaTelefon, @AdresOdbiorcyID);
            SET @OdbiorcaID = SCOPE_IDENTITY();
        END
        
        DECLARE @NadawcaWojewodztwo VARCHAR(50), @AdresNadaniaID INT;
        SELECT @NadawcaWojewodztwo = a.Wojewodztwo, @AdresNadaniaID = k.AdresID
        FROM Klienci k
        INNER JOIN Adresy a ON k.AdresID = a.AdresID
        WHERE k.KlientID = @NadawcaID;
        
        DECLARE @SortowniaNadaniaID INT;
        SELECT TOP 1 @SortowniaNadaniaID = SortowniaID
        FROM WojewodztwaSortowni
        WHERE Wojewodztwo = @NadawcaWojewodztwo;
        
        
        DECLARE @SortowniaDocelowaID INT;
        SELECT TOP 1 @SortowniaDocelowaID = SortowniaID
        FROM WojewodztwaSortowni
        WHERE Wojewodztwo = @OdbiorcaWojewodztwo;
        
        
        DECLARE @DroppointID INT = NULL;
        
        IF @DostawaDoDomu = 0 
        BEGIN
            -- Szukamy podanego paczkomatu
            SELECT @DroppointID = d.DroppointID
            FROM Droppointy d
            INNER JOIN ObiektInfrastruktury o ON d.DroppointID = o.ObiektID
            WHERE o.Nazwa LIKE '%' + @PaczkomatDocelowy + '%'
                AND d.CzyAktywny = 1;
                
            IF @DroppointID IS NULL
            BEGIN
                RAISERROR('Nie znaleziono aktywnego paczkomatu o nazwie: %s', 16, 1, @PaczkomatDocelowy);
                RETURN;
            END
        END

        
        DECLARE @KurierID INT;
        
        SELECT TOP 1 @KurierID = KurierID
        FROM Kurierzy
        WHERE SortowniaID = @SortowniaNadaniaID
            AND Wojewodztwo = @NadawcaWojewodztwo
            AND PrzesylkaID IS NULL
        ORDER BY NEWID(); 
        
        IF @KurierID IS NULL
        BEGIN
            SELECT TOP 1 @KurierID = k.KurierID
            FROM Kurierzy k
            LEFT JOIN (
                SELECT KurierID, COUNT(*) as LiczbaPrzesylek
                FROM OperacjeKurierskie
                WHERE CAST(CzasRozpoczecia AS DATE) = CAST(GETDATE() AS DATE)
                GROUP BY KurierID
            ) ok ON k.KurierID = ok.KurierID
            WHERE k.SortowniaID = @SortowniaNadaniaID
            ORDER BY ISNULL(ok.LiczbaPrzesylek, 0), NEWID();
        END
        
        DECLARE @CzasTransportu INT = 0;
        DECLARE @Trasa VARCHAR(20) = '';
        
        IF @SortowniaNadaniaID != @SortowniaDocelowaID
        BEGIN
            DECLARE @KodSortowniNadania VARCHAR(3), @KodSortowniDocelowa VARCHAR(3);
            
            SELECT @KodSortowniNadania = 
                CASE 
                    WHEN Nazwa LIKE '%Warszawa%' THEN 'WAW'
                    WHEN Nazwa LIKE '%Kraków%' THEN 'KRK'
                    WHEN Nazwa LIKE '%Wrocław%' THEN 'WRO'
                    WHEN Nazwa LIKE '%Gdańsk%' THEN 'GDA'
                    WHEN Nazwa LIKE '%Łódź%' THEN 'LOD'
                    ELSE 'WAW'
                END
            FROM ObiektInfrastruktury
            WHERE ObiektID = @SortowniaNadaniaID;
            
            SELECT @KodSortowniDocelowa = 
                CASE 
                    WHEN Nazwa LIKE '%Warszawa%' THEN 'WAW'
                    WHEN Nazwa LIKE '%Kraków%' THEN 'KRK'
                    WHEN Nazwa LIKE '%Wrocław%' THEN 'WRO'
                    WHEN Nazwa LIKE '%Gdańsk%' THEN 'GDA'
                    WHEN Nazwa LIKE '%Łódź%' THEN 'LOD'
                    ELSE 'WAW'
                END
            FROM ObiektInfrastruktury
            WHERE ObiektID = @SortowniaDocelowaID;
            
            SET @Trasa = @KodSortowniNadania + '-' + @KodSortowniDocelowa;
            
            IF NOT EXISTS (SELECT 1 FROM CzasyPrzejazdow WHERE Trasa = @Trasa)
            BEGIN
                SET @Trasa = @KodSortowniDocelowa + '-' + @KodSortowniNadania;
            END
            
            SELECT @CzasTransportu = 
                CASE 
                    WHEN CHARINDEX('h', CzasPrzejazdu) > 0 
                    THEN CAST(LEFT(CzasPrzejazdu, CHARINDEX('h', CzasPrzejazdu) - 1) AS INT)
                    ELSE 0
                END
            FROM CzasyPrzejazdow
            WHERE Trasa = @Trasa;
            
            IF @CzasTransportu IS NULL OR @CzasTransportu = 0
            BEGIN
                SET @CzasTransportu = 18;
            END
        END
        
        SET @CzasTransportu = @CzasTransportu + 4;
        
        IF @DostawaDoDomu = 1
        BEGIN
            SET @CzasTransportu = @CzasTransportu + 4;
        END
        ELSE
        BEGIN
            SET @CzasTransportu = @CzasTransportu + 2;
        END
        
        INSERT INTO Przesylki (NadawcaID, DroppointID, SortowniaID, KurierID, AdresNadaniaID, Gabaryt)
        VALUES (@NadawcaID, @DroppointID, @SortowniaNadaniaID, @KurierID, @AdresNadaniaID, @Gabaryt);
        
        DECLARE @PrzesylkaID INT = SCOPE_IDENTITY();
        
        INSERT INTO OdbiorcyPrzesylki (PrzesylkaID, OdbiorcaID, CzyGlowny, Kolejnosc)
        VALUES (@PrzesylkaID, @OdbiorcaID, 1, 1);
        
        UPDATE Kurierzy SET PrzesylkaID = @PrzesylkaID WHERE KurierID = @KurierID;
        
        INSERT INTO OperacjeKurierskie (PrzesylkaID, KurierID, CzasRozpoczecia, CzasZakonczenia, Status)
        VALUES (@PrzesylkaID, @KurierID, GETDATE(), GETDATE(), 'Przyjęta do nadania');
        
        INSERT INTO TrasaPrzesylki (PrzesylkaID, SortowniaStartowaID, SortowniaDocelowaID, DataWyjazdu, DataPrzyjazdu)
        VALUES (@PrzesylkaID, @SortowniaNadaniaID, @SortowniaDocelowaID, 
                DATEADD(HOUR, 2, GETDATE()), 
                DATEADD(HOUR, @CzasTransportu, GETDATE()));
        
        DECLARE @OpisStatusu VARCHAR(500);
        SET @OpisStatusu = 'Przesyłka została nadana i przekazana kurierowi. ' +
            CASE 
                WHEN @DostawaDoDomu = 1 THEN 'Dostawa do adresu domowego.'
                ELSE 'Dostawa do paczkomatu ' + @PaczkomatDocelowy + '.'
            END;
            
        INSERT INTO HistoriaStatusowPrzesylek (PrzesylkaID, Status, Opis, LokalizacjaID)
        VALUES (@PrzesylkaID, 'Nadana', @OpisStatusu, @SortowniaNadaniaID);
        
        EXEC sp_WyslijNotyfikacjeEmail @PrzesylkaID, 'NADANIE';
        
        COMMIT TRANSACTION;
        
        SELECT 
            @PrzesylkaID AS NowaPrzesylkaID,
            @CzasTransportu AS PrzewidywanyCzasDostawyGodzin,
            DATEADD(HOUR, @CzasTransportu, GETDATE()) AS PrzewidywanaDataDostawy,
            @Trasa AS TrasaPrzesylki,
            CASE 
                WHEN @DostawaDoDomu = 1 THEN 'Dostawa do domu'
                ELSE 'Dostawa do paczkomatu: ' + @PaczkomatDocelowy
            END AS TypDostawy;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO