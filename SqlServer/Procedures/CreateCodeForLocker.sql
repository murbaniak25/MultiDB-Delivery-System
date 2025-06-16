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