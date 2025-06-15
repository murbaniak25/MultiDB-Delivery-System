-- Kompleksowa analiza wydajności kuriera

DECLARE
    v_kurier_id NUMBER := 1;
    v_okres VARCHAR2(7) := TO_CHAR(SYSDATE, 'YYYY-MM');
BEGIN

    --Analiza wydajności
    DBMS_OUTPUT.PUT_LINE('1. Analiza wydajności kuriera:');
    P_ANALIZA_WYDAJNOSCI_KURIERA(v_kurier_id, v_okres);
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('2. Pozycja w rankingu:');
END;
/

-- Sprawdzenie pozycji w rankingu
SELECT 
    KURIER_ID,
    OKRES_ROZLICZENIOWY,
    LICZBA_DOSTAW,
    SREDNI_CZAS_DOSTAWY_MIN,
    WSKAZNIK_WYDAJNOSCI,
    RANKING,
    KATEGORIA
FROM V_RANKING_KURIEROW
WHERE KURIER_ID = 1
ORDER BY OKRES_ROZLICZENIOWY DESC;

-- Automatyczna ocena roczna
EXEC P_OCENA_PRACOWNIKA('KURIER', 1, TO_CHAR(SYSDATE, 'YYYY'), 100);

--Sprawdzenie oceny
SELECT * FROM V_OCENY_PRACOWNIKOW
WHERE TYP_PRACOWNIKA = 'KURIER' AND PRACOWNIK_ID = 1;