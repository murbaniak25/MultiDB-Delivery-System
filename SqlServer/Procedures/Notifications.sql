USE DeliveryDB;
GO


CREATE OR ALTER PROCEDURE sp_WyslijPowiadomienie
    @KlientID INT,
    @PrzesylkaID INT,
    @TypPowiadomienia VARCHAR(50),
    @Kanal VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @Tresc VARCHAR(500);
        DECLARE @Email VARCHAR(100), @Telefon VARCHAR(20);
        
        SELECT @Email = Email, @Telefon = Telefon
        FROM Klienci
        WHERE KlientID = @KlientID;
        
        SET @Tresc = CASE @TypPowiadomienia
            WHEN 'Nadanie' THEN 'Twoja przesyłka została nadana. Numer: ' + CAST(@PrzesylkaID AS VARCHAR(20))
            WHEN 'Dostawa' THEN 'Twoja przesyłka czeka na odbiór. Numer: ' + CAST(@PrzesylkaID AS VARCHAR(20))
            WHEN 'Zwrot' THEN 'Zgłoszono zwrot przesyłki. Numer: ' + CAST(@PrzesylkaID AS VARCHAR(20))
            ELSE 'Aktualizacja statusu przesyłki nr: ' + CAST(@PrzesylkaID AS VARCHAR(20))
        END;
        
        IF @Kanal NOT IN ('Email', 'SMS', 'Push')
        BEGIN
            SET @Kanal = 'Email';
        END
        
        INSERT INTO Powiadomienia (KlientID, PrzesylkaID, TypPowiadomienia, Tresc, Kanal, DataWyslania)
        VALUES (@KlientID, @PrzesylkaID, @TypPowiadomienia, @Tresc, @Kanal, GETDATE());
        
        SELECT SCOPE_IDENTITY() AS PowiadomienieID;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO