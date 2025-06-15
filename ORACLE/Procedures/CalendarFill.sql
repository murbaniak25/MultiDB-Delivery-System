CREATE OR REPLACE PROCEDURE P_WYPELNIJ_DIM_CZAS(
    p_data_od DATE,
    p_data_do DATE
) AS
    v_data DATE;
    v_data_id NUMBER := 1;
BEGIN
    v_data := p_data_od;
    
    DELETE FROM DIM_CZAS WHERE DATA_PELNA BETWEEN p_data_od AND p_data_do;
    
    WHILE v_data <= p_data_do LOOP
        INSERT INTO DIM_CZAS (
            DATA_ID,
            DATA_PELNA,
            ROK,
            MIESIAC,
            DZIEN,
            KWARTAL,
            TYDZIEN_ROKU,
            DZIEN_TYGODNIA,
            NAZWA_MIESIACA,
            NAZWA_DNIA,
            CZY_WEEKEND,
            CZY_SWIETO,
            NAZWA_SWIETA
        ) VALUES (
            v_data_id,
            v_data,
            EXTRACT(YEAR FROM v_data),
            EXTRACT(MONTH FROM v_data),
            EXTRACT(DAY FROM v_data),
            CEIL(EXTRACT(MONTH FROM v_data)/3),
            TO_NUMBER(TO_CHAR(v_data, 'IW')),
            TO_NUMBER(TO_CHAR(v_data, 'D')),
            TO_CHAR(v_data, 'Month', 'NLS_DATE_LANGUAGE=POLISH'),
            TO_CHAR(v_data, 'Day', 'NLS_DATE_LANGUAGE=POLISH'),
            CASE WHEN TO_CHAR(v_data, 'D') IN ('1', '7') THEN 'T' ELSE 'N' END,
            CASE 
                WHEN TO_CHAR(v_data, 'DD-MM') IN ('01-01', '06-01', '03-05', '01-05', '15-08', '01-11', '11-11', '25-12', '26-12') THEN 'T'
                ELSE 'N'
            END,
            CASE TO_CHAR(v_data, 'DD-MM')
                WHEN '01-01' THEN 'Nowy Rok'
                WHEN '06-01' THEN 'Święto Trzech Króli'
                WHEN '03-05' THEN 'Święto Konstytucji 3 Maja'
                WHEN '01-05' THEN 'Święto Pracy'
                WHEN '15-08' THEN 'Wniebowzięcie NMP'
                WHEN '01-11' THEN 'Wszystkich Świętych'
                WHEN '11-11' THEN 'Święto Niepodległości'
                WHEN '25-12' THEN 'Boże Narodzenie'
                WHEN '26-12' THEN 'Drugi dzień świąt'
                ELSE NULL
            END
        );
        
        v_data_id := v_data_id + 1;
        v_data := v_data + 1;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Wypełniono wymiar czasu dla ' || (v_data_id - 1) || ' dni');
END;
/


EXEC P_WYPELNIJ_DIM_CZAS(DATE '2024-01-01', DATE '2025-12-31');