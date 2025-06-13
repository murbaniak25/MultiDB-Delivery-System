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
        
        INSERT INTO Zwroty (KlientID, PrzesylkaID, Data, Przyczyna, Status)
        VALUES (@KlientID, @PrzesylkaID, GETDATE(), @Przyczyna, 'Nowy');
        
        DECLARE @ZwrotID INT = SCOPE_IDENTITY();
        
        DECLARE @SkrytkaID INT;
        SELECT @SkrytkaID = SkrytkaID FROM Przesylki WHERE PrzesylkaID = @PrzesylkaID;
        
        IF @SkrytkaID IS NOT NULL
        BEGIN
            UPDATE SkrytkiPaczkomatow SET Status = 'Wolna' WHERE SkrytkaID = @SkrytkaID;
            UPDATE Przesylki SET SkrytkaID = NULL WHERE PrzesylkaID = @PrzesylkaID;
        END
        
        DECLARE @NadawcaID INT;
        SELECT @NadawcaID = NadawcaID FROM Przesylki WHERE PrzesylkaID = @PrzesylkaID;
        
        EXEC sp_WyslijPowiadomienie @NadawcaID, @PrzesylkaID, 'Zwrot', 'Email';
        
        COMMIT TRANSACTION;
        
        SELECT @ZwrotID AS NowyZwrotID;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO