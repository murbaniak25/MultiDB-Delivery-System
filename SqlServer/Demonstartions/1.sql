CREATE OR ALTER VIEW vw_SzczegolyPrzesylki AS
SELECT 
    p.PrzesylkaID,
    p.Gabaryt,
    -- Nadawca
    kn.Imie + ' ' + kn.Nazwisko AS Nadawca,
    kn.Email AS EmailNadawcy,
    an.Miasto + ', ' + an.Wojewodztwo AS LokalizacjaNadawcy,
    -- Odbiorca
    ko.Imie + ' ' + ko.Nazwisko AS Odbiorca,
    ko.Email AS EmailOdbiorcy,
    ao.Miasto + ', ' + ao.Wojewodztwo AS LokalizacjaOdbiorcy,
    -- Trasa
    sn.Nazwa AS SortowniaNadania,
    sd.Nazwa AS SortowniaDocelowa,
    tp.DataWyjazdu,
    tp.DataPrzyjazdu,
    DATEDIFF(HOUR, tp.DataWyjazdu, tp.DataPrzyjazdu) AS CzasTransportuGodzin,
    -- Paczkomat docelowy
    oi.Nazwa AS PaczkomatDocelowy,
    ap.Miasto AS MiastoPaczkomatu,
    -- Kurier
    ku.Imie + ' ' + ku.Nazwisko AS Kurier,
    ku.Telefon AS TelefonKuriera,
    -- Status
    (SELECT TOP 1 Status FROM HistoriaStatusowPrzesylek WHERE PrzesylkaID = p.PrzesylkaID ORDER BY DataZmiany DESC) AS AktualnyStatus,
    (SELECT TOP 1 DataZmiany FROM HistoriaStatusowPrzesylek WHERE PrzesylkaID = p.PrzesylkaID ORDER BY DataZmiany DESC) AS OstatniaAktualizacja
FROM Przesylki p
-- Nadawca
INNER JOIN Klienci kn ON p.NadawcaID = kn.KlientID
INNER JOIN Adresy an ON kn.AdresID = an.AdresID
-- Odbiorca
INNER JOIN OdbiorcyPrzesylki op ON p.PrzesylkaID = op.PrzesylkaID AND op.CzyGlowny = 1
INNER JOIN Klienci ko ON op.OdbiorcaID = ko.KlientID
INNER JOIN Adresy ao ON ko.AdresID = ao.AdresID
-- Trasa
LEFT JOIN TrasaPrzesylki tp ON p.PrzesylkaID = tp.PrzesylkaID
LEFT JOIN ObiektInfrastruktury sn ON tp.SortowniaStartowaID = sn.ObiektID
LEFT JOIN ObiektInfrastruktury sd ON tp.SortowniaDocelowaID = sd.ObiektID
-- Paczkomat
INNER JOIN Droppointy d ON p.DroppointID = d.DroppointID
INNER JOIN ObiektInfrastruktury oi ON d.DroppointID = oi.ObiektID
INNER JOIN Adresy ap ON oi.AdresID = ap.AdresID
-- Kurier
INNER JOIN Kurierzy ku ON p.KurierID = ku.KurierID;
GO