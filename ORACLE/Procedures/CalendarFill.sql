CREATE OR REPLACE PROCEDURE P_WYPELNIJ_WYMIAR_CZASU(p_data_od DATE, p_data_do DATE) AS
    v_data DATE;
BEGIN
    v_data := p_data_od;
    
    WHILE v_data <= p_data_do LOOP
        INSERT INTO D_CZAS (
            DATA_ID, ROK, KWARTAL, MIESIAC, TYDZIEN, 
            DZIEN_MIESIACA, DZIEN_TYGODNIA,
            NAZWA_MIESIACA, NAZWA_DNIA,
            CZY_WEEKEND, CZY_SWIETO
        ) VALUES (
            v_data,
            EXTRACT(YEAR FROM v_data),
            TO_NUMBER(TO_CHAR(v_data, 'Q')),
            EXTRACT(MONTH FROM v_data),
            TO_NUMBER(TO_CHAR(v_data, 'WW')),
            EXTRACT(DAY FROM v_data),
            TO_NUMBER(TO_CHAR(v_data, 'D')),
            TO_CHAR(v_data, 'Month', 'NLS_DATE_LANGUAGE=POLISH'),
            TO_CHAR(v_data, 'Day', 'NLS_DATE_LANGUAGE=POLISH'),
            CASE WHEN TO_CHAR(v_data, 'D') IN ('1', '7') THEN 'T' ELSE 'N' END,
            'N'
        );
        
        v_data := v_data + 1;
    END LOOP;
    
    COMMIT;
END;
/

BEGIN
    P_WYPELNIJ_WYMIAR_CZASU(DATE '2025-01-01', DATE '2029-12-31');
END;
/