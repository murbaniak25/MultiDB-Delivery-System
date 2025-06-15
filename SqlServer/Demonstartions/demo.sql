USE DeliveryDB
GO


-- Odbiorca: nowy odbiorca
-- Paczkomat docelowy: 'WAW01M'

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
    @PaczkomatDocelowy = 'WAW01'; -- Paczkomat docelowy
GO

-- Odbiorca: nowy odbiorca
-- Paczkomat docelowy: NULL (przesyłka na adres domowy)

EXEC sp_NadajPrzesylkeV2
    @NadawcaID = 2,
    @OdbiorcaEmail = 'jan.kowalski@example.com',
    @OdbiorcaImie = 'Jan',
    @OdbiorcaNazwisko = 'Kowalski',
    @OdbiorcaTelefon = '501700800',
    @OdbiorcaUlica = 'Leśna 10',
    @OdbiorcaKodPocztowy = '80-001',
    @OdbiorcaMiasto = 'Gdańsk',
    @OdbiorcaWojewodztwo = 'pomorskie',
    @Gabaryt = 'B',
    @PaczkomatDocelowy = NULL; -- Przesyłka na adres domowy
GO


SELECT * FROM Droppointy
select * from ObiektInfrastruktury
SELECT * FROM vw_SzczegolyPrzesylki;
SELECT * FROM vw_SzczegolyPrzesylki WHERE PrzesylkaID = 102;
