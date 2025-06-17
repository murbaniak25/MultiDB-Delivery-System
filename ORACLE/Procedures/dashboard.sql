CREATE OR REPLACE PROCEDURE P_DASHBOARD_MENEDZERSKI AS
    v_data_raportu DATE := SYSDATE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('╔══════════════════════════════════════════════════════════════╗');
    DBMS_OUTPUT.PUT_LINE('║                    DASHBOARD MENEDŻERSKI                    ║');
    DBMS_OUTPUT.PUT_LINE('║                  ' || TO_CHAR(v_data_raportu, 'DD/MM/YYYY HH24:MI') || '                      ║');
    DBMS_OUTPUT.PUT_LINE('╚══════════════════════════════════════════════════════════════╝');
    DBMS_OUTPUT.PUT_LINE('');
    
    DBMS_OUTPUT.PUT_LINE('📊 KURIERZY:');
    FOR rec IN (
        SELECT 
            COUNT(*) AS LiczbaKurierow,
            ROUND(AVG(LiczbaUdanychDostaw), 2) AS SrednieDostaw,
            ROUND(AVG(SredniCzasDostawyMinuty), 2) AS SredniCzas,
            MAX(LiczbaUdanychDostaw) AS NajlepszyWynik
        FROM STAT_KURIERZY_SNAPSHOT
        WHERE DataAktualizacji = (SELECT MAX(DataAktualizacji) FROM STAT_KURIERZY_SNAPSHOT)
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('  • Aktywni kurierzy: ' || rec.LiczbaKurierow);
        DBMS_OUTPUT.PUT_LINE('  • Średnie dostawy: ' || rec.SrednieDostaw);
        DBMS_OUTPUT.PUT_LINE('  • Średni czas dostawy: ' || rec.SredniCzas || ' min');
        DBMS_OUTPUT.PUT_LINE('  • Najlepszy wynik: ' || rec.NajlepszyWynik || ' dostaw');
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    DBMS_OUTPUT.PUT_LINE('🏭 SORTOWNIE:');
    FOR rec IN (
        SELECT 
            COUNT(*) AS LiczbaSortowni,
            SUM(LiczbaPrzetworzonych) AS TotalPrzetworzonych,
            ROUND(AVG(SredniCzasPrzetwarzaniaMinuty), 2) AS SredniCzasPrzetwarzania
        FROM STAT_SORTOWNIE_SNAPSHOT
        WHERE DataAktualizacji = (SELECT MAX(DataAktualizacji) FROM STAT_SORTOWNIE_SNAPSHOT)
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('  • Aktywne sortownie: ' || rec.LiczbaSortowni);
        DBMS_OUTPUT.PUT_LINE('  • Przetworzono łącznie: ' || rec.TotalPrzetworzonych);
        DBMS_OUTPUT.PUT_LINE('  • Średni czas przetwarzania: ' || rec.SredniCzasPrzetwarzania || ' min');
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    DBMS_OUTPUT.PUT_LINE('📦 PACZKOMATY:');
    FOR rec IN (
        SELECT 
            COUNT(*) AS LiczbaPaczkomatow,
            ROUND(AVG(ProcentWykorzystania), 2) AS SrednieWykorzystanie,
            SUM(LiczbaAwarii) AS TotalAwarii
        FROM STAT_DROPPOINTY_SNAPSHOT
        WHERE DataAktualizacji = (SELECT MAX(DataAktualizacji) FROM STAT_DROPPOINTY_SNAPSHOT)
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('  • Aktywne paczkomaty: ' || rec.LiczbaPaczkomatow);
        DBMS_OUTPUT.PUT_LINE('  • Średnie wykorzystanie: ' || rec.SrednieWykorzystanie || '%');
        DBMS_OUTPUT.PUT_LINE('  • Łączne awarie: ' || rec.TotalAwarii);
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════');
END;
/
