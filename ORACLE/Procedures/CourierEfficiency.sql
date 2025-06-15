CREATE OR REPLACE PROCEDURE P_ANALIZA_WYDAJNOSCI_KURIERA(
    p_kurier_id IN NUMBER,
    p_okres IN VARCHAR2
) AS
    v_avg_dostaw NUMBER;
    v_avg_czas NUMBER;
    v_wydajnosc NUMBER;
BEGIN
    SELECT AVG(LICZBA_DOSTAW), AVG(SREDNI_CZAS_DOSTAWY_MIN)
    INTO v_avg_dostaw, v_avg_czas
    FROM WYDAJNOSC_KURIEROW
    WHERE OKRES_ROZLICZENIOWY = p_okres;
    
    UPDATE WYDAJNOSC_KURIEROW
    SET WSKAZNIK_WYDAJNOSCI = 
        CASE 
            WHEN v_avg_dostaw > 0 AND SREDNI_CZAS_DOSTAWY_MIN > 0 THEN
                (LICZBA_DOSTAW / v_avg_dostaw * 50) + 
                ((v_avg_czas / SREDNI_CZAS_DOSTAWY_MIN) * 50)
            ELSE 100
        END
    WHERE KURIER_ID = p_kurier_id AND OKRES_ROZLICZENIOWY = p_okres;
    
    COMMIT;
    
    FOR rec IN (
        SELECT * FROM WYDAJNOSC_KURIEROW 
        WHERE KURIER_ID = p_kurier_id AND OKRES_ROZLICZENIOWY = p_okres
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Kurier ID: ' || rec.KURIER_ID);
        DBMS_OUTPUT.PUT_LINE('Okres: ' || rec.OKRES_ROZLICZENIOWY);
        DBMS_OUTPUT.PUT_LINE('Liczba dostaw: ' || rec.LICZBA_DOSTAW);
        DBMS_OUTPUT.PUT_LINE('Średni czas: ' || rec.SREDNI_CZAS_DOSTAWY_MIN || ' min');
        DBMS_OUTPUT.PUT_LINE('Wskaźnik wydajności: ' || rec.WSKAZNIK_WYDAJNOSCI);
    END LOOP;
END;
/