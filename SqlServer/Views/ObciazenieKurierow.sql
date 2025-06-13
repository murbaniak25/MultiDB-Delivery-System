USE DeliveryDB
GO

CREATE OR ALTER VIEW vw_ObciazenieKurierow AS
SELECT 
    k.KurierID,
    k.Imie + ' ' + k.Nazwisko AS Kurier,
    k.Telefon,
    s.SortowniaID,
    ois.Nazwa AS Sortownia,
    COUNT(DISTINCT ok.PrzesylkaID) AS LiczbaPrzesylek,
    COUNT(DISTINCT CASE WHEN CAST(ok.CzasRozpoczecia AS DATE) = CAST(GETDATE() AS DATE) 
                        THEN ok.PrzesylkaID END) AS PrzesylkiDzis,
    AVG(DATEDIFF(MINUTE, ok.CzasRozpoczecia, ok.CzasZakonczenia)) AS SredniCzasDostawy,
    MAX(ok.CzasZakonczenia) AS OstatniaDostawa
FROM Kurierzy k
INNER JOIN Sortownie s ON k.SortowniaID = s.SortowniaID
INNER JOIN ObiektInfrastruktury ois ON s.SortowniaID = ois.ObiektID
LEFT JOIN OperacjeKurierskie ok ON k.KurierID = ok.KurierID
WHERE ok.CzasRozpoczecia >= DATEADD(DAY, -30, GETDATE())
GROUP BY k.KurierID, k.Imie, k.Nazwisko, k.Telefon, s.SortowniaID, ois.Nazwa;
GO