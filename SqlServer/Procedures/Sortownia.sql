USE DeliveryDB;
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
        DECLARE @Status VARCHAR(20) = 'Zakończona';
        
        INSERT INTO OperacjeSortownicze (PrzesylkaID, PracownikID, TypOperacji, CzasRozpoczecia, CzasZakonczenia, Status, Uwagi)
        VALUES (@PrzesylkaID, @PracownikID, @TypOperacji, @CzasRozpoczecia, GETDATE(), @Status, @Uwagi);
        
        DECLARE @OperacjaID INT = SCOPE_IDENTITY();
        
        IF @TypOperacji = 'Sortowanie do wysyłki'
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

