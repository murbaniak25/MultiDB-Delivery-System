USE DeliveryDB
GO

CREATE OR ALTER VIEW vw_AktywneAwarie AS
SELECT 
    ai.AwariaID,
    ai.TypObiektu,
    CASE ai.TypObiektu
        WHEN 'Sortownia' THEN 'Sortownia: ' + ois.Nazwa
        WHEN 'DropPoint' THEN 'DropPoint: ' + oid.Nazwa
        WHEN 'Skrytka' THEN 'Skrytka: ' + CAST(ai.ObiektID AS VARCHAR(10))
    END AS NazwaObiektu,
    ai.Data AS DataZgloszenia,
    ai.Opis,
    ai.Status,
    ai.Priorytet,
    ps.Imie + ' ' + ps.Nazwisko AS ZgloszonePrzez,
    DATEDIFF(HOUR, ai.Data, GETDATE()) AS GodzinOdZgloszenia,
    CASE 
        WHEN ai.TypObiektu = 'Sortownia' THEN 
            (SELECT COUNT(*) FROM Przesylki WHERE SortowniaID = ai.ObiektID)
        WHEN ai.TypObiektu = 'DropPoint' THEN 
            (SELECT COUNT(*) FROM Przesylki WHERE DroppointID = ai.ObiektID)
        ELSE 0
    END AS PrzesylkiDotknieteProblemem
FROM AwarieInfrastruktury ai
INNER JOIN PracownicySortowni ps ON ai.PracownikID = ps.PracownikID
LEFT JOIN ObiektInfrastruktury ois ON ai.ObiektID = ois.ObiektID AND ai.TypObiektu = 'Sortownia'
LEFT JOIN ObiektInfrastruktury oid ON ai.ObiektID = oid.ObiektID AND ai.TypObiektu = 'DropPoint'
WHERE ai.Status IN ('Otwarta', 'W trakcie');
GO