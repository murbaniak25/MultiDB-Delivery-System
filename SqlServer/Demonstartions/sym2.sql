USE DeliveryDB
GO

CREATE OR ALTER PROCEDURE sp_SymulujCyklZyciaPrzesylkiV2
    @PrzesylkaID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DroppointID INT, @SortowniaStartowaID INT, @SortowniaDocelowaID INT;
    DECLARE @CzyDostawaDoDomu BIT = 0;
    
    SELECT 
        @DroppointID = p.DroppointID,
        @SortowniaStartowaID = tp.SortowniaStartowaID,
        @SortowniaDocelowaID = tp.SortowniaDocelowaID,
        @CzyDostawaDoDomu = CASE WHEN p.DroppointID IS NULL THEN 1 ELSE 0 END
    FROM Przesylki p
    LEFT JOIN TrasaPrzesylki tp ON p.PrzesylkaID = tp.PrzesylkaID
    WHERE p.PrzesylkaID = @PrzesylkaID;
    
    -- 1. Odbiór od nadawcy
    WAITFOR DELAY '00:00:01';
    EXEC sp_AktualizujStatusPrzesylki 
        @PrzesylkaID = @PrzesylkaID,
        @NowyStatus = 'Odebrana od nadawcy',
        @Opis = 'Kurier odebrał przesyłkę od nadawcy',
        @LokalizacjaID = NULL;
    PRINT 'Status: Odebrana od nadawcy';
    
    -- 2. Dostawa do sortowni
    WAITFOR DELAY '00:00:01';
    EXEC sp_AktualizujStatusPrzesylki 
        @PrzesylkaID = @PrzesylkaID,
        @NowyStatus = 'W sortowni',
        @Opis = 'Przesyłka dotarła do sortowni nadania',
        @LokalizacjaID = @SortowniaStartowaID;
    PRINT 'Status: W sortowni nadania';
    
    -- 3. W transporcie (jeśli różne sortownie)
    IF @SortowniaStartowaID != @SortowniaDocelowaID
    BEGIN
        WAITFOR DELAY '00:00:01';
        EXEC sp_AktualizujStatusPrzesylki 
            @PrzesylkaID = @PrzesylkaID,
            @NowyStatus = 'W transporcie',
            @Opis = 'Przesyłka w transporcie między sortowniami',
            @LokalizacjaID = NULL;
        PRINT 'Status: W transporcie między sortowniami';
        
        -- 4. W sortowni docelowej
        WAITFOR DELAY '00:00:01';
        EXEC sp_AktualizujStatusPrzesylki 
            @PrzesylkaID = @PrzesylkaID,
            @NowyStatus = 'W sortowni',
            @Opis = 'Przesyłka dotarła do sortowni docelowej',
            @LokalizacjaID = @SortowniaDocelowaID;
        PRINT 'Status: W sortowni docelowej';
    END
    
    -- 5. W dostawie
    WAITFOR DELAY '00:00:01';
    EXEC sp_AktualizujStatusPrzesylki 
        @PrzesylkaID = @PrzesylkaID,
        @NowyStatus = 'W dostawie',
        @Opis = 'Przesyłka wydana kurierowi do dostawy ostatniej mili',
        @LokalizacjaID = NULL;
    PRINT 'Status: W dostawie';
    
    -- 6. Dostarczona
    IF @CzyDostawaDoDomu = 1
    BEGIN
        WAITFOR DELAY '00:00:01';
        EXEC sp_AktualizujStatusPrzesylki 
            @PrzesylkaID = @PrzesylkaID,
            @NowyStatus = 'Dostarczona',
            @Opis = 'Przesyłka dostarczona do adresata',
            @LokalizacjaID = NULL;
        PRINT 'Status: Dostarczona do domu';
    END
    ELSE
    BEGIN
        -- Przypisz do skrytki
        EXEC sp_PrzypiszDoSkrytki @PrzesylkaID = @PrzesylkaID;
        
        WAITFOR DELAY '00:00:01';
        EXEC sp_AktualizujStatusPrzesylki 
            @PrzesylkaID = @PrzesylkaID,
            @NowyStatus = 'W paczkomacie',
            @Opis = 'Przesyłka umieszczona w paczkomacie, oczekuje na odbiór',
            @LokalizacjaID = @DroppointID;
        PRINT 'Status: W paczkomacie';
    END
    
    PRINT 'Symulacja zakończona!';
    
    SELECT * 
    FROM HistoriaStatusowPrzesylek 
    WHERE PrzesylkaID = @PrzesylkaID
    ORDER BY DataZmiany;
END;
GO
