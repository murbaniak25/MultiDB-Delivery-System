USE DeliveryDB
GO

CREATE OR ALTER VIEW vw_HistoriaPowiadomien AS
SELECT 
    p.PowiadomieniID,
    p.DataWyslania,
    k.Imie + ' ' + k.Nazwisko AS Odbiorca,
    k.Email,
    k.Telefon,
    p.TypPowiadomienia,
    p.Kanal,
    p.Tresc,
    pr.PrzesylkaID,
    pr.Gabaryt
FROM Powiadomienia p
INNER JOIN Klienci k ON p.KlientID = k.KlientID
LEFT JOIN Przesylki pr ON p.PrzesylkaID = pr.PrzesylkaID
ORDER BY p.DataWyslania DESC
OFFSET 0 ROWS;
GO
