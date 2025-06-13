USE DeliveryDB
GO


CREATE OR ALTER VIEW vw_MonitoringPaczkomatow AS
SELECT 
    d.DroppointID,
    oi.Nazwa AS NazwaPaczkomatu,
    a.Miasto,
    a.Ulica,
    d.CzyAktywny,
    s.Gabaryt,
    COUNT(*) AS LiczbaSkrytek,
    SUM(CASE WHEN s.Status = 'Wolna' THEN 1 ELSE 0 END) AS WolneSkrytki,
    SUM(CASE WHEN s.Status = 'Zajęta' THEN 1 ELSE 0 END) AS ZajeteSkrytki,
    CAST(SUM(CASE WHEN s.Status = 'Wolna' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS ProcentWolnych,
    -- Awarie
    (SELECT COUNT(*) FROM AwarieInfrastruktury 
     WHERE ObiektID = d.DroppointID AND Status IN ('Otwarta', 'W trakcie')) AS AktywneAwarie
FROM Droppointy d
INNER JOIN ObiektInfrastruktury oi ON d.DroppointID = oi.ObiektID
INNER JOIN Adresy a ON oi.AdresID = a.AdresID
LEFT JOIN SkrytkiPaczkomatow s ON d.DroppointID = s.DroppointID
WHERE d.Typ = 'Paczkomat'
GROUP BY d.DroppointID, oi.Nazwa, a.Miasto, a.Ulica, d.CzyAktywny, s.Gabaryt;
GO