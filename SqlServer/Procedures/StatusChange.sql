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