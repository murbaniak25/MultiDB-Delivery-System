CREATE OR REPLACE VIEW V_RANKING_KURIEROW AS
SELECT
    KurierID,
    Imie,
    Nazwisko,
    Wojewodztwo,
    SortowniaNazwa,
    LiczbaUdanychDostaw,
    SredniCzasDostawyMinuty,
    RANK() OVER (ORDER BY LiczbaUdanychDostaw DESC) AS Ranking,
    DataAktualizacji
FROM STAT_KURIERZY_SNAPSHOT
WHERE DataAktualizacji = (SELECT MAX(DataAktualizacji) FROM STAT_KURIERZY_SNAPSHOT);

CREATE OR REPLACE VIEW V_DASHBOARD_SORTOWNIE AS
SELECT
    SortowniaID,
    SortowniaNazwa,
    Miasto,
    Wojewodztwo,
    LiczbaPrzetworzonych,
    LiczbaPracownikow,
    LiczbaKurierow,
    LiczbaObslugiwanychDroppointow,
    SredniCzasPrzetwarzaniaMinuty,
    DataAktualizacji
FROM STAT_SORTOWNIE_SNAPSHOT
WHERE DataAktualizacji = (SELECT MAX(DataAktualizacji) FROM STAT_SORTOWNIE_SNAPSHOT);

CREATE OR REPLACE VIEW V_PRZESYLKI_GABARYT_REGION AS
SELECT
    Gabaryt,
    WojewodztwoNadania,
    WojewodztwoOdbioru,
    SUM(LiczbaPrzesylek) AS SumaPrzesylek,
    AVG(SredniCzasTransportuGodziny) AS SredniCzasTransportu,
    MAX(DataAktualizacji) AS DataAktualizacji
FROM STAT_PRZESYLKI_SNAPSHOT
GROUP BY Gabaryt, WojewodztwoNadania, WojewodztwoOdbioru;

CREATE OR REPLACE VIEW V_AGREGAT_BLEDY_AWARIE_DZIEN AS
SELECT
    DataZgloszenia,
    KodBledu,
    Kategoria,
    PoziomWaznosci,
    SUM(LiczbaZgloszen) AS LiczbaZgloszen,
    SUM(LiczbaAwarii) AS LiczbaAwarii,
    SUM(LiczbaNaprawionych) AS LiczbaNaprawionych,
    AVG(SredniCzasNaprawyGodziny) AS SredniCzasNaprawy,
    MAX(DataAktualizacji) AS DataAktualizacji
FROM STAT_BLEDY_AWARIE_SNAPSHOT
GROUP BY DataZgloszenia, KodBledu, Kategoria, PoziomWaznosci;

CREATE OR REPLACE VIEW V_MIESIECZNE_PRZESYLKI AS
SELECT
    Rok,
    Miesiac,
    LiczbaPrzesylek,
    AktywniKurierzy,
    AktywneSortownie,
    AktywneDroppointy,
    SredniCzasDostawyGodziny,
    PrzesylkiGabarytA,
    PrzesylkiGabarytB,
    PrzesylkiGabarytC,
    DataAktualizacji
FROM STAT_AGREGACJE_MIESIECZNE
ORDER BY Rok DESC, Miesiac DESC;

CREATE OR REPLACE VIEW V_RANKING_DROPPOINTY AS
SELECT
    DroppointID,
    DroppointNazwa,
    ProcentWykorzystania,
    RANK() OVER (ORDER BY ProcentWykorzystania DESC) AS Ranking,
    DataAktualizacji
FROM STAT_DROPPOINTY_SNAPSHOT
WHERE DataAktualizacji = (SELECT MAX(DataAktualizacji) FROM STAT_DROPPOINTY_SNAPSHOT);

CREATE OR REPLACE VIEW V_TREND_AWARII AS
SELECT
    TRUNC(DataZgloszenia, 'MM') AS Miesiac,
    SUM(LiczbaAwarii) AS SumaAwarii
FROM STAT_BLEDY_AWARIE_SNAPSHOT
GROUP BY TRUNC(DataZgloszenia, 'MM')
ORDER BY Miesiac DESC;
