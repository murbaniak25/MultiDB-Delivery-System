CREATE OR REPLACE PROCEDURE P_ANALIZA_PACZKOMATOW(
    p_wojewodztwo IN VARCHAR2 DEFAULT NULL,
    p_prog_wykorzystania IN NUMBER DEFAULT 80
) AS
    v_status VARCHAR2(50);
    v_akcja VARCHAR2(200);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Próg alarmowy: ' || p_prog_wykorzystania || '%');
    DBMS_OUTPUT.PUT_LINE('');
    
    FOR rec IN (
        SELECT 
            DroppointID,
            DroppointNazwa,
            Typ,
            Miasto,
            Wojewodztwo,
            LiczbaSkrytek,
            LiczbaWolnychSkrytek,
            LiczbaZajetychSkrytek,
            LiczbaObsluzonychPrzesylek,
            ProcentWykorzystania,
            LiczbaAwarii,
            LiczbaOtwartychAwarii
        FROM STAT_DROPPOINTY_SNAPSHOT
        WHERE (p_wojewodztwo IS NULL OR Wojewodztwo = p_wojewodztwo)
          AND DataAktualizacji = (SELECT MAX(DataAktualizacji) FROM STAT_DROPPOINTY_SNAPSHOT)
        ORDER BY ProcentWykorzystania DESC
    ) LOOP
        IF rec.ProcentWykorzystania >= 95 THEN
            v_status := 'KRYTYCZNY';
            v_akcja := 'Natychmiastowe rozszerzenie lub dodanie nowego punktu';
        ELSIF rec.ProcentWykorzystania >= p_prog_wykorzystania THEN
            v_status := 'WYSOKI';
            v_akcja := 'Monitorowanie i planowanie rozszerzenia';
        ELSIF rec.ProcentWykorzystania >= 50 THEN
            v_status := 'OPTYMALNY';
            v_akcja := 'Brak działań';
        ELSE
            v_status := 'NISKI';
            v_akcja := 'Analiza przyczyn niskiego wykorzystania';
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('Paczkomat: ' || rec.DroppointNazwa);
        DBMS_OUTPUT.PUT_LINE('  Lokalizacja: ' || rec.Miasto || ', ' || rec.Wojewodztwo);
        DBMS_OUTPUT.PUT_LINE('  Typ: ' || rec.Typ);
        DBMS_OUTPUT.PUT_LINE('  Skrytki: ' || rec.LiczbaSkrytek || ' (wolne: ' || rec.LiczbaWolnychSkrytek || ')');
        DBMS_OUTPUT.PUT_LINE('  Wykorzystanie: ' || rec.ProcentWykorzystania || '% - ' || v_status);
        DBMS_OUTPUT.PUT_LINE('  Obsłużone przesyłki: ' || rec.LiczbaObsluzonychPrzesylek);
        DBMS_OUTPUT.PUT_LINE('  Awarie: ' || rec.LiczbaAwarii || ' (otwarte: ' || rec.LiczbaOtwartychAwarii || ')');
        DBMS_OUTPUT.PUT_LINE('  Akcja: ' || v_akcja);
        DBMS_OUTPUT.PUT_LINE('---');
    END LOOP;
END;
/
