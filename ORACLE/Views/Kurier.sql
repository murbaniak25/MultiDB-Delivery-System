CREATE OR REPLACE VIEW V_RANKING_WYDAJNOSCI_KURIEROW AS
SELECT 
    sk.KurierID,
    sk.Imie || ' ' || sk.Nazwisko AS KURIER,
    sk.Wojewodztwo,
    sk.SortowniaNazwa,
    sk.LiczbaUdanychDostaw AS SREDNIA_DZIENNA_DOSTAW,
    ROUND((sk.LiczbaUdanychDostaw * 100.0) / NULLIF(sk.LiczbaDostarczonychPrzesylek, 0), 2) AS SKUTECZNOSC_PROCENT,
    sk.SredniCzasDostawyMinuty AS SREDNI_CZAS_DOSTAWY,
    RANK() OVER (ORDER BY sk.LiczbaUdanychDostaw DESC) AS RANKING_ILOSC,
    RANK() OVER (ORDER BY (sk.LiczbaUdanychDostaw * 100.0) / NULLIF(sk.LiczbaDostarczonychPrzesylek, 0) DESC) AS RANKING_SKUTECZNOSC,
    RANK() OVER (ORDER BY sk.SredniCzasDostawyMinuty ASC) AS RANKING_SZYBKOSC,
    sk.DataAktualizacji
FROM STAT_KURIERZY_SNAPSHOT sk
WHERE sk.DataAktualizacji = (SELECT MAX(DataAktualizacji) FROM STAT_KURIERZY_SNAPSHOT);



CREATE OR REPLACE VIEW V_REKOMENDACJA_KURIERA AS
SELECT 
    kp.KURIER_ID,
    kp.IMIE || ' ' || kp.NAZWISKO AS KURIER,
    kp.SORTOWNIA_ID,
    kp.WOJEWODZTWO,
    bo.LICZBA_PRZYPISANYCH,
    bo.PROCENT_OBLOZENIA,
    bo.WOLNA_POJEMNOSC,
    -- Poprawiony wskaźnik gotowości z domyślnymi wartościami
    CASE 
        WHEN bo.PROCENT_OBLOZENIA >= 95 THEN 0
        WHEN bo.WOLNA_POJEMNOSC = 0 THEN 0      
        ELSE ROUND(
            (100 - bo.PROCENT_OBLOZENIA) * 0.4 +  
            (COALESCE(kp.SKUTECZNOSC_PROCENT, 95)) * 0.3 +  -- Domyślnie 95%
            (100 - (COALESCE(kp.SREDNI_CZAS_DOSTAWY, 30) / 60)) * 0.3  -- Domyślnie 30 min
        , 2)
    END AS WSKAZNIK_GOTOWOSCI,
    CASE 
        WHEN bo.LICZBA_GABARYT_C > bo.LICZBA_GABARYT_A * 2 THEN 'A'
        WHEN bo.LICZBA_GABARYT_A > bo.LICZBA_GABARYT_C * 2 THEN 'C'
        ELSE 'B'
    END AS REKOMENDOWANY_GABARYT
FROM D_KURIER_PROFIL kp
JOIN F_KURIER_BIEZACE_OBLOZENIE bo 
    ON kp.KURIER_ID = bo.KURIER_ID 
    AND bo.DATA_SNAPSHOT = TRUNC(SYSDATE)
WHERE bo.PROCENT_OBLOZENIA < 95
ORDER BY WSKAZNIK_GOTOWOSCI DESC;
