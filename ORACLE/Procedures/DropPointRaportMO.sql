CREATE OR REPLACE PROCEDURE P_RAPORT_MIESIAC_PACZKOMAT(
    p_paczkomat_id IN VARCHAR2,
    p_miesiac IN DATE
) AS
    v_suma_nadan NUMBER := 0;
    v_suma_odbiorow NUMBER := 0;
    v_suma_zwrotow NUMBER := 0;
    v_sr_czas_skrytka NUMBER := 0;
    v_procent_terminowych NUMBER := 0;
    v_koszt_total NUMBER := 0;
BEGIN
    SELECT 
        SUM(LICZBA_NADAN),
        SUM(LICZBA_ODBIOROW),
        SUM(LICZBA_ZWROTOW),
        AVG(SREDNI_CZAS_W_SKRYTCE_H),
        AVG(PROCENT_TERMINOWYCH_ODBIOROW),
        SUM(KOSZT_OBSLUGI)
    INTO 
        v_suma_nadan, v_suma_odbiorow, v_suma_zwrotow,
        v_sr_czas_skrytka, v_procent_terminowych, v_koszt_total
    FROM STATYSTYKI_PUNKTOW_ODBIORU
    WHERE DROP_POINT_ID = p_paczkomat_id
        AND TRUNC(DATA_ANALIZY, 'MM') = TRUNC(p_miesiac, 'MM');
    
    DBMS_OUTPUT.PUT_LINE('=== RAPORT MIESIĘCZNY PACZKOMATU ===');
    DBMS_OUTPUT.PUT_LINE('Paczkomat: ' || p_paczkomat_id);
    DBMS_OUTPUT.PUT_LINE('Miesiąc: ' || TO_CHAR(p_miesiac, 'YYYY-MM'));
    DBMS_OUTPUT.PUT_LINE('------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Liczba nadań: ' || v_suma_nadan);
    DBMS_OUTPUT.PUT_LINE('Liczba odbiorów: ' || v_suma_odbiorow);
    DBMS_OUTPUT.PUT_LINE('Liczba zwrotów: ' || v_suma_zwrotow);
    DBMS_OUTPUT.PUT_LINE('Śr. czas w skrytce: ' || ROUND(v_sr_czas_skrytka, 2) || ' h');
    DBMS_OUTPUT.PUT_LINE('% terminowych odbiorów: ' || ROUND(v_procent_terminowych, 2) || '%');
    DBMS_OUTPUT.PUT_LINE('Koszt obsługi: ' || v_koszt_total || ' PLN');
    DBMS_OUTPUT.PUT_LINE('====================================');
END;
/