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
            RAISERROR('Nieprawidłowy lub wygasły kod odbioru dla podanej przesyłki.', 16, 1);
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
            RAISERROR('Przesyłka nie jest jeszcze dostępna do odbioru w paczkomacie.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        EXEC sp_AktualizujStatusPrzesylki 
            @PrzesylkaID = @PrzesylkaID,
            @NowyStatus = 'Dostarczona',
            @Opis = 'Przesyłka odebrana z paczkomatu przez odbiorcę',
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
