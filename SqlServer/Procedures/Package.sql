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
    @DostawaDoDomu BIT = 0 -- 0 = paczkomat, 1 = dostawa do domu
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

        IF @SortowniaNadaniaID IS NULL
            SET @SortowniaNadaniaID = 1;

        DECLARE @DroppointID INT = NULL;
        DECLARE @SortowniaDocelowaID INT;
        DECLARE @WojewodztwoDocelowe VARCHAR(50);

        IF @DostawaDoDomu = 0
        BEGIN
            SELECT @DroppointID = d.DroppointID
            FROM Droppointy d
            INNER JOIN ObiektInfrastruktury o ON d.DroppointID = o.ObiektID
            WHERE o.Nazwa LIKE '%' + @PaczkomatDocelowy + '%'
                AND d.CzyAktywny = 1
                AND NOT EXISTS (
                    SELECT 1 FROM AwarieInfrastruktury ai
                    WHERE ai.TypObiektu = 'DropPoint'
                        AND ai.ObiektID = d.DroppointID
                        AND ai.Status IN ('Otwarta', 'W trakcie')
                );

            IF @DroppointID IS NULL
            BEGIN
                RAISERROR('Nie znaleziono sprawnego, aktywnego paczkomatu o nazwie: %s', 16, 1, @PaczkomatDocelowy);
                RETURN;
            END

            IF NOT EXISTS (
                SELECT 1
                FROM SkrytkiPaczkomatow s
                WHERE s.DroppointID = @DroppointID
                    AND s.Status = 'Wolna'
                    AND NOT EXISTS (
                        SELECT 1 FROM AwarieInfrastruktury ai
                        WHERE ai.TypObiektu = 'Skrytka'
                            AND ai.ObiektID = s.SkrytkaID
                            AND ai.Status IN ('Otwarta', 'W trakcie')
                    )
            )
            BEGIN
                RAISERROR('Wybrany paczkomat jest pełny lub wszystkie skrytki są niesprawne.', 16, 1);
                RETURN;
            END

            SELECT @SortowniaDocelowaID = d.SortowniaID
            FROM Droppointy d
            WHERE d.DroppointID = @DroppointID;

            SELECT @WojewodztwoDocelowe = a.Wojewodztwo
            FROM Droppointy d
            INNER JOIN ObiektInfrastruktury o ON d.DroppointID = o.ObiektID
            INNER JOIN Adresy a ON o.AdresID = a.AdresID
            WHERE d.DroppointID = @DroppointID;
        END
        ELSE
        BEGIN
            SET @WojewodztwoDocelowe = @OdbiorcaWojewodztwo;
            SELECT TOP 1 @SortowniaDocelowaID = SortowniaID
            FROM WojewodztwaSortowni
            WHERE Wojewodztwo = @WojewodztwoDocelowe;

            IF @SortowniaDocelowaID IS NULL
                SET @SortowniaDocelowaID = 1;
        END

        DECLARE @RekomendowanyKurierID INT = NULL;
        
        BEGIN TRY
            DECLARE @OracleQuery NVARCHAR(500);
            SET @OracleQuery = 'SELECT F_REKOMENDUJ_KURIERA(' + 
                CAST(@SortowniaNadaniaID AS VARCHAR) + ', ''' + 
                @NadawcaWojewodztwo + ''', ''' + 
                @Gabaryt + ''') AS RekomendowanyKurier FROM dual';

            DECLARE @TempTable TABLE (RekomendowanyKurier INT);
            INSERT INTO @TempTable
            EXEC('SELECT * FROM OPENQUERY(ORACLE_ANALYTICS, ''' + @OracleQuery + ''')');
            
            SELECT @RekomendowanyKurierID = RekomendowanyKurier 
            FROM @TempTable 
            WHERE RekomendowanyKurier IS NOT NULL;

        END TRY
        BEGIN CATCH
            PRINT 'Oracle Analytics niedostępny (Błąd: ' + ERROR_MESSAGE() + ')';
            SET @RekomendowanyKurierID = NULL;
        END CATCH

        DECLARE @KurierID INT;
        
        IF @RekomendowanyKurierID IS NOT NULL AND EXISTS (
            SELECT 1 FROM Kurierzy WHERE KurierID = @RekomendowanyKurierID AND SortowniaID = @SortowniaNadaniaID
        )
        BEGIN
            SET @KurierID = @RekomendowanyKurierID;
        END
        ELSE
        BEGIN
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
        -- Dodanie czasu przetwarzania w sortowni (4h)
        SET @CzasTransportu = @CzasTransportu + 4;

        -- Dodanie czasu doręczenia: 4h dla dostawy do domu, 2h dla paczkomatu
        IF @DostawaDoDomu = 1
        BEGIN
            SET @CzasTransportu = @CzasTransportu + 4;
        END
        ELSE
        BEGIN
            SET @CzasTransportu = @CzasTransportu + 2;
        END

        DECLARE @PrzewidywanaDataDostawy DATETIME = DATEADD(HOUR, @CzasTransportu, GETDATE());
        DECLARE @GodzinaPrzewidywana INT = DATEPART(HOUR, @PrzewidywanaDataDostawy);

        IF @GodzinaPrzewidywana < 8
        BEGIN
            SET @PrzewidywanaDataDostawy = DATEADD(HOUR, 8 - @GodzinaPrzewidywana, @PrzewidywanaDataDostawy);
            SET @PrzewidywanaDataDostawy = DATEADD(MINUTE, -DATEPART(MINUTE, @PrzewidywanaDataDostawy), @PrzewidywanaDataDostawy);
            SET @PrzewidywanaDataDostawy = DATEADD(SECOND, -DATEPART(SECOND, @PrzewidywanaDataDostawy), @PrzewidywanaDataDostawy);
        END
        ELSE IF @GodzinaPrzewidywana >= 20
        BEGIN
            SET @PrzewidywanaDataDostawy = DATEADD(DAY, 1, CAST(@PrzewidywanaDataDostawy AS DATE));
            SET @PrzewidywanaDataDostawy = DATEADD(HOUR, 8, @PrzewidywanaDataDostawy);
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
                WHEN @DostawaDoDomu = 1 THEN 'Dostawa do adresu domowego w województwie ' + @WojewodztwoDocelowe + '.'
                ELSE 'Dostawa do paczkomatu ' + @PaczkomatDocelowy + ' (sortownia: ' + CAST(@SortowniaDocelowaID AS VARCHAR) + ').'
            END;

        INSERT INTO HistoriaStatusowPrzesylek (PrzesylkaID, Status, Opis, LokalizacjaID)
        VALUES (@PrzesylkaID, 'Nadana', @OpisStatusu, @SortowniaNadaniaID);

        EXEC sp_WyslijNotyfikacjeEmail @PrzesylkaID, 'NADANIE';

        IF @DostawaDoDomu = 0
        BEGIN
            EXEC sp_PrzypiszDoSkrytkiZKodem @PrzesylkaID;
        END

        COMMIT TRANSACTION;

        SELECT
            @PrzesylkaID AS NowaPrzesylkaID,
            @PrzewidywanaDataDostawy AS PrzewidywanaDataDostawy,
            @Trasa AS TrasaPrzesylki,
            CASE
                WHEN @DostawaDoDomu = 1 THEN 'Dostawa do domu'
                ELSE 'Dostawa do paczkomatu: ' + @PaczkomatDocelowy
            END AS TypDostawy,
            @SortowniaNadaniaID AS SortowniaNadania,
            @SortowniaDocelowaID AS SortowniaDocelowa,
            @KurierID AS WybranyKurierID,
            CASE
                WHEN @DostawaDoDomu = 1 THEN @WojewodztwoDocelowe
                ELSE (SELECT a.Wojewodztwo FROM ObiektInfrastruktury o
                      INNER JOIN Adresy a ON o.AdresID = a.AdresID
                      WHERE o.ObiektID = @DroppointID)
            END AS WojewodztwoDocelowe,
            CASE
                WHEN @DostawaDoDomu = 0
                THEN (SELECT TOP 1 o.Nazwa
                      FROM ObiektInfrastruktury o
                      WHERE o.ObiektID = @DroppointID)
                ELSE NULL
            END AS PaczkomatDocelowy,
            CASE
                WHEN @DostawaDoDomu = 0
                THEN (SELECT TOP 1 SkrytkaID
                      FROM Przesylki
                      WHERE PrzesylkaID = @PrzesylkaID)
                ELSE NULL
            END AS SkrytkaID,
            CASE
                WHEN @DostawaDoDomu = 0
                THEN (SELECT TOP 1 KodOdbioru
                      FROM KodyOdbioru
                      WHERE PrzesylkaID = @PrzesylkaID
                        AND DataWygasniecia > GETDATE()
                      ORDER BY DataWygasniecia DESC)
                ELSE NULL
            END AS KodOdbioru;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
