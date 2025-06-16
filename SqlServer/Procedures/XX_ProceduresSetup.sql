USE DeliveryDB;
GO

CREATE OR ALTER PROCEDURE sp_DodajKlienta
    @TypKlienta VARCHAR(20),
    @Imie VARCHAR(50) = NULL,
    @Nazwisko VARCHAR(100) = NULL,
    @NazwaFirmy VARCHAR(100) = NULL,
    @Nip VARCHAR(15) = NULL,
    @Email VARCHAR(100),
    @Telefon VARCHAR(20),
    @Ulica VARCHAR(100),
    @KodPocztowy VARCHAR(10),
    @Miasto VARCHAR(50),
    @Wojewodztwo VARCHAR(50),
    @Kraj VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF @TypKlienta NOT IN ('Osoba', 'Firma')
        BEGIN
            RAISERROR('Nieprawid³owy typ klienta. Dozwolone: Osoba, Firma', 16, 1);
            RETURN;
        END
        
        IF @TypKlienta = 'Osoba' AND (@Imie IS NULL OR @Nazwisko IS NULL)
        BEGIN
            RAISERROR('Dla typu Osoba wymagane s¹ Imiê i Nazwisko', 16, 1);
            RETURN;
        END
        
        IF @TypKlienta = 'Firma' AND (@NazwaFirmy IS NULL OR @Nip IS NULL)
        BEGIN
            RAISERROR('Dla typu Firma wymagane s¹ NazwaFirmy i NIP', 16, 1);
            RETURN;
        END
        
        DECLARE @AdresID INT;
        
        INSERT INTO Adresy (Ulica, KodPocztowy, Miasto, Wojewodztwo, Kraj)
        VALUES (@Ulica, @KodPocztowy, @Miasto, @Wojewodztwo, @Kraj);
        
        SET @AdresID = SCOPE_IDENTITY();
        
        INSERT INTO Klienci (TypKlienta, Imie, Nazwisko, NazwaFirmy, Nip, Email, Telefon, AdresID)
        VALUES (@TypKlienta, @Imie, @Nazwisko, @NazwaFirmy, @Nip, @Email, @Telefon, @AdresID);
        
        DECLARE @KlientID INT = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
        
        SELECT @KlientID AS NowyKlientID;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;

 
GO

CREATE OR ALTER PROCEDURE sp_ZglosAwarie
    @TypObiektu VARCHAR(20),
    @ObiektID INT,
    @Opis VARCHAR(500),
    @Priorytet VARCHAR(10),
    @PracownikID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @Priorytet NOT IN ('Niski', 'Sredni', 'Wysoki', 'Krytyczny')
        BEGIN
            SET @Priorytet = 'Sredni';
        END
        
        IF @TypObiektu NOT IN ('Sortownia', 'DropPoint', 'Skrytka')
        BEGIN
            RAISERROR('Nieprawid³owy typ obiektu', 16, 1);
            RETURN;
        END
        
        INSERT INTO AwarieInfrastruktury (TypObiektu, ObiektID, Opis, Priorytet, PracownikID)
        VALUES (@TypObiektu, @ObiektID, @Opis, @Priorytet, @PracownikID);
        
        DECLARE @AwariaID INT = SCOPE_IDENTITY();
        
        IF @Priorytet = 'Krytyczny' AND @TypObiektu = 'DropPoint'
        BEGIN
            UPDATE Droppointy SET CzyAktywny = 0 WHERE DroppointID = @ObiektID;
        END
        
        SELECT @AwariaID AS NowaAwariaID;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_ZglosBlad
    @KodBledu VARCHAR(10),
    @OpisZgloszenia VARCHAR(500),
    @ZrodloZgloszenia VARCHAR(20),
    @PracownikID INT = NULL,
    @KurierID INT = NULL,
    @KlientID INT = NULL,
    @ObiektID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM KodyBledow WHERE KodBledu = @KodBledu)
        BEGIN
            RAISERROR('Nieznany kod b³êdu', 16, 1);
            RETURN;
        END
        
        IF @ZrodloZgloszenia NOT IN ('Kurier', 'Pracownik', 'Uzytkownik')
        BEGIN
            RAISERROR('Nieprawid³owe Ÿród³o zg³oszenia', 16, 1);
            RETURN;
        END
        
        INSERT INTO ZgloszeniaBledow (
            KodBledu, OpisZgloszenia, ZrodloZgloszenia, 
            PracownikID, KurierID, KlientID, ObiektID
        )
        VALUES (
            @KodBledu, @OpisZgloszenia, @ZrodloZgloszenia,
            @PracownikID, @KurierID, @KlientID, @ObiektID
        );
        
        SELECT SCOPE_IDENTITY() AS ZgloszenieID;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO


CREATE OR ALTER PROCEDURE sp_AktualizujStatusAwarii
    @AwariaID INT,
    @NowyStatus VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @NowyStatus NOT IN ('Otwarta', 'W trakcie', 'Naprawiona', 'Anulowana')
        BEGIN
            RAISERROR('Nieprawid³owy status awarii', 16, 1);
            RETURN;
        END
        
        UPDATE AwarieInfrastruktury 
        SET Status = @NowyStatus 
        WHERE AwariaID = @AwariaID;
        
        IF @NowyStatus = 'Naprawiona'
        BEGIN
            DECLARE @TypObiektu VARCHAR(20), @ObiektID INT;
            
            SELECT @TypObiektu = TypObiektu, @ObiektID = ObiektID
            FROM AwarieInfrastruktury
            WHERE AwariaID = @AwariaID;
            
            IF @TypObiektu = 'DropPoint'
            BEGIN
                UPDATE Droppointy SET CzyAktywny = 1 WHERE DroppointID = @ObiektID;
            END
        END
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

USE DeliveryDB
GO


CREATE OR ALTER PROCEDURE sp_GenerujKodOdbioru
    @KodOdbioru VARCHAR(6) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Znaki VARCHAR(36) = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    DECLARE @i INT = 1;
    
    SET @KodOdbioru = '';
    WHILE @i <= 6
    BEGIN
        SET @KodOdbioru = @KodOdbioru + SUBSTRING(@Znaki, (ABS(CHECKSUM(NEWID())) % 36) + 1, 1);
        SET @i = @i + 1;
    END
END;
GO

 
GO


CREATE OR ALTER PROCEDURE sp_PrzypiszDoSkrytki
    @PrzesylkaID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @Gabaryt CHAR(1), @DroppointID INT, @SkrytkaID INT;
        
        SELECT @Gabaryt = Gabaryt, @DroppointID = DroppointID 
        FROM Przesylki 
        WHERE PrzesylkaID = @PrzesylkaID;
        
        IF NOT EXISTS (SELECT 1 FROM Droppointy WHERE DroppointID = @DroppointID AND Typ = 'Paczkomat')
        BEGIN
            RAISERROR('Przesy³ka nie jest kierowana do paczkomatu', 16, 1);
            RETURN;
        END
        
        SELECT TOP 1 @SkrytkaID = SkrytkaID
        FROM SkrytkiPaczkomatow
        WHERE DroppointID = @DroppointID 
            AND Gabaryt = @Gabaryt 
            AND Status = 'Wolna'
        ORDER BY SkrytkaID;
        
        IF @SkrytkaID IS NULL
        BEGIN
            SELECT TOP 1 @SkrytkaID = SkrytkaID
            FROM SkrytkiPaczkomatow
            WHERE DroppointID = @DroppointID 
                AND Gabaryt > @Gabaryt 
                AND Status = 'Wolna'
            ORDER BY Gabaryt, SkrytkaID;
        END
        
        IF @SkrytkaID IS NULL
        BEGIN
            RAISERROR('Brak wolnych skrytek w paczkomacie', 16, 1);
            RETURN;
        END
        
        UPDATE Przesylki SET SkrytkaID = @SkrytkaID WHERE PrzesylkaID = @PrzesylkaID;
        
        UPDATE SkrytkiPaczkomatow SET Status = 'Zajêta' WHERE SkrytkaID = @SkrytkaID;
        
        DECLARE @OdbiorcaID INT;
        SELECT @OdbiorcaID = OdbiorcaID 
        FROM OdbiorcyPrzesylki 
        WHERE PrzesylkaID = @PrzesylkaID AND CzyGlowny = 1;
        
        
        COMMIT TRANSACTION;
        
        --SELECT @SkrytkaID AS PrzypisanaSkrytkaID;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO



CREATE OR ALTER PROCEDURE sp_SprawdzDostepnoscSkrytek
    @DroppointID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        Gabaryt,
        COUNT(*) AS LiczbaSkrytek,
        COUNT(CASE WHEN Status = 'Wolna' THEN 1 END) AS WolneSkrytki,
        COUNT(CASE WHEN Status = 'Zajêta' THEN 1 END) AS ZajeteSkrytki
    FROM SkrytkiPaczkomatow
    WHERE DroppointID = @DroppointID
    GROUP BY Gabaryt
    ORDER BY Gabaryt;
END;
GO

USE DeliveryDB
GO


CREATE OR ALTER PROCEDURE sp_PrzypiszDoSkrytkiZKodem
    @PrzesylkaID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        EXEC sp_PrzypiszDoSkrytki @PrzesylkaID;
        
        DECLARE @KodOdbioru VARCHAR(6);
        DECLARE @Proby INT = 0;
        
        WHILE @Proby < 10
        BEGIN
            EXEC sp_GenerujKodOdbioru @KodOdbioru OUTPUT;
            
            IF NOT EXISTS (SELECT 1 FROM KodyOdbioru WHERE KodOdbioru = @KodOdbioru AND CzyUzyty = 0)
            BEGIN
                BREAK;
            END
            
            SET @Proby = @Proby + 1;
        END
        
        INSERT INTO KodyOdbioru (PrzesylkaID, KodOdbioru, DataWygasniecia)
        VALUES (@PrzesylkaID, @KodOdbioru, DATEADD(DAY, 2, GETDATE()));
        
        DECLARE @OdbiorcaEmail VARCHAR(100);
        SELECT @OdbiorcaEmail = k.Email
        FROM OdbiorcyPrzesylki op
        INNER JOIN Klienci k ON op.OdbiorcaID = k.KlientID
        WHERE op.PrzesylkaID = @PrzesylkaID AND op.CzyGlowny = 1;
        
        DECLARE @TrescEmail VARCHAR(MAX);
        SET @TrescEmail = '<h2>Twoja przesy³ka czeka na odbiór!</h2>' +
                         '<p>Kod odbioru: <strong style="font-size: 24px; color: #FF6B00;">' + @KodOdbioru + '</strong></p>' +
                         '<p>Kod jest wa¿ny przez 48 godzin.</p>';
        
        INSERT INTO KolejkaNotyfikacji (AdresEmail, Temat, TrescHTML, TrescTekst, TypZdarzenia)
        VALUES (@OdbiorcaEmail, 
                'Kod odbioru przesy³ki #' + CAST(@PrzesylkaID AS VARCHAR(10)) + ': ' + @KodOdbioru,
                @TrescEmail,
                'Twoja przesy³ka czeka na odbiór. Kod odbioru: ' + @KodOdbioru + '. Kod jest wa¿ny przez 48 godzin.',
                'KOD_ODBIORU');
        
        COMMIT TRANSACTION;
        
        --SELECT @KodOdbioru AS KodOdbioru;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

USE DeliveryDB
GO

CREATE OR ALTER PROCEDURE sp_WyslijNotyfikacjeEmail
    @PrzesylkaID INT,
    @TypZdarzenia VARCHAR(50),
    @DodatkoweParametry VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @TematEmaila VARCHAR(200);
        DECLARE @TrescHTML VARCHAR(MAX);
        DECLARE @TrescTekst VARCHAR(1000);
        DECLARE @EmailNadawcy VARCHAR(100);
        DECLARE @EmailOdbiorcy VARCHAR(100);
        
        SELECT @TematEmaila = TematEmaila, @TrescHTML = TrescHTML, @TrescTekst = TrescTekst
        FROM SzablonyNotyfikacji
        WHERE TypZdarzenia = @TypZdarzenia AND CzyAktywny = 1;
        
        IF @TematEmaila IS NULL
        BEGIN
            RETURN; 
        END
        
        SELECT 
            @EmailNadawcy = kn.Email,
            @EmailOdbiorcy = ko.Email
        FROM Przesylki p
        INNER JOIN Klienci kn ON p.NadawcaID = kn.KlientID
        INNER JOIN OdbiorcyPrzesylki op ON p.PrzesylkaID = op.PrzesylkaID AND op.CzyGlowny = 1
        INNER JOIN Klienci ko ON op.OdbiorcaID = ko.KlientID
        WHERE p.PrzesylkaID = @PrzesylkaID;
        
        SET @TematEmaila = REPLACE(@TematEmaila, '{ID}', CAST(@PrzesylkaID AS VARCHAR(20)));
        SET @TrescHTML = REPLACE(@TrescHTML, '{ID}', CAST(@PrzesylkaID AS VARCHAR(20)));
        SET @TrescTekst = REPLACE(@TrescTekst, '{ID}', CAST(@PrzesylkaID AS VARCHAR(20)));
        
        IF @TypZdarzenia = 'NADANIE'
        BEGIN
            DECLARE @CzasDostawy VARCHAR(50);
            SELECT @CzasDostawy = CONVERT(VARCHAR(50), DataPrzyjazdu, 120)
            FROM TrasaPrzesylki
            WHERE PrzesylkaID = @PrzesylkaID;
            
            SET @TrescHTML = REPLACE(@TrescHTML, '{CZAS_DOSTAWY}', @CzasDostawy);
            SET @TrescTekst = REPLACE(@TrescTekst, '{CZAS_DOSTAWY}', @CzasDostawy);
        END
        
        INSERT INTO KolejkaNotyfikacji (AdresEmail, Temat, TrescHTML, TrescTekst, TypZdarzenia)
        VALUES (@EmailNadawcy, @TematEmaila, @TrescHTML, @TrescTekst, @TypZdarzenia);
        
        INSERT INTO KolejkaNotyfikacji (AdresEmail, Temat, TrescHTML, TrescTekst, TypZdarzenia)
        VALUES (@EmailOdbiorcy, @TematEmaila, @TrescHTML, @TrescTekst, @TypZdarzenia);
        
    END TRY
    BEGIN CATCH
        PRINT 'B³¹d wysy³ki notyfikacji: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

USE DeliveryDB
GO

CREATE OR ALTER PROCEDURE sp_AktualizujStatusPrzesylki
    @PrzesylkaID INT,
    @NowyStatus VARCHAR(50),
    @Opis VARCHAR(500) = NULL,
    @LokalizacjaID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO HistoriaStatusowPrzesylek (PrzesylkaID, Status, Opis, LokalizacjaID)
        VALUES (@PrzesylkaID, @NowyStatus, @Opis, @LokalizacjaID);
        
        DECLARE @TypZdarzenia VARCHAR(50);
        SET @TypZdarzenia = CASE @NowyStatus
            WHEN 'W sortowni' THEN 'W_SORTOWNI'
            WHEN 'W transporcie' THEN 'W_TRANSPORCIE'
            WHEN 'W dostawie' THEN 'W_DOSTAWIE'
            WHEN 'W paczkomacie' THEN 'W_PACZKOMACIE'
            WHEN 'Odebrana' THEN 'ODEBRANA'
            ELSE NULL
        END;
        
        IF @TypZdarzenia IS NOT NULL
        BEGIN
            EXEC sp_WyslijNotyfikacjeEmail @PrzesylkaID, @TypZdarzenia;
        END
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO
GO

USE DeliveryDB
GO

CREATE OR ALTER PROCEDURE sp_OdbierzPrzesylkeZKodem
    @PrzesylkaID INT,
    @KodOdbioru VARCHAR(6)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @SkrytkaID INT;
        DECLARE @DroppointID INT;

        IF NOT EXISTS (
            SELECT 1
            FROM KodyOdbioru
            WHERE PrzesylkaID = @PrzesylkaID
              AND KodOdbioru = @KodOdbioru
              AND CzyUzyty = 0
              AND DataWygasniecia >= GETDATE()
        )
        BEGIN
            RAISERROR('Nieprawid³owy lub wygas³y kod odbioru dla podanej przesy³ki.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SELECT @SkrytkaID = SkrytkaID, @DroppointID = DroppointID
        FROM Przesylki
        WHERE PrzesylkaID = @PrzesylkaID;

        IF NOT EXISTS (
            SELECT 1
            FROM HistoriaStatusowPrzesylek
            WHERE PrzesylkaID = @PrzesylkaID
              AND Status = 'W paczkomacie'
        )
        BEGIN
            RAISERROR('Przesy³ka nie jest jeszcze dostêpna do odbioru w paczkomacie.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        EXEC sp_AktualizujStatusPrzesylki 
            @PrzesylkaID = @PrzesylkaID,
            @NowyStatus = 'Dostarczona',
            @Opis = 'Przesy³ka odebrana z paczkomatu przez odbiorcê',
            @LokalizacjaID = @DroppointID;

        UPDATE KodyOdbioru
        SET CzyUzyty = 1,
            DataUzycia = GETDATE()
        WHERE PrzesylkaID = @PrzesylkaID AND KodOdbioru = @KodOdbioru;

        IF @SkrytkaID IS NOT NULL
        BEGIN
            UPDATE SkrytkiPaczkomatow
            SET Status = 'Wolna'
            WHERE SkrytkaID = @SkrytkaID;
        END

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

 
GO


CREATE OR ALTER PROCEDURE sp_RaportPrzesylekKuriera
    @KurierID INT,
    @DataOd DATE,
    @DataDo DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        p.PrzesylkaID,
        k1.Imie + ' ' + k1.Nazwisko AS Nadawca,
        k2.Imie + ' ' + k2.Nazwisko AS Odbiorca,
        p.Gabaryt,
        ok.CzasRozpoczecia,
        ok.CzasZakonczenia,
        ok.Status,
        ok.Uwagi
    FROM OperacjeKurierskie ok
    INNER JOIN Przesylki p ON ok.PrzesylkaID = p.PrzesylkaID
    INNER JOIN Klienci k1 ON p.NadawcaID = k1.KlientID
    INNER JOIN OdbiorcyPrzesylki op ON p.PrzesylkaID = op.PrzesylkaID AND op.CzyGlowny = 1
    INNER JOIN Klienci k2 ON op.OdbiorcaID = k2.KlientID
    WHERE ok.KurierID = @KurierID
        AND CAST(ok.CzasRozpoczecia AS DATE) BETWEEN @DataOd AND @DataDo
    ORDER BY ok.CzasRozpoczecia DESC;
END;
GO

CREATE OR ALTER PROCEDURE sp_StatystykiSortowni
    @SortowniaID INT,
    @Miesiac INT,
    @Rok INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        COUNT(DISTINCT p.PrzesylkaID) AS LiczbaPrzesylek,
        COUNT(DISTINCT os.PracownikID) AS LiczbaPracownikow,
        COUNT(DISTINCT os.OperacjaID) AS LiczbaOperacji,
        AVG(DATEDIFF(MINUTE, os.CzasRozpoczecia, os.CzasZakonczenia)) AS SredniCzasOperacji,
        COUNT(DISTINCT CASE WHEN z.Status IN ('Nowy', 'W trakcie') THEN z.ZwrotID END) AS AktywneZwroty
    FROM Sortownie s
    LEFT JOIN Przesylki p ON s.SortowniaID = p.SortowniaID
    LEFT JOIN OperacjeSortownicze os ON p.PrzesylkaID = os.PrzesylkaID
    LEFT JOIN Zwroty z ON p.PrzesylkaID = z.PrzesylkaID
    WHERE s.SortowniaID = @SortowniaID
        AND MONTH(os.CzasRozpoczecia) = @Miesiac
        AND YEAR(os.CzasRozpoczecia) = @Rok
    GROUP BY s.SortowniaID;
END;
GO

 
GO

CREATE OR ALTER PROCEDURE sp_ZarejestrujZwrot
    @KlientID INT,
    @PrzesylkaID INT,
    @Przyczyna VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF NOT EXISTS (
            SELECT 1 FROM OdbiorcyPrzesylki 
            WHERE PrzesylkaID = @PrzesylkaID AND OdbiorcaID = @KlientID
        )
        BEGIN
            RAISERROR('Klient nie jest odbiorc¹ tej przesy³ki', 16, 1);
            RETURN;
        END
        
        IF EXISTS (
            SELECT 1 FROM Zwroty 
            WHERE PrzesylkaID = @PrzesylkaID 
                AND Status IN ('Nowy', 'W trakcie')
        )
        BEGIN
            RAISERROR('Dla tej przesy³ki istnieje ju¿ aktywny zwrot', 16, 1);
            RETURN;
        END

        IF NOT EXISTS (
            SELECT 1 FROM HistoriaStatusowPrzesylek
            WHERE PrzesylkaID = @PrzesylkaID
              AND Status IN ('Dostarczona', 'W paczkomacie')
        )
        BEGIN
            RAISERROR('Zwrot mo¿liwy tylko dla przesy³ek dostarczonych lub oczekuj¹cych w paczkomacie.', 16, 1);
            RETURN;
        END
        DECLARE @DataDostarczenia DATETIME;

        SELECT TOP 1 @DataDostarczenia = DataZmiany
        FROM HistoriaStatusowPrzesylek
        WHERE PrzesylkaID = @PrzesylkaID
        AND Status IN ('Dostarczona', 'W paczkomacie')
        ORDER BY DataZmiany DESC;

        IF @DataDostarczenia IS NULL
        BEGIN
            RAISERROR('Zwrot mo¿liwy tylko dla przesy³ek dostarczonych lub oczekuj¹cych w paczkomacie.', 16, 1);
            RETURN;
        END

        IF DATEDIFF(DAY, @DataDostarczenia, GETDATE()) > 14
        BEGIN
            RAISERROR('Min¹³ maksymalny czas na zwrot przesy³ki (14 dni od dostarczenia).', 16, 1);
            RETURN;
        END

        
        INSERT INTO Zwroty (KlientID, PrzesylkaID, Data, Przyczyna, Status)
        VALUES (@KlientID, @PrzesylkaID, GETDATE(), @Przyczyna, 'Nowy');
        
        DECLARE @ZwrotID INT = SCOPE_IDENTITY();
        
        INSERT INTO HistoriaStatusowPrzesylek (PrzesylkaID, Status, Opis, LokalizacjaID)
        VALUES (@PrzesylkaID, 'Zwrot w toku', 'Rozpoczêto proces zwrotu przesy³ki przez odbiorcê', NULL);

        DECLARE @SkrytkaID INT;
        SELECT @SkrytkaID = SkrytkaID FROM Przesylki WHERE PrzesylkaID = @PrzesylkaID;
        IF @SkrytkaID IS NOT NULL
        BEGIN
            UPDATE SkrytkiPaczkomatow SET Status = 'Wolna' WHERE SkrytkaID = @SkrytkaID;
            UPDATE Przesylki SET SkrytkaID = NULL WHERE PrzesylkaID = @PrzesylkaID;
        END

        DECLARE @SortowniaOdbiorcyID INT, @KurierID INT, @AdresOdbiorcyID INT;
        SELECT TOP 1 @SortowniaOdbiorcyID = s.SortowniaID, @AdresOdbiorcyID = k.AdresID
        FROM OdbiorcyPrzesylki op
        INNER JOIN Klienci k ON op.OdbiorcaID = k.KlientID
        INNER JOIN Adresy a ON k.AdresID = a.AdresID
        INNER JOIN WojewodztwaSortowni s ON a.Wojewodztwo = s.Wojewodztwo
        WHERE op.PrzesylkaID = @PrzesylkaID AND op.CzyGlowny = 1;

        SELECT TOP 1 @KurierID = KurierID
        FROM Kurierzy
        WHERE SortowniaID = @SortowniaOdbiorcyID
        ORDER BY NEWID();

        INSERT INTO OperacjeKurierskie (PrzesylkaID, KurierID, CzasRozpoczecia, CzasZakonczenia, Status)
        VALUES (@PrzesylkaID, @KurierID, GETDATE(), GETDATE(), 'Zwrot - odbiór od odbiorcy');


        DECLARE @SortowniaNadawcyID INT, @NadawcaID INT;
        SELECT @NadawcaID = NadawcaID FROM Przesylki WHERE PrzesylkaID = @PrzesylkaID;
        SELECT TOP 1 @SortowniaNadawcyID = s.SortowniaID
        FROM Klienci k
        INNER JOIN Adresy a ON k.AdresID = a.AdresID
        INNER JOIN WojewodztwaSortowni s ON a.Wojewodztwo = s.Wojewodztwo
        WHERE k.KlientID = @NadawcaID;



        INSERT INTO TrasaPrzesylki (PrzesylkaID, SortowniaStartowaID, SortowniaDocelowaID, DataWyjazdu, DataPrzyjazdu)
        VALUES (
            @PrzesylkaID, 
            @SortowniaOdbiorcyID, 
            @SortowniaNadawcyID, 
            GETDATE(), 
            DATEADD(HOUR, 24, GETDATE())
        );

        EXEC sp_WyslijNotyfikacjeEmail @PrzesylkaID, 'ZWROT';

        COMMIT TRANSACTION;
        
        SELECT @ZwrotID AS NowyZwrotID;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

 
GO

CREATE OR ALTER PROCEDURE sp_UstalTrasePrzesylki
    @PrzesylkaID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @SortowniaStartowaID INT, @DroppointID INT, @WojewodztwoDocelowe VARCHAR(50);
        DECLARE @SortowniaDocelowaID INT;
        
        SELECT 
            @SortowniaStartowaID = p.SortowniaID,
            @DroppointID = p.DroppointID
        FROM Przesylki p
        WHERE p.PrzesylkaID = @PrzesylkaID;
        
        SELECT @WojewodztwoDocelowe = a.Wojewodztwo
        FROM Droppointy d
        INNER JOIN ObiektInfrastruktury o ON d.DroppointID = o.ObiektID
        INNER JOIN Adresy a ON o.AdresID = a.AdresID
        WHERE d.DroppointID = @DroppointID;
        
        SELECT TOP 1 @SortowniaDocelowaID = SortowniaID
        FROM WojewodztwaSortowni
        WHERE Wojewodztwo = @WojewodztwoDocelowe
        ORDER BY SortowniaID;
        
        IF @SortowniaDocelowaID IS NULL
        BEGIN
            SELECT @SortowniaDocelowaID = SortowniaID 
            FROM Droppointy 
            WHERE DroppointID = @DroppointID;
        END
        
        IF NOT EXISTS (SELECT 1 FROM TrasaPrzesylki WHERE PrzesylkaID = @PrzesylkaID)
        BEGIN
            INSERT INTO TrasaPrzesylki (PrzesylkaID, SortowniaStartowaID, SortowniaDocelowaID, DataWyjazdu)
            VALUES (@PrzesylkaID, @SortowniaStartowaID, @SortowniaDocelowaID, DATEADD(HOUR, 2, GETDATE()));
        END
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


CREATE OR ALTER PROCEDURE sp_ZarejestrujOperacjeSortownicza
    @PrzesylkaID INT,
    @PracownikID INT,
    @TypOperacji VARCHAR(50),
    @Uwagi VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @CzasRozpoczecia DATETIME2 = GETDATE();
        DECLARE @Status VARCHAR(20) = 'Zakoñczona';
        
        INSERT INTO OperacjeSortownicze (PrzesylkaID, PracownikID, TypOperacji, CzasRozpoczecia, CzasZakonczenia, Status, Uwagi)
        VALUES (@PrzesylkaID, @PracownikID, @TypOperacji, @CzasRozpoczecia, GETDATE(), @Status, @Uwagi);
        
        DECLARE @OperacjaID INT = SCOPE_IDENTITY();
        
        IF @TypOperacji = 'Sortowanie do wysy³ki'
        BEGIN
            EXEC sp_UstalTrasePrzesylki @PrzesylkaID;
        END
        
        SELECT @OperacjaID AS NowaOperacjaID;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO


 
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
            RAISERROR('Nieprawid³owy gabaryt przesy³ki', 16, 1);
            RETURN;
        END
        
        IF @DostawaDoDomu = 0 AND @PaczkomatDocelowy IS NULL
        BEGIN
            RAISERROR('Dla dostawy do paczkomatu wymagane jest podanie nazwy paczkomatu docelowego', 16, 1);
            RETURN;
        END
        
        IF @DostawaDoDomu = 1 AND @PaczkomatDocelowy IS NOT NULL
        BEGIN
            RAISERROR('Dla dostawy do domu nie nale¿y podawaæ paczkomatu', 16, 1);
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
                AND NOT EXISTS (
                        SELECT 1 FROM AwarieInfrastruktury ai
                        WHERE ai.TypObiektu = 'Skrytka'
                        AND ai.ObiektID = s.SkrytkaID
                        AND ai.Status IN ('Otwarta', 'W trakcie')
                )
            )
            BEGIN
                RAISERROR('Wybrany paczkomat jest pe³ny lub wszystkie skrytki s¹ niesprawne.', 16, 1);
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
                    WHEN Nazwa LIKE '%Wroc³aw%' THEN 'WRO'
                    WHEN Nazwa LIKE '%Gdañsk%' THEN 'GDA'
                    WHEN Nazwa LIKE '%£ódŸ%' THEN 'LOD'
                    ELSE 'WAW'
                END
            FROM ObiektInfrastruktury
            WHERE ObiektID = @SortowniaNadaniaID;
            
            SELECT @KodSortowniDocelowa = 
                CASE 
                    WHEN Nazwa LIKE '%Warszawa%' THEN 'WAW'
                    WHEN Nazwa LIKE '%Kraków%' THEN 'KRK'
                    WHEN Nazwa LIKE '%Wroc³aw%' THEN 'WRO'
                    WHEN Nazwa LIKE '%Gdañsk%' THEN 'GDA'
                    WHEN Nazwa LIKE '%£ódŸ%' THEN 'LOD'
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
        VALUES (@PrzesylkaID, @KurierID, GETDATE(), GETDATE(), 'Przyjêta do nadania');
        
        INSERT INTO TrasaPrzesylki (PrzesylkaID, SortowniaStartowaID, SortowniaDocelowaID, DataWyjazdu, DataPrzyjazdu)
        VALUES (@PrzesylkaID, @SortowniaNadaniaID, @SortowniaDocelowaID, 
                DATEADD(HOUR, 2, GETDATE()), 
                DATEADD(HOUR, @CzasTransportu, GETDATE()));
        
        DECLARE @OpisStatusu VARCHAR(500);
        SET @OpisStatusu = 'Przesy³ka zosta³a nadana i przekazana kurierowi. ' +
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