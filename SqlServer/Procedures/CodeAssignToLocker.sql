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
        SET @TrescEmail = '<h2>Twoja przesyłka czeka na odbiór!</h2>' +
                         '<p>Kod odbioru: <strong style="font-size: 24px; color: #FF6B00;">' + @KodOdbioru + '</strong></p>' +
                         '<p>Kod jest ważny przez 48 godzin.</p>';
        
        INSERT INTO KolejkaNotyfikacji (AdresEmail, Temat, TrescHTML, TrescTekst, TypZdarzenia)
        VALUES (@OdbiorcaEmail, 
                'Kod odbioru przesyłki #' + CAST(@PrzesylkaID AS VARCHAR(10)) + ': ' + @KodOdbioru,
                @TrescEmail,
                'Twoja przesyłka czeka na odbiór. Kod odbioru: ' + @KodOdbioru + '. Kod jest ważny przez 48 godzin.',
                'KOD_ODBIORU');
        
        COMMIT TRANSACTION;
        
        SELECT @KodOdbioru AS KodOdbioru;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO