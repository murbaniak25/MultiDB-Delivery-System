DECLARE
    v_data DATE;
    v_paczkomat VARCHAR2(10);
BEGIN
    FOR i IN 1..5 LOOP
        v_paczkomat := 'WAW0' || i;
        
        FOR j IN 0..89 LOOP -- 90 dni
            v_data := TRUNC(SYSDATE) - j;
            
            INSERT INTO STATYSTYKI_PUNKTOW_ODBIORU (
                STAT_ID, DROP_POINT_ID, DATA_ANALIZY,
                LICZBA_NADAN, LICZBA_ODBIOROW, LICZBA_ZWROTOW, LICZBA_NIEODEBRANYCH,
                SREDNI_CZAS_W_SKRYTCE_H, PROCENT_TERMINOWYCH_ODBIOROW,
                KOSZT_OBSLUGI, LICZBA_AWARII, OCENA_KLIENTOW
            ) VALUES (
                SEQ_STAT_PUNKTOW.NEXTVAL, v_paczkomat, v_data,
                ROUND(DBMS_RANDOM.VALUE(50, 200)), -- nadania
                ROUND(DBMS_RANDOM.VALUE(45, 180)), -- odbiory
                ROUND(DBMS_RANDOM.VALUE(0, 10)),   -- zwroty
                ROUND(DBMS_RANDOM.VALUE(0, 5)),    -- nieodebrane
                ROUND(DBMS_RANDOM.VALUE(12, 36), 2), -- śr. czas w skrytce
                ROUND(DBMS_RANDOM.VALUE(85, 99), 2), -- % terminowych
                ROUND(DBMS_RANDOM.VALUE(500, 2000), 2), -- koszt obsługi
                ROUND(DBMS_RANDOM.VALUE(0, 2)), -- awarie
                ROUND(DBMS_RANDOM.VALUE(3.5, 5), 2) -- ocena
            );
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- Wydajność kurierów
DECLARE
    v_data DATE;
    v_okres VARCHAR2(7);
BEGIN
    FOR kurier IN 1..10 LOOP
        FOR mies IN 0..2 LOOP -- ostatnie 3 miesiące
            v_data := ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -mies);
            v_okres := TO_CHAR(v_data, 'YYYY-MM');
            
            INSERT INTO WYDAJNOSC_KURIEROW (
                WYDAJNOSC_ID, KURIER_ID, DATA_ANALIZY, OKRES_ROZLICZENIOWY,
                LICZBA_DNI_PRACY, LICZBA_DOSTAW, LICZBA_ODBIOROW, LICZBA_ZWROTOW,
                SREDNI_CZAS_DOSTAWY_MIN, NAJKROTSZY_CZAS_MIN, NAJDLUZSZY_CZAS_MIN,
                CZAS_PRACY_LACZNIE_H, SREDNI_CZAS_NA_PRZESYLKE_MIN,
                KOSZT_KURIERA, WSKAZNIK_WYDAJNOSCI
            ) VALUES (
                SEQ_WYDAJNOSC.NEXTVAL, kurier, v_data, v_okres,
                ROUND(DBMS_RANDOM.VALUE(18, 22)), -- dni pracy
                ROUND(DBMS_RANDOM.VALUE(300, 600)), -- dostawy
                ROUND(DBMS_RANDOM.VALUE(100, 200)), -- odbiory
                ROUND(DBMS_RANDOM.VALUE(5, 20)), -- zwroty
                ROUND(DBMS_RANDOM.VALUE(15, 35), 2), -- śr. czas dostawy
                ROUND(DBMS_RANDOM.VALUE(5, 15)), -- najkrótszy
                ROUND(DBMS_RANDOM.VALUE(45, 120)), -- najdłuższy
                ROUND(DBMS_RANDOM.VALUE(140, 180), 2), -- godz. pracy
                ROUND(DBMS_RANDOM.VALUE(8, 20), 2), -- śr. czas/przesyłkę
                ROUND(DBMS_RANDOM.VALUE(3500, 5000), 2), -- koszt
                ROUND(DBMS_RANDOM.VALUE(80, 120), 2) -- wskaźnik
            );
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- Wydajność pracowników sortowni
DECLARE
    v_data DATE;
    v_okres VARCHAR2(7);
    v_sortownia VARCHAR2(10);
BEGIN
    FOR pracownik IN 1..20 LOOP
        v_sortownia := 'SORT0' || CEIL(pracownik/4); -- 4 pracowników na sortownię
        
        FOR mies IN 0..2 LOOP
            v_data := ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -mies);
            v_okres := TO_CHAR(v_data, 'YYYY-MM');
            
            INSERT INTO WYDAJNOSC_PRACOWNIKOW_SORTOWNI (
                WYDAJNOSC_ID, PRACOWNIK_ID, SORTOWNIA_ID, DATA_ANALIZY, OKRES_ROZLICZENIOWY,
                LICZBA_DNI_PRACY, LICZBA_ZMIAN, LICZBA_GODZIN_LACZNIE, LICZBA_PACZEK,
                SREDNIA_PACZEK_NA_GODZINE, WSKAZNIK_WYDAJNOSCI, OCENA_KIEROWNIKA
            ) VALUES (
                SEQ_WYDAJNOSC.NEXTVAL, pracownik, v_sortownia, v_data, v_okres,
                ROUND(DBMS_RANDOM.VALUE(18, 22)), -- dni pracy
                ROUND(DBMS_RANDOM.VALUE(18, 22)), -- zmiany
                ROUND(DBMS_RANDOM.VALUE(140, 180), 2), -- godziny
                ROUND(DBMS_RANDOM.VALUE(2000, 5000)), -- paczki
                ROUND(DBMS_RANDOM.VALUE(15, 35), 2), -- paczek/godz
                ROUND(DBMS_RANDOM.VALUE(85, 115), 2), -- wskaźnik
                ROUND(DBMS_RANDOM.VALUE(3, 5), 2) -- ocena
            );
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- Koszty operacyjne
DECLARE
    v_data DATE;
    v_kategorie SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
        'PALIWO', 'PLACE', 'UTRZYMANIE', 'ENERGIA', 'DZIERZAWA', 'NAPRAWY', 'MARKETING', 'IT'
    );
BEGIN
    FOR mies IN 0..11 LOOP -- ostatnie 12 miesięcy
        v_data := ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -mies);
        
        FOR i IN 1..v_kategorie.COUNT LOOP
            INSERT INTO KOSZTY_OPERACYJNE (
                KOSZT_ID, MIESIAC, KATEGORIA_KOSZTOW,
                KWOTA_PLAN, KWOTA_RZECZYWISTA, ROZNICA,
                DATA_KSIEGOWANIA, WPROWADZONE_PRZEZ
            ) VALUES (
                SEQ_RENTOWNOSC.NEXTVAL, v_data, v_kategorie(i),
                ROUND(DBMS_RANDOM.VALUE(10000, 100000), 2),
                ROUND(DBMS_RANDOM.VALUE(9000, 105000), 2),
                0, -- będzie obliczone
                v_data + 5, 'SYSTEM'
            );
        END LOOP;
    END LOOP;
    
    -- Aktualizuj różnice
    UPDATE KOSZTY_OPERACYJNE SET ROZNICA = KWOTA_RZECZYWISTA - KWOTA_PLAN;
    COMMIT;
END;
/

-- Analiza zwrotów
DECLARE
    v_data DATE;
    v_zwroty_total NUMBER;
BEGIN
    FOR mies IN 0..11 LOOP
        v_data := ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -mies);
        v_zwroty_total := ROUND(DBMS_RANDOM.VALUE(100, 500));
        
        INSERT INTO ANALIZA_ZWROTOW (
            ANALIZA_ID, MIESIAC,
            LICZBA_ZWROTOW_OGOLEM, LICZBA_ZWROTOW_NIEODEBRANE,
            LICZBA_ZWROTOW_USZKODZONE, LICZBA_ZWROTOW_BLEDNY_ADRES,
            LICZBA_ZWROTOW_INNE
        ) VALUES (
            SEQ_OPTYMALIZACJA.NEXTVAL, v_data,
            v_zwroty_total,
            ROUND(v_zwroty_total * 0.5), -- 50% nieodebrane
            ROUND(v_zwroty_total * 0.2), -- 20% uszkodzone
            ROUND(v_zwroty_total * 0.15), -- 15% błędny adres
            ROUND(v_zwroty_total * 0.15)  -- 15% inne
        );
    END LOOP;
    
    -- Oblicz procenty
    UPDATE ANALIZA_ZWROTOW SET
        PROCENT_NIEODEBRANE = ROUND(LICZBA_ZWROTOW_NIEODEBRANE * 100.0 / LICZBA_ZWROTOW_OGOLEM, 2),
        PROCENT_USZKODZONE = ROUND(LICZBA_ZWROTOW_USZKODZONE * 100.0 / LICZBA_ZWROTOW_OGOLEM, 2),
        PROCENT_BLEDNY_ADRES = ROUND(LICZBA_ZWROTOW_BLEDNY_ADRES * 100.0 / LICZBA_ZWROTOW_OGOLEM, 2);
    
    COMMIT;
END;
/

-- Fakty transakcje (przykładowe)
DECLARE
    v_data DATE;
    v_gabaryt CHAR(1);
    v_gabaryty SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('A', 'B', 'C');
BEGIN
    FOR dni IN 0..29 LOOP -- ostatnie 30 dni
        v_data := TRUNC(SYSDATE) - dni;
        
        FOR trans IN 1..100 LOOP -- 100 transakcji dziennie
            v_gabaryt := v_gabaryty(ROUND(DBMS_RANDOM.VALUE(1, 3)));
            
            INSERT INTO FAKT_TRANSAKCJE (
                TRANSAKCJA_ID, DATA_TRANSAKCJI, PRZESYLKA_ID,
                KLIENT_NADAWCA_ID, KLIENT_ODBIORCA_ID, TYP_TRANSAKCJI,
                PACZKOMAT_NADANIA_ID, PACZKOMAT_ODBIORU_ID, KURIER_ID,
                GABARYT, WAGA_KG, CENA_NETTO, CENA_BRUTTO,
                CZAS_DOSTAWY_H, CZY_DOSTARCZONA, CZY_W_TERMINIE
            ) VALUES (
                SEQ_FAKT_TRANS.NEXTVAL, v_data, SEQ_FAKT_TRANS.CURRVAL,
                ROUND(DBMS_RANDOM.VALUE(1, 100)), -- nadawca
                ROUND(DBMS_RANDOM.VALUE(1, 100)), -- odbiorca
                CASE ROUND(DBMS_RANDOM.VALUE(1, 3))
                    WHEN 1 THEN 'NADANIE'
                    WHEN 2 THEN 'ODBIOR'
                    ELSE 'ZWROT'
                END,
                'WAW0' || ROUND(DBMS_RANDOM.VALUE(1, 5)), -- paczkomat nadania
                'WAW0' || ROUND(DBMS_RANDOM.VALUE(1, 5)), -- paczkomat odbioru
                ROUND(DBMS_RANDOM.VALUE(1, 10)), -- kurier
                v_gabaryt,
                CASE v_gabaryt
                    WHEN 'A' THEN ROUND(DBMS_RANDOM.VALUE(0.5, 5), 2)
                    WHEN 'B' THEN ROUND(DBMS_RANDOM.VALUE(5, 10), 2)
                    ELSE ROUND(DBMS_RANDOM.VALUE(10, 25), 2)
                END,
                CASE v_gabaryt
                    WHEN 'A' THEN 12.20
                    WHEN 'B' THEN 14.63
                    ELSE 19.51
                END,
                CASE v_gabaryt
                    WHEN 'A' THEN 15.00
                    WHEN 'B' THEN 18.00
                    ELSE 24.00
                END,
                ROUND(DBMS_RANDOM.VALUE(12, 48), 2), -- czas dostawy
                CASE WHEN DBMS_RANDOM.VALUE < 0.95 THEN 'T' ELSE 'N' END, -- 95% dostarczone
                CASE WHEN DBMS_RANDOM.VALUE < 0.92 THEN 'T' ELSE 'N' END -- 92% w terminie
            );
        END LOOP;
    END LOOP;
    COMMIT;
END;
/