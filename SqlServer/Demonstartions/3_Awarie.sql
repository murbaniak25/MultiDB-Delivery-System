USE DeliveryDB
GO


EXEC sp_ZglosAwarie
    @TypObiektu = 'DropPoint',
    @ObiektID = 7, 
    @Opis = 'Awaria zasilania – paczkomat nieczynny',
    @Priorytet = 'Krytyczny',
    @PracownikID = 1;

EXEC sp_ZglosAwarie
    @TypObiektu = 'Sortownia',
    @ObiektID = 1,
    @Opis = 'Awaria taśmociągu nr 3. Zmniejszona przepustowość o 30%.',
    @Priorytet = 'Wysoki',
    @PracownikID = 2;

EXEC sp_ZglosBlad
    @KodBledu = 'ERR001',
    @OpisZgloszenia = 'Skrytka A-5 nie otwiera się mimo wprowadzenia poprawnego kodu',
    @ZrodloZgloszenia = 'Uzytkownik',
    @KlientID = 1,
    @ObiektID = 11; -- skrytka


EXEC sp_NadajPrzesylkeV2
    @NadawcaID = 1,
    @OdbiorcaEmail = 'ewa.przykladowa@example.com',
    @OdbiorcaImie = 'Ewa',
    @OdbiorcaNazwisko = 'Przykładowa',
    @OdbiorcaTelefon = '500600700',
    @OdbiorcaUlica = 'Kwiatowa 5',
    @OdbiorcaKodPocztowy = '30-001',
    @OdbiorcaMiasto = 'Kraków',
    @OdbiorcaWojewodztwo = 'małopolskie',
    @Gabaryt = 'A',
    @PaczkomatDocelowy = 'KRK01',
    @DostawaDoDomu = 0;

EXEC sp_AktualizujStatusAwarii
    @AwariaID = 1,
    @NowyStatus = 'Naprawiona';


SELECT * FROM AwarieInfrastruktury
SELECT * FROM ObiektInfrastruktury

-- Zgloszenia
SELECT * FROM vw_PodsumowanieAwarii;

-- Szczegolny zgloszen
SELECT 
    AwariaID,
    NazwaObiektu,
    Opis,
    Priorytet,
    ZgloszonePrzez,
    GodzinOdZgloszenia,
    PrzesylkiDotknieteProblemem
FROM vw_AktywneAwarie
ORDER BY 
    CASE Priorytet 
        WHEN 'Krytyczny' THEN 1
        WHEN 'Wysoki' THEN 2
        WHEN 'Sredni' THEN 3
        ELSE 4
    END;

-- Widok podsumuwujacy 
SELECT * FROM vw_PodsumowanieBledow
ORDER BY LiczbaZgloszen DESC;
