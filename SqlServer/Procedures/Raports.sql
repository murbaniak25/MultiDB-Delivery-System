USE DeliveryDB;
GO


CREATE OR ALTER PROCEDURE sp_RaportPrzesylekKuriera
    @KurierID INT,
    @DataOd DATE,
    @DataDo DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        p.PrzesylkaID,
        k1.Imie + ' ' + k1.Nazwisko AS Nadawca,
        k2.Imie + ' ' + k2.Nazwisko AS Odbiorca,
        p.Gabaryt,
        ok.CzasRozpoczecia,
        ok.CzasZakonczenia,
        ok.Status,
        ok.Uwagi
    FROM OperacjeKurierskie ok
    INNER JOIN Przesylki p ON ok.PrzesylkaID = p.PrzesylkaID
    INNER JOIN Klienci k1 ON p.NadawcaID = k1.KlientID
    INNER JOIN OdbiorcyPrzesylki op ON p.PrzesylkaID = op.PrzesylkaID AND op.CzyGlowny = 1
    INNER JOIN Klienci k2 ON op.OdbiorcaID = k2.KlientID
    WHERE ok.KurierID = @KurierID
        AND CAST(ok.CzasRozpoczecia AS DATE) BETWEEN @DataOd AND @DataDo
    ORDER BY ok.CzasRozpoczecia DESC;
END;
GO

CREATE OR ALTER PROCEDURE sp_StatystykiSortowni
    @SortowniaID INT,
    @Miesiac INT,
    @Rok INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        COUNT(DISTINCT p.PrzesylkaID) AS LiczbaPrzesylek,
        COUNT(DISTINCT os.PracownikID) AS LiczbaPracownikow,
        COUNT(DISTINCT os.OperacjaID) AS LiczbaOperacji,
        AVG(DATEDIFF(MINUTE, os.CzasRozpoczecia, os.CzasZakonczenia)) AS SredniCzasOperacji,
        COUNT(DISTINCT CASE WHEN z.Status IN ('Nowy', 'W trakcie') THEN z.ZwrotID END) AS AktywneZwroty
    FROM Sortownie s
    LEFT JOIN Przesylki p ON s.SortowniaID = p.SortowniaID
    LEFT JOIN OperacjeSortownicze os ON p.PrzesylkaID = os.PrzesylkaID
    LEFT JOIN Zwroty z ON p.PrzesylkaID = z.PrzesylkaID
    WHERE s.SortowniaID = @SortowniaID
        AND MONTH(os.CzasRozpoczecia) = @Miesiac
        AND YEAR(os.CzasRozpoczecia) = @Rok
    GROUP BY s.SortowniaID;
END;
GO