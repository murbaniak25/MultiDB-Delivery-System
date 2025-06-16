USE DeliveryDB;
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
            RAISERROR('Klient nie jest odbiorcą tej przesyłki', 16, 1);
            RETURN;
        END
        
        IF EXISTS (
            SELECT 1 FROM Zwroty 
            WHERE PrzesylkaID = @PrzesylkaID 
                AND Status IN ('Nowy', 'W trakcie')
        )
        BEGIN
            RAISERROR('Dla tej przesyłki istnieje już aktywny zwrot', 16, 1);
            RETURN;
        END

        IF NOT EXISTS (
            SELECT 1 FROM HistoriaStatusowPrzesylek
            WHERE PrzesylkaID = @PrzesylkaID
              AND Status IN ('Dostarczona', 'W paczkomacie')
        )
        BEGIN
            RAISERROR('Zwrot możliwy tylko dla przesyłek dostarczonych lub oczekujących w paczkomacie.', 16, 1);
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
            RAISERROR('Zwrot możliwy tylko dla przesyłek dostarczonych lub oczekujących w paczkomacie.', 16, 1);
            RETURN;
        END

        IF DATEDIFF(DAY, @DataDostarczenia, GETDATE()) > 14
        BEGIN
            RAISERROR('Minął maksymalny czas na zwrot przesyłki (14 dni od dostarczenia).', 16, 1);
            RETURN;
        END

        
        INSERT INTO Zwroty (KlientID, PrzesylkaID, Data, Przyczyna, Status)
        VALUES (@KlientID, @PrzesylkaID, GETDATE(), @Przyczyna, 'Nowy');
        
        DECLARE @ZwrotID INT = SCOPE_IDENTITY();
        
        INSERT INTO HistoriaStatusowPrzesylek (PrzesylkaID, Status, Opis, LokalizacjaID)
        VALUES (@PrzesylkaID, 'Zwrot w toku', 'Rozpoczęto proces zwrotu przesyłki przez odbiorcę', NULL);

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



        -- Dodaj nową trasę zwrotną
        INSERT INTO TrasaPrzesylki (PrzesylkaID, SortowniaStartowaID, SortowniaDocelowaID, DataWyjazdu, DataPrzyjazdu)
        VALUES (
            @PrzesylkaID, 
            @SortowniaOdbiorcyID, 
            @SortowniaNadawcyID, 
            GETDATE(), 
            DATEADD(HOUR, 24, GETDATE()) -- przykładowo 24h na zwrot
        );

        -- 8. Powiadom nadawcę i odbiorcę
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
