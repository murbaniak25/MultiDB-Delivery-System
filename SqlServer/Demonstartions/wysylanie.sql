USE DeliveryDB
GO


EXEC sp_NadajPrzesylkeV2
    @NadawcaID = 1, -- Marek z Warszawy
    @OdbiorcaEmail = 'jan.kowalski@example.com',
    @OdbiorcaImie = 'Jan',
    @OdbiorcaNazwisko = 'Kowalski',
    @OdbiorcaTelefon = '600700800',
    @OdbiorcaUlica = 'Nowa 10',
    @OdbiorcaKodPocztowy = '00-500',
    @OdbiorcaMiasto = 'Warszawa',
    @OdbiorcaWojewodztwo = 'Mazowieckie',
    @Gabaryt = 'A',
    @PaczkomatDocelowy = NULL, -- blad 
    @DostawaDoDomu = 0;


EXEC sp_NadajPrzesylkeV2
    @NadawcaID = 1, -- Marek z Warszawy
    @OdbiorcaEmail = 'ewa.przykladowa@example.com',
    @OdbiorcaImie = 'Ewa',
    @OdbiorcaNazwisko = 'Przykładowa',
    @OdbiorcaTelefon = '500600700',
    @OdbiorcaUlica = 'Kwiatowa 5',
    @OdbiorcaKodPocztowy = '30-001',
    @OdbiorcaMiasto = 'Kraków',
    @OdbiorcaWojewodztwo = 'Małopolskie',
    @Gabaryt = 'B',
    @PaczkomatDocelowy = 'KRK01',
    @DostawaDoDomu = 0;

EXEC sp_NadajPrzesylkeV2
    @NadawcaID = 2, -- Ewa z Krakowa
    @OdbiorcaEmail = 'anna.nowak@example.com',
    @OdbiorcaImie = 'Anna',
    @OdbiorcaNazwisko = 'Nowak',
    @OdbiorcaTelefon = '700800900',
    @OdbiorcaUlica = 'Długa 25',
    @OdbiorcaKodPocztowy = '80-100',
    @OdbiorcaMiasto = 'Gdańsk',
    @OdbiorcaWojewodztwo = 'Pomorskie',
    @Gabaryt = 'C',
    @PaczkomatDocelowy = NULL,
    @DostawaDoDomu = 1;


BEGIN TRY
    EXEC sp_NadajPrzesylkeV2
        @NadawcaID = 1,
        @OdbiorcaEmail = 'test@example.com',
        @OdbiorcaImie = 'Test',
        @OdbiorcaNazwisko = 'Testowy',
        @OdbiorcaTelefon = '111222333',
        @OdbiorcaUlica = 'Testowa 1',
        @OdbiorcaKodPocztowy = '00-001',
        @OdbiorcaMiasto = 'Warszawa',
        @OdbiorcaWojewodztwo = 'Mazowieckie',
        @Gabaryt = 'A',
        @PaczkomatDocelowy = 'NIEISTNIEJĄCY',
        @DostawaDoDomu = 0;
END TRY
BEGIN CATCH
    PRINT 'BŁĄD: ' + ERROR_MESSAGE();
END CATCH