CREATE OR REPLACE PROCEDURE P_RAPORT_FINANSOWY(
    p_rok IN NUMBER DEFAULT NULL,
    p_miesiac IN NUMBER DEFAULT NULL
) AS
    v_rok NUMBER := COALESCE(p_rok, EXTRACT(YEAR FROM SYSDATE));
    v_miesiac NUMBER := COALESCE(p_miesiac, EXTRACT(MONTH FROM SYSDATE));
    v_total_przesylki NUMBER;
    v_szacowany_przychod NUMBER;
    v_koszt_kurierow NUMBER;
    v_marza NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== RAPORT FINANSOWY ===');
    DBMS_OUTPUT.PUT_LINE('Okres: ' || v_miesiac || '/' || v_rok);
    DBMS_OUTPUT.PUT_LINE('');
    
    SELECT 
        LiczbaPrzesylek,
        LiczbaPrzesylek * 15 AS SzacowanyPrzychod, -- 15 zł średnia za przesyłkę
        AktywniKurierzy * 4000 AS KosztKurierow -- 4000 zł średnia pensja kuriera
    INTO v_total_przesylki, v_szacowany_przychod, v_koszt_kurierow
    FROM STAT_AGREGACJE_MIESIECZNE
    WHERE Rok = v_rok AND Miesiac = v_miesiac
    AND ROWNUM = 1;
    
    v_marza := v_szacowany_przychod - v_koszt_kurierow;
    
    DBMS_OUTPUT.PUT_LINE('Liczba przesyłek: ' || v_total_przesylki);
    DBMS_OUTPUT.PUT_LINE('Szacowany przychód: ' || v_szacowany_przychod || ' zł');
    DBMS_OUTPUT.PUT_LINE('Koszt kurierów: ' || v_koszt_kurierow || ' zł');
    DBMS_OUTPUT.PUT_LINE('Marża brutto: ' || v_marza || ' zł');
    DBMS_OUTPUT.PUT_LINE('Rentowność: ' || ROUND((v_marza * 100.0) / v_szacowany_przychod, 2) || '%');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Brak danych dla okresu ' || v_miesiac || '/' || v_rok);
END;
/
