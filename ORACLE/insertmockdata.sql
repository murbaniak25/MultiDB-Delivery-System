INSERT INTO D_KURIER_PROFIL (
    KURIER_ID, IMIE, NAZWISKO, SORTOWNIA_ID, WOJEWODZTWO,
    SREDNIA_DZIENNA_DOSTAW, MAX_DZIENNA_DOSTAW, SKUTECZNOSC_PROCENT, 
    SREDNI_CZAS_DOSTAWY, MAX_DOPUSZCZALNE_DOSTAW, PREFEROWANY_GABARYT
)
SELECT 
    KurierID,
    Imie,
    Nazwisko,
    SortowniaID,
    Wojewodztwo,
    GREATEST(LiczbaUdanychDostaw, 1) AS srednia_dostaw,
    GREATEST(LiczbaDostarczonychPrzesylek, 10) AS max_dostaw,
    CASE 
        WHEN LiczbaDostarczonychPrzesylek > 0 
        THEN ROUND((LiczbaUdanychDostaw * 100.0) / LiczbaDostarczonychPrzesylek, 2)
        ELSE 95.0 
    END AS skutecznosc,
    COALESCE(SredniCzasDostawyMinuty, 30) AS sredni_czas,
    GREATEST(LiczbaDostarczonychPrzesylek * 2, 50) AS max_dopuszczalne,
    'B' AS preferowany_gabaryt
FROM STAT_KURIERZY_SNAPSHOT
WHERE DataAktualizacji = (SELECT MAX(DataAktualizacji) FROM STAT_KURIERZY_SNAPSHOT);


-- Wypełnij F_KURIER_BIEZACE_OBLOZENIE na podstawie snapshotów
INSERT INTO F_KURIER_BIEZACE_OBLOZENIE (
    DATA_SNAPSHOT, KURIER_ID, SORTOWNIA_ID,
    LICZBA_PRZYPISANYCH, LICZBA_W_DOSTAWIE, LICZBA_OCZEKUJACYCH,
    LICZBA_GABARYT_A, LICZBA_GABARYT_B, LICZBA_GABARYT_C,
    PRZEWIDYWANY_CZAS_REALIZACJI_H, PROCENT_OBLOZENIA, WOLNA_POJEMNOSC
)
SELECT 
    TRUNC(SYSDATE) AS data_snapshot,
    sk.KurierID,
    sk.SortowniaID,
    -- Symulacja obłożenia na podstawie historii
    ROUND(sk.LiczbaDostarczonychPrzesylek * 0.3) AS przypisane,
    ROUND(sk.LiczbaDostarczonychPrzesylek * 0.2) AS w_dostawie,
    ROUND(sk.LiczbaDostarczonychPrzesylek * 0.1) AS oczekujace,
    -- Rozkład gabarytów z analiz przesyłek
    COALESCE(sp_a.gab_a, 2) AS gab_a,
    COALESCE(sp_b.gab_b, 3) AS gab_b,
    COALESCE(sp_c.gab_c, 1) AS gab_c,
    -- Przewidywany czas
    (sk.LiczbaDostarczonychPrzesylek * 0.3) * 
        COALESCE(sk.SredniCzasDostawyMinuty, 30) / 60 AS przewidywany_czas,
    -- Procent obłożenia
    LEAST(
        ((sk.LiczbaDostarczonychPrzesylek * 0.3) * 100.0) / 
        GREATEST(kp.MAX_DOPUSZCZALNE_DOSTAW, 50), 
        100
    ) AS procent_oblozenia,
    -- Wolna pojemność
    GREATEST(
        GREATEST(kp.MAX_DOPUSZCZALNE_DOSTAW, 50) - (sk.LiczbaDostarczonychPrzesylek * 0.3), 
        0
    ) AS wolna_pojemnosc
FROM STAT_KURIERZY_SNAPSHOT sk
JOIN D_KURIER_PROFIL kp ON sk.KurierID = kp.KURIER_ID
LEFT JOIN (
    SELECT 'Mazowieckie' AS woj, 2 AS gab_a FROM DUAL UNION ALL
    SELECT 'Małopolskie', 1 FROM DUAL UNION ALL
    SELECT 'Dolnośląskie', 1 FROM DUAL UNION ALL
    SELECT 'Pomorskie', 1 FROM DUAL UNION ALL
    SELECT 'Łódzkie', 1 FROM DUAL
) sp_a ON sk.Wojewodztwo = sp_a.woj
LEFT JOIN (
    SELECT 'Mazowieckie' AS woj, 3 AS gab_b FROM DUAL UNION ALL
    SELECT 'Małopolskie', 2 FROM DUAL UNION ALL
    SELECT 'Dolnośląskie', 2 FROM DUAL UNION ALL
    SELECT 'Pomorskie', 2 FROM DUAL UNION ALL
    SELECT 'Łódzkie', 2 FROM DUAL
) sp_b ON sk.Wojewodztwo = sp_b.woj
LEFT JOIN (
    SELECT 'Mazowieckie' AS woj, 1 AS gab_c FROM DUAL UNION ALL
    SELECT 'Małopolskie', 1 FROM DUAL UNION ALL
    SELECT 'Dolnośląskie', 1 FROM DUAL UNION ALL
    SELECT 'Pomorskie', 1 FROM DUAL UNION ALL
    SELECT 'Łódzkie', 1 FROM DUAL
) sp_c ON sk.Wojewodztwo = sp_c.woj
WHERE sk.DataAktualizacji = (SELECT MAX(DataAktualizacji) FROM STAT_KURIERZY_SNAPSHOT);


-- Wypełnij D_WZORCE_CZASOWE podstawowymi danymi
INSERT INTO D_WZORCE_CZASOWE (DZIEN_TYGODNIA, GODZINA, WOJEWODZTWO, WSPOLCZYNNIK_OBLOZENIA)
SELECT 
    d.dzien,
    g.godzina,
    w.wojewodztwo,
    CASE 
        WHEN d.dzien IN (1, 7) THEN 0.7  -- Weekendy
        WHEN g.godzina BETWEEN 10 AND 14 THEN 1.3  -- Szczyt
        WHEN g.godzina BETWEEN 16 AND 18 THEN 1.2  -- Popołudnie
        WHEN g.godzina < 9 OR g.godzina > 19 THEN 0.8  -- Poza godzinami
        ELSE 1.0
    END
FROM 
    (SELECT LEVEL AS dzien FROM DUAL CONNECT BY LEVEL <= 7) d,
    (SELECT LEVEL-1 AS godzina FROM DUAL CONNECT BY LEVEL <= 24) g,
    (SELECT DISTINCT Wojewodztwo AS wojewodztwo FROM STAT_KURIERZY_SNAPSHOT) w;



UPDATE D_KURIER_PROFIL 
SET 
    SKUTECZNOSC_PROCENT = COALESCE(SKUTECZNOSC_PROCENT, 95),
    SREDNI_CZAS_DOSTAWY = COALESCE(SREDNI_CZAS_DOSTAWY, 30),
    MAX_DOPUSZCZALNE_DOSTAW = COALESCE(MAX_DOPUSZCZALNE_DOSTAW, 50)
WHERE SKUTECZNOSC_PROCENT IS NULL 
   OR SREDNI_CZAS_DOSTAWY IS NULL 
   OR MAX_DOPUSZCZALNE_DOSTAW IS NULL;

COMMIT;


