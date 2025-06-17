USE DeliveryDB;
GO

CREATE VIEW V_STAT_KURIERZY_SNAPSHOT AS
SELECT 
    k.KurierID,
    k.Imie,
    k.Nazwisko,
    k.Wojewodztwo,
    k.SortowniaID,
    oi.Nazwa AS SortowniaNazwa,
    COUNT(DISTINCT ok.PrzesylkaID) AS LiczbaDostarczonychPrzesylek,
    COUNT(DISTINCT CASE WHEN ok.Status = 'Dostarczona' THEN ok.PrzesylkaID END) AS LiczbaUdanychDostaw,
    COUNT(DISTINCT CASE WHEN ok.Status = 'Niedostarczona' THEN ok.PrzesylkaID END) AS LiczbaNieudanychDostaw,
    AVG(DATEDIFF(MINUTE, ok.CzasRozpoczecia, ok.CzasZakonczenia)) AS SredniCzasDostawyMinuty,
    MIN(ok.CzasRozpoczecia) AS PierwszaOperacja,
    MAX(ok.CzasZakonczenia) AS OstatniaOperacja,
    CAST(GETDATE() AS DATETIME2) AS DataAktualizacji
FROM Kurierzy k
LEFT JOIN OperacjeKurierskie ok ON k.KurierID = ok.KurierID
LEFT JOIN Sortownie s ON k.SortowniaID = s.SortowniaID
LEFT JOIN ObiektInfrastruktury oi ON s.SortowniaID = oi.ObiektID
WHERE oi.TypObiektu = 'Sortownia' OR oi.TypObiektu IS NULL
GROUP BY k.KurierID, k.Imie, k.Nazwisko, k.Wojewodztwo, k.SortowniaID, oi.Nazwa;
GO

CREATE VIEW V_STAT_SORTOWNIE_SNAPSHOT AS
SELECT 
    s.SortowniaID,
    oi.Nazwa AS SortowniaNazwa,
    a.Miasto,
    a.Wojewodztwo,
    COUNT(DISTINCT p.PrzesylkaID) AS LiczbaPrzetworzonych,
    COUNT(DISTINCT ps.PracownikID) AS LiczbaPracownikow,
    COUNT(DISTINCT k.KurierID) AS LiczbaKurierow,
    COUNT(DISTINCT d.DroppointID) AS LiczbaObslugiwanychDroppointow,
    AVG(DATEDIFF(MINUTE, os.CzasRozpoczecia, os.CzasZakonczenia)) AS SredniCzasPrzetwarzaniaMinuty,
    SUM(CASE WHEN os.TypOperacji = 'SORTOWANIE' THEN 1 ELSE 0 END) AS LiczbaOperacjiSortowania,
    SUM(CASE WHEN os.TypOperacji = 'ZALADOWANIE' THEN 1 ELSE 0 END) AS LiczbaOperacjiZaladunku,
    SUM(CASE WHEN os.TypOperacji = 'ROZLADOWANIE' THEN 1 ELSE 0 END) AS LiczbaOperacjiRozladunku,
    CAST(GETDATE() AS DATETIME2) AS DataAktualizacji
FROM Sortownie s
JOIN ObiektInfrastruktury oi ON s.SortowniaID = oi.ObiektID
JOIN Adresy a ON oi.AdresID = a.AdresID
LEFT JOIN Przesylki p ON s.SortowniaID = p.SortowniaID
LEFT JOIN PracownicySortowni ps ON s.SortowniaID = ps.SortowniaID
LEFT JOIN Kurierzy k ON s.SortowniaID = k.SortowniaID
LEFT JOIN Droppointy d ON s.SortowniaID = d.SortowniaID
LEFT JOIN OperacjeSortownicze os ON p.PrzesylkaID = os.PrzesylkaID
WHERE s.CzyAktywny = 1
GROUP BY s.SortowniaID, oi.Nazwa, a.Miasto, a.Wojewodztwo;
GO

CREATE VIEW V_STAT_PRZESYLKI_SNAPSHOT AS
SELECT 
    CAST(CAST(hsp.DataZmiany AS DATE) AS DATETIME2) AS DataDostawy,
    p.Gabaryt,
    an.Wojewodztwo AS WojewodztwoNadania,
    COALESCE(ad.Wojewodztwo, ao.Wojewodztwo) AS WojewodztwoOdbioru,
    COUNT(DISTINCT p.PrzesylkaID) AS LiczbaPrzesylek,
    AVG(DATEDIFF(HOUR, tp.DataWyjazdu, tp.DataPrzyjazdu)) AS SredniCzasTransportuGodziny,
    COUNT(DISTINCT CASE WHEN p.DroppointID IS NOT NULL THEN p.PrzesylkaID END) AS LiczbaDoDroppointow,
    COUNT(DISTINCT CASE WHEN p.DroppointID IS NULL THEN p.PrzesylkaID END) AS LiczbaDoAdresow,
    COUNT(DISTINCT z.ZwrotID) AS LiczbaZwrotow,
    CAST(GETDATE() AS DATETIME2) AS DataAktualizacji
FROM Przesylki p
LEFT JOIN TrasaPrzesylki tp ON p.PrzesylkaID = tp.PrzesylkaID
LEFT JOIN Adresy an ON p.AdresNadaniaID = an.AdresID
LEFT JOIN OdbiorcyPrzesylki op ON p.PrzesylkaID = op.PrzesylkaID AND op.CzyGlowny = 1
LEFT JOIN Klienci ko ON op.OdbiorcaID = ko.KlientID
LEFT JOIN Adresy ao ON ko.AdresID = ao.AdresID
LEFT JOIN Droppointy d ON p.DroppointID = d.DroppointID
LEFT JOIN ObiektInfrastruktury oid ON d.DroppointID = oid.ObiektID
LEFT JOIN Adresy ad ON oid.AdresID = ad.AdresID
LEFT JOIN Zwroty z ON p.PrzesylkaID = z.PrzesylkaID
LEFT JOIN HistoriaStatusowPrzesylek hsp ON p.PrzesylkaID = hsp.PrzesylkaID 
    AND hsp.Status IN ('Dostarczona', 'Odebrana')
WHERE hsp.DataZmiany IS NOT NULL
GROUP BY CAST(CAST(hsp.DataZmiany AS DATE) AS DATETIME2), p.Gabaryt, an.Wojewodztwo, COALESCE(ad.Wojewodztwo, ao.Wojewodztwo);
GO

CREATE VIEW V_STAT_DROPPOINTY_SNAPSHOT AS
SELECT 
    d.DroppointID,
    oi.Nazwa AS DroppointNazwa,
    d.Typ,
    a.Miasto,
    a.Wojewodztwo,
    d.SortowniaID,
    COUNT(DISTINCT sp.SkrytkaID) AS LiczbaSkrytek,
    COUNT(DISTINCT CASE WHEN sp.Status = 'Wolna' THEN sp.SkrytkaID END) AS LiczbaWolnychSkrytek,
    COUNT(DISTINCT CASE WHEN sp.Status = 'Zajeta' THEN sp.SkrytkaID END) AS LiczbaZajetychSkrytek,
    COUNT(DISTINCT p.PrzesylkaID) AS LiczbaObsluzonychPrzesylek,
    COUNT(DISTINCT ai.AwariaID) AS LiczbaAwarii,
    COUNT(DISTINCT CASE WHEN ai.Status = 'Otwarta' THEN ai.AwariaID END) AS LiczbaOtwartychAwarii,
    CAST(
        CASE WHEN COUNT(DISTINCT sp.SkrytkaID) > 0 
        THEN (COUNT(DISTINCT CASE WHEN sp.Status = 'Zajeta' THEN sp.SkrytkaID END) * 100.0) / COUNT(DISTINCT sp.SkrytkaID)
        ELSE 0 
        END AS DECIMAL(5,2)
    ) AS ProcentWykorzystania,
    CAST(GETDATE() AS DATETIME2) AS DataAktualizacji
FROM Droppointy d
JOIN ObiektInfrastruktury oi ON d.DroppointID = oi.ObiektID
JOIN Adresy a ON oi.AdresID = a.AdresID
LEFT JOIN SkrytkiPaczkomatow sp ON d.DroppointID = sp.DroppointID
LEFT JOIN Przesylki p ON d.DroppointID = p.DroppointID
LEFT JOIN AwarieInfrastruktury ai ON d.DroppointID = ai.ObiektID AND ai.TypObiektu = 'DropPoint'
WHERE d.CzyAktywny = 1
GROUP BY d.DroppointID, oi.Nazwa, d.Typ, a.Miasto, a.Wojewodztwo, d.SortowniaID;
GO

CREATE VIEW V_STAT_BLEDY_AWARIE_SNAPSHOT AS
SELECT 
    CAST(CAST(zb.DataZgloszenia AS DATE) AS DATETIME2) AS DataZgloszenia,
    zb.KodBledu,
    kb.Kategoria,
    kb.PoziomWaznosci,
    zb.ZrodloZgloszenia,
    COUNT(DISTINCT zb.ZgloszenieID) AS LiczbaZgloszen,
    COUNT(DISTINCT CASE WHEN zb.Potwierdzone = 1 THEN zb.ZgloszenieID END) AS LiczbaPotwierdzonych,
    COUNT(DISTINCT ai.AwariaID) AS LiczbaAwarii,
    COUNT(DISTINCT CASE WHEN ai.Status = 'Naprawiona' THEN ai.AwariaID END) AS LiczbaNaprawionych,
    AVG(CASE 
        WHEN ai.Status = 'Naprawiona' 
        THEN DATEDIFF(HOUR, ai.Data, GETDATE()) 
        ELSE NULL 
    END) AS SredniCzasNaprawyGodziny,
    CAST(GETDATE() AS DATETIME2) AS DataAktualizacji
FROM ZgloszeniaBledow zb
LEFT JOIN KodyBledow kb ON zb.KodBledu = kb.KodBledu
LEFT JOIN AwarieInfrastruktury ai ON zb.ObiektID = ai.ObiektID 
    AND CAST(zb.DataZgloszenia AS DATE) = CAST(ai.Data AS DATE)
GROUP BY CAST(CAST(zb.DataZgloszenia AS DATE) AS DATETIME2), 
         zb.KodBledu, kb.Kategoria, kb.PoziomWaznosci, zb.ZrodloZgloszenia;
GO

CREATE VIEW V_STAT_AGREGACJE_MIESIECZNE AS
SELECT 
    YEAR(hsp.DataZmiany) AS Rok,
    MONTH(hsp.DataZmiany) AS Miesiac,
    COUNT(DISTINCT p.PrzesylkaID) AS LiczbaPrzesylek,
    COUNT(DISTINCT p.KurierID) AS AktywniKurierzy,
    COUNT(DISTINCT p.SortowniaID) AS AktywneSortownie,
    COUNT(DISTINCT p.DroppointID) AS AktywneDroppointy,
    AVG(DATEDIFF(HOUR, tp.DataWyjazdu, hsp.DataZmiany)) AS SredniCzasDostawyGodziny,
    SUM(CASE WHEN p.Gabaryt = 'A' THEN 1 ELSE 0 END) AS PrzesylkiGabarytA,
    SUM(CASE WHEN p.Gabaryt = 'B' THEN 1 ELSE 0 END) AS PrzesylkiGabarytB,
    SUM(CASE WHEN p.Gabaryt = 'C' THEN 1 ELSE 0 END) AS PrzesylkiGabarytC,
    CAST(GETDATE() AS DATETIME2) AS DataAktualizacji
FROM Przesylki p
JOIN HistoriaStatusowPrzesylek hsp ON p.PrzesylkaID = hsp.PrzesylkaID
LEFT JOIN TrasaPrzesylki tp ON p.PrzesylkaID = tp.PrzesylkaID
WHERE hsp.Status IN ('Dostarczona', 'Odebrana') AND hsp.DataZmiany IS NOT NULL
GROUP BY YEAR(hsp.DataZmiany), MONTH(hsp.DataZmiany);
GO