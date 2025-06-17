SELECT
    KurierID,
    Imie,
    Nazwisko,
    Wojewodztwo,
    SortowniaNazwa,
    LiczbaUdanychDostaw,
    SredniCzasDostawyMinuty,
    Ranking,
    DataAktualizacji
FROM V_RANKING_KURIEROW
WHERE Ranking <= 10;

SELECT
    SortowniaID,
    SortowniaNazwa,
    Miasto,
    Wojewodztwo,
    LiczbaPracownikow,
    LiczbaKurierow,
    LiczbaPrzetworzonych,
    SredniCzasPrzetwarzaniaMinuty
FROM V_DASHBOARD_SORTOWNIE
WHERE Wojewodztwo = 'Małopolskie'
ORDER BY LiczbaPrzetworzonych DESC;

SELECT
    Gabaryt,
    WojewodztwoNadania,
    WojewodztwoOdbioru,
    SumaPrzesylek,
    SredniCzasTransportu,
    DataAktualizacji
FROM V_PRZESYLKI_GABARYT_REGION
WHERE Gabaryt = 'B'
ORDER BY SumaPrzesylek DESC;

SELECT
    DataZgloszenia,
    KodBledu,
    Kategoria,
    LiczbaZgloszen,
    LiczbaAwarii,
    LiczbaNaprawionych,
    SredniCzasNaprawy
FROM V_AGREGAT_BLEDY_AWARIE_DZIEN
WHERE DataZgloszenia >= TRUNC(SYSDATE) - 30
ORDER BY DataZgloszenia DESC, LiczbaAwarii DESC;


