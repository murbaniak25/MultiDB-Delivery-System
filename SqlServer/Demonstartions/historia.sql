USE DeliveryDB
GO

SELECT TOP 5
    PrzesylkaID,
    Nadawca,
    LokalizacjaNadawcy,
    Odbiorca,
    LokalizacjaOdbiorcy,
    CASE 
        WHEN PaczkomatDocelowy IS NULL THEN 'DOSTAWA DO DOMU'
        ELSE PaczkomatDocelowy
    END AS MiejsceDostawy,
    Gabaryt,
    CzasTransportuGodzin,
    DataPrzyjazdu AS PlanowanaDataDostawy,
    AktualnyStatus,
    Kurier
FROM vw_SzczegolyPrzesylki
ORDER BY PrzesylkaID DESC;

-------

DECLARE @OstatniaPrzesylkaID INT;
SELECT TOP 1 @OstatniaPrzesylkaID = PrzesylkaID 
FROM Przesylki 
ORDER BY PrzesylkaID DESC;

SELECT 
    Status,
    Opis,
    DataZmiany,
    Lokalizacja,
    CzasOdPoprzedniegoStatusuMin
FROM vw_HistoriaPrzesylki
WHERE PrzesylkaID = @OstatniaPrzesylkaID
ORDER BY DataZmiany;

-------

SELECT TOP 10
    AdresEmail,
    Temat,
    TypZdarzenia,
    StatusOpis,
    DataUtworzenia
FROM vw_KolejkaNotyfikacji
ORDER BY DataUtworzenia DESC;
