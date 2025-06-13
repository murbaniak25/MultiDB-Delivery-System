USE DeliveryDB;
GO


CREATE OR ALTER PROCEDURE sp_NadajPrzesylke
    @NadawcaID INT,
    @OdbiorcaID INT,
    @Gabaryt CHAR(1),
    @DroppointID INT,
    @AdresNadaniaID INT,
    @CzyGlownyOdbiorca BIT = 1
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
        
        IF NOT EXISTS (SELECT 1 FROM Droppointy WHERE DroppointID = @DroppointID AND CzyAktywny = 1)
        BEGIN
            RAISERROR('Wybrany punkt nadania jest nieaktywny', 16, 1);
            RETURN;
        END
        
        DECLARE @SortowniaID INT;
        SELECT @SortowniaID = SortowniaID FROM Droppointy WHERE DroppointID = @DroppointID;
        
        DECLARE @KurierID INT;
        SELECT TOP 1 @KurierID = KurierID 
        FROM Kurierzy 
        WHERE SortowniaID = @SortowniaID 
            AND PrzesylkaID IS NULL
        ORDER BY KurierID;
        
        IF @KurierID IS NULL
        BEGIN
            SELECT TOP 1 @KurierID = KurierID 
            FROM Kurierzy 
            WHERE SortowniaID = @SortowniaID
            ORDER BY NEWID();
        END
        
        INSERT INTO Przesylki (NadawcaID, DroppointID, SortowniaID, KurierID, AdresNadaniaID, Gabaryt)
        VALUES (@NadawcaID, @DroppointID, @SortowniaID, @KurierID, @AdresNadaniaID, @Gabaryt);
        
        DECLARE @PrzesylkaID INT = SCOPE_IDENTITY();
        
        INSERT INTO OdbiorcyPrzesylki (PrzesylkaID, OdbiorcaID, CzyGlowny, Kolejnosc)
        VALUES (@PrzesylkaID, @OdbiorcaID, @CzyGlownyOdbiorca, 1);
        
        UPDATE Kurierzy SET PrzesylkaID = @PrzesylkaID WHERE KurierID = @KurierID;
        
        INSERT INTO OperacjeKurierskie (PrzesylkaID, KurierID, CzasRozpoczecia, CzasZakonczenia, Status)
        VALUES (@PrzesylkaID, @KurierID, GETDATE(), GETDATE(), 'Przyjęta do nadania');
        
        EXEC sp_WyslijPowiadomienie @NadawcaID, @PrzesylkaID, 'Nadanie', 'Email';
        
        COMMIT TRANSACTION;
        
        SELECT @PrzesylkaID AS NowaPrzesylkaID;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO