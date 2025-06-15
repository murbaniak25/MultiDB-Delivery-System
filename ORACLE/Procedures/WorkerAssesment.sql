CREATE OR REPLACE PROCEDURE P_OCENA_PRACOWNIKA(
    p_typ_pracownika IN VARCHAR2,
    p_pracownik_id IN NUMBER,
    p_okres IN VARCHAR2,
    p_oceniajacy_id IN NUMBER
) AS
    v_ocena_wydajnosc NUMBER;
    v_ocena_slowna VARCHAR2(50);
    v_rekomendacja_podwyzka NUMBER;
    v_wskaznik NUMBER;
BEGIN
    IF p_typ_pracownika = 'KURIER' THEN
        SELECT AVG(WSKAZNIK_WYDAJNOSCI)
        INTO v_wskaznik
        FROM WYDAJNOSC_KURIEROW
        WHERE KURIER_ID = p_pracownik_id
            AND OKRES_ROZLICZENIOWY LIKE p_okres || '%';
    ELSE
        SELECT AVG(WSKAZNIK_WYDAJNOSCI)
        INTO v_wskaznik
        FROM WYDAJNOSC_PRACOWNIKOW_SORTOWNI
        WHERE PRACOWNIK_ID = p_pracownik_id
            AND OKRES_ROZLICZENIOWY LIKE p_okres || '%';
    END IF;
    
    v_ocena_wydajnosc := CASE
        WHEN v_wskaznik >= 120 THEN 5
        WHEN v_wskaznik >= 110 THEN 4.5
        WHEN v_wskaznik >= 100 THEN 4
        WHEN v_wskaznik >= 90 THEN 3.5
        WHEN v_wskaznik >= 80 THEN 3
        ELSE 2.5
    END;
    
    v_ocena_slowna := CASE
        WHEN v_ocena_wydajnosc >= 4.5 THEN 'WYBITNY'
        WHEN v_ocena_wydajnosc >= 4 THEN 'BARDZO_DOBRY'
        WHEN v_ocena_wydajnosc >= 3.5 THEN 'DOBRY'
        WHEN v_ocena_wydajnosc >= 3 THEN 'DOSTATECZNY'
        ELSE 'NIEDOSTATECZNY'
    END;
    
    v_rekomendacja_podwyzka := CASE
        WHEN v_ocena_wydajnosc >= 4.5 THEN 15
        WHEN v_ocena_wydajnosc >= 4 THEN 10
        WHEN v_ocena_wydajnosc >= 3.5 THEN 5
        ELSE 0
    END;
    
    INSERT INTO OCENY_PRACOWNIKOW (
        OCENA_ID, TYP_PRACOWNIKA, PRACOWNIK_ID, OKRES_OCENY,
        DATA_OCENY, OCENA_WYDAJNOSC, OCENA_SLOWNA,
        REKOMENDACJA_PODWYZKA, OCENIAJACY_ID, STATUS_OCENY
    ) VALUES (
        SEQ_OCENY.NEXTVAL, p_typ_pracownika, p_pracownik_id, p_okres,
        SYSDATE, v_ocena_wydajnosc, v_ocena_slowna,
        v_rekomendacja_podwyzka, p_oceniajacy_id, 'ZATWIERDZONA'
    );
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Ocena zapisana. Wydajność: ' || v_ocena_wydajnosc || 
                        ' (' || v_ocena_slowna || ')');
END;
/