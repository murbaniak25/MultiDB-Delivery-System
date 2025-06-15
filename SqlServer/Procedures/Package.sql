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
    @PaczkomatDocelowy VARCHAR(10) = NULL
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
        
        -- sortownia nadania (najbliższej nadawcy)
        DECLARE @SortowniaNadaniaID INT;
        SELECT TOP 1 @SortowniaNadaniaID = SortowniaID
        FROM WojewodztwaSortowni
        WHERE Wojewodztwo = @NadawcaWojewodztwo;
        
        IF @SortowniaNadaniaID IS NULL
        BEGIN
            SET @SortowniaNadaniaID = 1;
        END
        
        -- sortownia docelowa
        DECLARE @SortowniaDocelowaID INT;
        SELECT TOP 1 @SortowniaDocelowaID = SortowniaID
        FROM WojewodztwaSortowni
        WHERE Wojewodztwo = @OdbiorcaWojewodztwo;
        
        IF @SortowniaDocelowaID IS NULL
        BEGIN
            SET @SortowniaDocelowaID = 1;
        END
        
        DECLARE @DroppointID INT = NULL;
        IF @PaczkomatDocelowy IS NOT NULL
        BEGIN
            SELECT @DroppointID = DroppointID
            FROM Droppointy d
            INNER JOIN ObiektInfrastruktury o ON d.DroppointID = o.ObiektID
            WHERE o.Nazwa LIKE '%' + @PaczkomatDocelowy + '%'
            AND d.CzyAktywny = 1;
            IF @DroppointID IS NULL
            BEGIN
                RAISERROR('Podany paczkomat docelowy nie istnieje lub jest nieaktywny', 16, 1);
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
            -- Jeśli nie ma wolnego -> najmniej obciążony
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
        DECLARE @Trasa VARCHAR(20);
        
        IF @SortowniaNadaniaID != @SortowniaDocelowaID
        BEGIN
            DECLARE @KodSortowniNadania VARCHAR(3), @KodSortowniDocelowa VARCHAR(3);
            SELECT @KodSortowniNadania = LEFT(o.Nazwa, 3)
            FROM ObiektInfrastruktury o
            WHERE o.ObiektID = @SortowniaNadaniaID;
            
            SELECT @KodSortowniDocelowa = LEFT(o.Nazwa, 3)
            FROM ObiektInfrastruktury o
            WHERE o.ObiektID = @SortowniaDocelowaID;
            
            SET @Trasa = @KodSortowniNadania + '-' + @KodSortowniDocelowa;
            
            IF NOT EXISTS (SELECT 1 FROM CzasyPrzejazdow WHERE Trasa = @Trasa)
            BEGIN
                SET @Trasa = @KodSortowniDocelowa + '-' + @KodSortowniNadania;
            END
            
            SELECT @CzasTransportu = CAST(LEFT(CzasPrzejazdu, CHARINDEX('h', CzasPrzejazdu) - 1) AS INT)
            FROM CzasyPrzejazdow
            WHERE Trasa = @Trasa;
        END
        
        SET @CzasTransportu = @CzasTransportu + 4 + 2; -- 4h sortowanie, 2h dostawa
        
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
        
        INSERT INTO HistoriaStatusowPrzesylek (PrzesylkaID, Status, Opis, LokalizacjaID)
        VALUES (@PrzesylkaID, 'Nadana', 'Przesyłka została nadana i przekazana kurierowi', @SortowniaNadaniaID);
        
        EXEC sp_WyslijNotyfikacjeEmail @PrzesylkaID, 'NADANIE';
        
        COMMIT TRANSACTION;
        
        SELECT 
            @PrzesylkaID AS NowaPrzesylkaID,
            @CzasTransportu AS PrzewidywanyCzasDostawyGodzin,
            DATEADD(HOUR, @CzasTransportu, GETDATE()) AS PrzewidywanaDataDostawy,
            @Trasa AS TrasaPrzesylki;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO