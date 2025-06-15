USE DeliveryDB
GO

CREATE OR ALTER VIEW vw_HistoriaPrzesylki AS
SELECT 
    h.PrzesylkaID,
    h.Status,
    h.Opis,
    h.DataZmiany,
    DATEDIFF(MINUTE, LAG(h.DataZmiany) OVER (PARTITION BY h.PrzesylkaID ORDER BY h.DataZmiany), h.DataZmiany) AS CzasOdPoprzedniegoStatusuMin,
    o.Nazwa AS Lokalizacja
FROM HistoriaStatusowPrzesylek h
LEFT JOIN ObiektInfrastruktury o ON h.LokalizacjaID = o.ObiektID;
GO

CREATE OR ALTER VIEW vw_KolejkaNotyfikacji AS
SELECT 
    k.KolejkaID,
    k.AdresEmail,
    k.Temat,
    k.TypZdarzenia,
    k.StatusWysylki,
    k.DataUtworzenia,
    k.DataWyslania,
    CASE 
        WHEN k.StatusWysylki = 'WYSLANE' THEN 'Wysłane'
        WHEN k.StatusWysylki = 'BLAD' THEN 'Błąd: ' + k.Bledy
        ELSE 'Oczekuje na wysłanie'
    END AS StatusOpis
FROM KolejkaNotyfikacji k
ORDER BY k.DataUtworzenia DESC
OFFSET 0 ROWS;
GO