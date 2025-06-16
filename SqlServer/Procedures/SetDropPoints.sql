USE DeliveryDB
GO


CREATE OR ALTER PROCEDURE sp_PrzypiszDoSkrytki
    @PrzesylkaID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @Gabaryt CHAR(1), @DroppointID INT, @SkrytkaID INT;
        
        SELECT @Gabaryt = Gabaryt, @DroppointID = DroppointID 
        FROM Przesylki 
        WHERE PrzesylkaID = @PrzesylkaID;
        
        IF NOT EXISTS (SELECT 1 FROM Droppointy WHERE DroppointID = @DroppointID AND Typ = 'Paczkomat')
        BEGIN
            RAISERROR('Przesy³ka nie jest kierowana do paczkomatu', 16, 1);
            RETURN;
        END
        
        SELECT TOP 1 @SkrytkaID = SkrytkaID
        FROM SkrytkiPaczkomatow
        WHERE DroppointID = @DroppointID 
            AND Gabaryt = @Gabaryt 
            AND Status = 'Wolna'
        ORDER BY SkrytkaID;
        
        IF @SkrytkaID IS NULL
        BEGIN
            SELECT TOP 1 @SkrytkaID = SkrytkaID
            FROM SkrytkiPaczkomatow
            WHERE DroppointID = @DroppointID 
                AND Gabaryt > @Gabaryt 
                AND Status = 'Wolna'
            ORDER BY Gabaryt, SkrytkaID;
        END
        
        IF @SkrytkaID IS NULL
        BEGIN
            RAISERROR('Brak wolnych skrytek w paczkomacie', 16, 1);
            RETURN;
        END
        
        UPDATE Przesylki SET SkrytkaID = @SkrytkaID WHERE PrzesylkaID = @PrzesylkaID;
        
        UPDATE SkrytkiPaczkomatow SET Status = 'Zajêta' WHERE SkrytkaID = @SkrytkaID;
        
        DECLARE @OdbiorcaID INT;
        SELECT @OdbiorcaID = OdbiorcaID 
        FROM OdbiorcyPrzesylki 
        WHERE PrzesylkaID = @PrzesylkaID AND CzyGlowny = 1;
        
        
        COMMIT TRANSACTION;

        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO



CREATE OR ALTER PROCEDURE sp_SprawdzDostepnoscSkrytek
    @DroppointID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        Gabaryt,
        COUNT(*) AS LiczbaSkrytek,
        COUNT(CASE WHEN Status = 'Wolna' THEN 1 END) AS WolneSkrytki,
        COUNT(CASE WHEN Status = 'Zajêta' THEN 1 END) AS ZajeteSkrytki
    FROM SkrytkiPaczkomatow
    WHERE DroppointID = @DroppointID
    GROUP BY Gabaryt
    ORDER BY Gabaryt;
END;
GO