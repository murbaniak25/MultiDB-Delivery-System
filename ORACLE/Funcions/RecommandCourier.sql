CREATE OR REPLACE FUNCTION F_REKOMENDUJ_KURIERA(
    p_sortownia_id NUMBER,
    p_wojewodztwo VARCHAR2,
    p_gabaryt CHAR
) RETURN NUMBER AS
    v_kurier_id NUMBER;
BEGIN
    SELECT KURIER_ID INTO v_kurier_id
    FROM (
        SELECT 
            rk.KURIER_ID,
            CASE 
                -- Bonus za zgodność województwa
                WHEN rk.WOJEWODZTWO = p_wojewodztwo THEN rk.WSKAZNIK_GOTOWOSCI + 10
                -- Bonus za preferowany gabaryt
                WHEN kp.PREFEROWANY_GABARYT = p_gabaryt THEN rk.WSKAZNIK_GOTOWOSCI + 5
                ELSE rk.WSKAZNIK_GOTOWOSCI
            END AS WSKAZNIK_SKORYGOWANY
        FROM V_REKOMENDACJA_KURIERA rk
        JOIN D_KURIER_PROFIL kp ON rk.KURIER_ID = kp.KURIER_ID
        WHERE rk.SORTOWNIA_ID = p_sortownia_id
            AND rk.WOLNA_POJEMNOSC > 0
            AND rk.WSKAZNIK_GOTOWOSCI IS NOT NULL
        ORDER BY WSKAZNIK_SKORYGOWANY DESC
    )
    WHERE ROWNUM = 1;
    
    RETURN v_kurier_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN NULL;
END;
/
