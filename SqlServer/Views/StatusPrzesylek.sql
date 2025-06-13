USE DeliveryDB;
GO

CREATE OR ALTER VIEW vw_StatusPrzesylek AS
SELECT 
    p.PrzesylkaID,
    p.Gabaryt,
    -- Nadawca
    kn.Imie + ' ' + kn.Nazwisko AS NadawcaNazwa,
    kn.Email AS NadawcaEmail,
    kn.Telefon AS NadawcaTelefon,
    an.Miasto AS NadawcaMiasto,
    -- Odbiorca
    ko.Imie + ' ' + ko.Nazwisko AS OdbiorcaNazwa,
    ko.Email AS OdbiorcaEmail,
    ko.Telefon AS OdbiorcaTelefon,
    -- Lokalizacja
    oi.Nazwa AS PunktOdbioru,
    d.Typ AS TypPunktuOdbioru,
    ao.Ulica + ', ' + ao.Miasto AS AdresPunktuOdbioru,
    -- Skrytka
    CASE 
        WHEN sp.SkrytkaID IS NOT NULL THEN 'Skrytka ' + sp.Gabaryt + '-' + CAST(sp.SkrytkaID AS VARCHAR(10))
        ELSE 'Brak przypisanej skrytki'
    END AS Skrytka,
    -- Status
    CASE 
        WHEN z.ZwrotID IS NOT NULL THEN 'ZWROT: ' + z.Status
        WHEN sp.SkrytkaID IS NOT NULL AND sp.Status = 'Zajęta' THEN 'W paczkomacie - oczekuje na odbiór'
        WHEN ok.Status IS NOT NULL THEN ok.Status
        ELSE 'Nieznany'
    END AS StatusPrzesylki,
    -- Kurier
    ku.Imie + ' ' + ku.Nazwisko AS Kurier,
    ku.Telefon AS TelefonKuriera,
    -- Czasy
    ok.CzasRozpoczecia AS DataNadania,
    ok.CzasZakonczenia AS OstatnieZdarzenie
FROM Przesylki p
-- Nadawca
INNER JOIN Klienci kn ON p.NadawcaID = kn.KlientID
INNER JOIN Adresy an ON kn.AdresID = an.AdresID
-- Odbiorca
INNER JOIN OdbiorcyPrzesylki op ON p.PrzesylkaID = op.PrzesylkaID AND op.CzyGlowny = 1
INNER JOIN Klienci ko ON op.OdbiorcaID = ko.KlientID
-- Punkt odbioru
INNER JOIN Droppointy d ON p.DroppointID = d.DroppointID
INNER JOIN ObiektInfrastruktury oi ON d.DroppointID = oi.ObiektID
INNER JOIN Adresy ao ON oi.AdresID = ao.AdresID
-- Kurier
INNER JOIN Kurierzy ku ON p.KurierID = ku.KurierID
-- Skrytka
LEFT JOIN SkrytkiPaczkomatow sp ON p.SkrytkaID = sp.SkrytkaID
-- Ostatnia operacja kurierska
OUTER APPLY (
    SELECT TOP 1 Status, CzasRozpoczecia, CzasZakonczenia
    FROM OperacjeKurierskie
    WHERE PrzesylkaID = p.PrzesylkaID
    ORDER BY CzasZakonczenia DESC
) ok
-- Zwroty
LEFT JOIN Zwroty z ON p.PrzesylkaID = z.PrzesylkaID AND z.Status IN ('Nowy', 'W trakcie');
GO