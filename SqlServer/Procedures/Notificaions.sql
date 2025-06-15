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
        PRINT 'Błąd wysyłki notyfikacji: ' + ERROR_MESSAGE();
    END CATCH
END;
GO