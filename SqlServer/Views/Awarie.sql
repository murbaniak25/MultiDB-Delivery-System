USE DeliveryDB
GO


CREATE OR ALTER VIEW vw_PodsumowanieAwarii AS
SELECT 
    ai.TypObiektu,
    COUNT(*) AS LiczbaAwarii,
    COUNT(CASE WHEN ai.Priorytet = 'Krytyczny' THEN 1 END) AS Krytyczne,
    COUNT(CASE WHEN ai.Priorytet = 'Wysoki' THEN 1 END) AS Wysokie,
    COUNT(CASE WHEN ai.Priorytet = 'Sredni' THEN 1 END) AS Srednie,
    COUNT(CASE WHEN ai.Priorytet = 'Niski' THEN 1 END) AS Niskie,
    AVG(DATEDIFF(HOUR, ai.Data, GETDATE())) AS SredniCzasOdZgloszenia
FROM AwarieInfrastruktury ai
WHERE ai.Status IN ('Otwarta', 'W trakcie')
GROUP BY ai.TypObiektu;
GO

CREATE OR ALTER VIEW vw_PodsumowanieBledow AS
SELECT 
    kb.Kategoria,
    kb.KodBledu,
    kb.OpisBledu,
    COUNT(zb.ZgloszenieID) AS LiczbaZgloszen,
    COUNT(CASE WHEN zb.Potwierdzone = 1 THEN 1 END) AS Potwierdzone,
    kb.PoziomWaznosci
FROM KodyBledow kb
LEFT JOIN ZgloszeniaBledow zb ON kb.KodBledu = zb.KodBledu
GROUP BY kb.Kategoria, kb.KodBledu, kb.OpisBledu, kb.PoziomWaznosci;
GO