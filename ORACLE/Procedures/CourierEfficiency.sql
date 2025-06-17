CREATE OR REPLACE PROCEDURE P_INICJALIZUJ_PROFILE_KURIEROW AS
BEGIN
    -- Wypełnij profile kurierów na podstawie snapshotów
    INSERT INTO D_KURIER_PROFIL (
        KURIER_ID, IMIE, NAZWISKO, SORTOWNIA_ID, WOJEWODZTWO,
        SREDNIA_DZIENNA_DOSTAW, MAX_DZIENNA_DOSTAW, SKUTECZNOSC_PROCENT, SREDNI_CZAS_DOSTAWY
    )
    SELECT 
        KurierID,
        Imie,
        Nazwisko,
        SortowniaID,
        Wojewodztwo,
        AVG(LiczbaUdanychDostaw),
        MAX(LiczbaUdanychDostaw),
        AVG(ROUND((LiczbaUdanychDostaw * 100.0) / NULLIF(LiczbaDostarczonychPrzesylek, 0), 2)),
        AVG(SredniCzasDostawyMinuty)
    FROM STAT_KURIERZY_SNAPSHOT
    GROUP BY KurierID, Imie, Nazwisko, SortowniaID, Wojewodztwo;
    
    COMMIT;
END;
/

BEGIN
    P_INICJALIZUJ_PROFILE_KURIEROW;
END;
/

CREATE OR REPLACE PROCEDURE P_OBLICZ_PROFIL_KURIERA(p_kurier_id NUMBER) AS
    v_srednia_dostaw NUMBER;
    v_max_dostaw NUMBER;
    v_skutecznosc NUMBER;
    v_sredni_czas NUMBER;
    v_preferowany_gabaryt CHAR(1);
BEGIN
    SELECT 
        AVG(LiczbaUdanychDostaw),
        MAX(LiczbaUdanychDostaw),
        AVG((LiczbaUdanychDostaw * 100.0) / NULLIF(LiczbaDostarczonychPrzesylek, 0)),
        AVG(SredniCzasDostawyMinuty)
    INTO 
        v_srednia_dostaw,
        v_max_dostaw,
        v_skutecznosc,
        v_sredni_czas
    FROM STAT_KURIERZY_SNAPSHOT
    WHERE KurierID = p_kurier_id
        AND DataAktualizacji >= TRUNC(SYSDATE) - 30;
    
    WITH gabaryt_stats AS (
        SELECT 
            sp.Gabaryt,
            COUNT(*) AS liczba,
            AVG(sp.SredniCzasTransportuGodziny * 60) AS avg_czas_min
        FROM STAT_PRZESYLKI_SNAPSHOT sp
        WHERE sp.DataAktualizacji >= TRUNC(SYSDATE) - 30
        GROUP BY sp.Gabaryt
    )
    SELECT Gabaryt INTO v_preferowany_gabaryt
    FROM gabaryt_stats
    WHERE avg_czas_min = (SELECT MIN(avg_czas_min) FROM gabaryt_stats)
    AND ROWNUM = 1;
    
    MERGE INTO D_KURIER_PROFIL kp
    USING (SELECT p_kurier_id AS kid FROM DUAL) s
    ON (kp.KURIER_ID = s.kid)
    WHEN MATCHED THEN UPDATE SET
        SREDNIA_DZIENNA_DOSTAW = v_srednia_dostaw,
        MAX_DZIENNA_DOSTAW = v_max_dostaw,
        SKUTECZNOSC_PROCENT = v_skutecznosc,
        SREDNI_CZAS_DOSTAWY = v_sredni_czas,
        PREFEROWANY_GABARYT = v_preferowany_gabaryt,
        MAX_DOPUSZCZALNE_DOSTAW = GREATEST(v_max_dostaw * 1.2, 50),
        OSTATNIA_AKTUALIZACJA = CURRENT_TIMESTAMP
    WHEN NOT MATCHED THEN INSERT (
        KURIER_ID, SREDNIA_DZIENNA_DOSTAW, MAX_DZIENNA_DOSTAW,
        SKUTECZNOSC_PROCENT, SREDNI_CZAS_DOSTAWY, PREFEROWANY_GABARYT
    ) VALUES (
        p_kurier_id, v_srednia_dostaw, v_max_dostaw,
        v_skutecznosc, v_sredni_czas, v_preferowany_gabaryt
    );
    
    COMMIT;
END;
/


CREATE OR REPLACE PROCEDURE P_OBLICZ_BIEZACE_OBLOZENIE AS
    v_dzien_tygodnia NUMBER;
    v_godzina NUMBER;
BEGIN
    v_dzien_tygodnia := TO_NUMBER(TO_CHAR(SYSDATE, 'D'));
    v_godzina := TO_NUMBER(TO_CHAR(SYSDATE, 'HH24'));
    
    -- Usuń stare dane
    DELETE FROM F_KURIER_BIEZACE_OBLOZENIE 
    WHERE DATA_SNAPSHOT < TRUNC(SYSDATE);
    
    -- Wstaw aktualne obłożenie oparte na snapshotach
    INSERT INTO F_KURIER_BIEZACE_OBLOZENIE (
        DATA_SNAPSHOT, KURIER_ID, SORTOWNIA_ID,
        LICZBA_PRZYPISANYCH, LICZBA_W_DOSTAWIE, LICZBA_OCZEKUJACYCH,
        LICZBA_GABARYT_A, LICZBA_GABARYT_B, LICZBA_GABARYT_C,
        PRZEWIDYWANY_CZAS_REALIZACJI_H, PROCENT_OBLOZENIA, WOLNA_POJEMNOSC
    )
    SELECT 
        TRUNC(SYSDATE),
        sk.KurierID,
        sk.SortowniaID,
        -- Estymacja na podstawie snapshotów
        ROUND(sk.LiczbaDostarczonychPrzesylek * 0.3) AS przypisane, -- 30% w toku
        ROUND(sk.LiczbaDostarczonychPrzesylek * 0.2) AS w_dostawie, -- 20% w dostawie
        ROUND(sk.LiczbaDostarczonychPrzesylek * 0.1) AS oczekujace, -- 10% oczekujące
        -- Gabaryt z analiz przesyłek
        ROUND(sp_a.suma_a * 0.3) AS gab_a,
        ROUND(sp_b.suma_b * 0.3) AS gab_b,
        ROUND(sp_c.suma_c * 0.3) AS gab_c,
        -- Przewidywany czas realizacji
        (sk.LiczbaDostarczonychPrzesylek * 0.3) * 
            sk.SredniCzasDostawyMinuty * 
            COALESCE(wc.WSPOLCZYNNIK_OBLOZENIA, 1.0) / 60 AS przewidywany_czas,
        -- Procent obłożenia
        LEAST(
            ((sk.LiczbaDostarczonychPrzesylek * 0.3) * 100.0) / 
            NULLIF(kp.MAX_DOPUSZCZALNE_DOSTAW, 0), 
            100
        ) AS procent_oblozenia,
        -- Wolna pojemność
        GREATEST(
            kp.MAX_DOPUSZCZALNE_DOSTAW - (sk.LiczbaDostarczonychPrzesylek * 0.3), 
            0
        ) AS wolna_pojemnosc
    FROM STAT_KURIERZY_SNAPSHOT sk
    LEFT JOIN D_KURIER_PROFIL kp ON sk.KurierID = kp.KURIER_ID
    LEFT JOIN (
        SELECT WojewodztwoOdbioru, SUM(CASE WHEN Gabaryt = 'A' THEN LiczbaPrzesylek ELSE 0 END) AS suma_a
        FROM STAT_PRZESYLKI_SNAPSHOT 
        WHERE DataAktualizacji = (SELECT MAX(DataAktualizacji) FROM STAT_PRZESYLKI_SNAPSHOT)
        GROUP BY WojewodztwoOdbioru
    ) sp_a ON sk.Wojewodztwo = sp_a.WojewodztwoOdbioru
    LEFT JOIN (
        SELECT WojewodztwoOdbioru, SUM(CASE WHEN Gabaryt = 'B' THEN LiczbaPrzesylek ELSE 0 END) AS suma_b
        FROM STAT_PRZESYLKI_SNAPSHOT 
        WHERE DataAktualizacji = (SELECT MAX(DataAktualizacji) FROM STAT_PRZESYLKI_SNAPSHOT)
        GROUP BY WojewodztwoOdbioru
    ) sp_b ON sk.Wojewodztwo = sp_b.WojewodztwoOdbioru
    LEFT JOIN (
        SELECT WojewodztwoOdbioru, SUM(CASE WHEN Gabaryt = 'C' THEN LiczbaPrzesylek ELSE 0 END) AS suma_c
        FROM STAT_PRZESYLKI_SNAPSHOT 
        WHERE DataAktualizacji = (SELECT MAX(DataAktualizacji) FROM STAT_PRZESYLKI_SNAPSHOT)
        GROUP BY WojewodztwoOdbioru
    ) sp_c ON sk.Wojewodztwo = sp_c.WojewodztwoOdbioru
    LEFT JOIN D_WZORCE_CZASOWE wc 
        ON wc.DZIEN_TYGODNIA = v_dzien_tygodnia 
        AND wc.GODZINA = v_godzina 
        AND wc.WOJEWODZTWO = sk.Wojewodztwo
    WHERE sk.DataAktualizacji = (SELECT MAX(DataAktualizacji) FROM STAT_KURIERZY_SNAPSHOT);
    
    COMMIT;
END;
/
