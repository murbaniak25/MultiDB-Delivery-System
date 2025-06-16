USE DeliveryDB
GO


CREATE OR ALTER PROCEDURE sp_SymulujZwrotPrzesylki
    @PrzesylkaID INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SortowniaStartowaID INT, @SortowniaDocelowaID INT;

    -- Pobierz trasę zwrotną
    SELECT 
        @SortowniaStartowaID = SortowniaStartowaID,
        @SortowniaDocelowaID = SortowniaDocelowaID
    FROM TrasaPrzesylki
    WHERE PrzesylkaID = @PrzesylkaID;

    -- 1. Odbiór zwrotu przez kuriera od odbiorcy
    WAITFOR DELAY '00:00:01';
    EXEC sp_AktualizujStatusPrzesylki 
        @PrzesylkaID = @PrzesylkaID,
        @NowyStatus = 'Zwrot odebrany',
        @Opis = 'Kurier odebrał przesyłkę zwrotną od odbiorcy',
        @LokalizacjaID = NULL;
    PRINT 'Status: Zwrot odebrany od odbiorcy';

    -- 2. Zwrot w sortowni odbiorcy
    WAITFOR DELAY '00:00:01';
    EXEC sp_AktualizujStatusPrzesylki 
        @PrzesylkaID = @PrzesylkaID,
        @NowyStatus = 'Zwrot w sortowni nadania',
        @Opis = 'Przesyłka zwrotna dotarła do sortowni odbiorcy',
        @LokalizacjaID = @SortowniaStartowaID;
    PRINT 'Status: Zwrot w sortowni odbiorcy';

    -- 3. Zwrot w transporcie (między sortowniami)
    IF @SortowniaStartowaID != @SortowniaDocelowaID
    BEGIN
        WAITFOR DELAY '00:00:01';
        EXEC sp_AktualizujStatusPrzesylki 
            @PrzesylkaID = @PrzesylkaID,
            @NowyStatus = 'Zwrot w transporcie',
            @Opis = 'Przesyłka zwrotna w transporcie między sortowniami',
            @LokalizacjaID = NULL;
        PRINT 'Status: Zwrot w transporcie między sortowniami';

        -- 4. Zwrot w sortowni nadawcy
        WAITFOR DELAY '00:00:01';
        EXEC sp_AktualizujStatusPrzesylki 
            @PrzesylkaID = @PrzesylkaID,
            @NowyStatus = 'Zwrot w sortowni docelowej',
            @Opis = 'Przesyłka zwrotna dotarła do sortowni nadawcy',
            @LokalizacjaID = @SortowniaDocelowaID;
        PRINT 'Status: Zwrot w sortowni nadawcy';
    END

    -- 5. Zwrot w dostawie do nadawcy
    WAITFOR DELAY '00:00:01';
    EXEC sp_AktualizujStatusPrzesylki 
        @PrzesylkaID = @PrzesylkaID,
        @NowyStatus = 'Zwrot w dostawie',
        @Opis = 'Kurier dostarcza przesyłkę zwrotną do nadawcy',
        @LokalizacjaID = NULL;
    PRINT 'Status: Zwrot w dostawie do nadawcy';

    -- 6. Zwrot dostarczony do nadawcy
    WAITFOR DELAY '00:00:01';
    EXEC sp_AktualizujStatusPrzesylki 
        @PrzesylkaID = @PrzesylkaID,
        @NowyStatus = 'Zwrot dostarczony',
        @Opis = 'Przesyłka zwrotna dostarczona do nadawcy',
        @LokalizacjaID = NULL;
    PRINT 'Status: Zwrot dostarczony do nadawcy';

    PRINT 'Symulacja zwrotu zakończona!';

    -- Wyświetl historię statusów zwrotu
    SELECT * FROM HistoriaStatusowPrzesylek WHERE PrzesylkaID = @PrzesylkaID ORDER BY DataZmiany;
END;
GO
