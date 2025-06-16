USE DeliveryDB
GO

BEGIN TRY
    EXEC sp_NadajPrzesylkeV2
        @NadawcaID = 1,
        @OdbiorcaEmail = 'test@example.com',
        @OdbiorcaImie = 'Test',
        @OdbiorcaNazwisko = 'Testowy',
        @OdbiorcaTelefon = '123456789',
        @OdbiorcaUlica = 'Testowa 1',
        @OdbiorcaKodPocztowy = '00-001',
        @OdbiorcaMiasto = 'Warszawa',
        @OdbiorcaWojewodztwo = 'Mazowieckie',
        @Gabaryt = 'X', -- Nieprawidłowy gabaryt!
        @DostawaDoDomu = 0,
        @PaczkomatDocelowy = 'WAW01';
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH

BEGIN TRY
    EXEC sp_NadajPrzesylkeV2
        @NadawcaID = 1,
        @OdbiorcaEmail = 'test2@example.com',
        @OdbiorcaImie = 'Test',
        @OdbiorcaNazwisko = 'Drugi',
        @OdbiorcaTelefon = '123456789',
        @OdbiorcaUlica = 'Testowa 2',
        @OdbiorcaKodPocztowy = '00-002',
        @OdbiorcaMiasto = 'Warszawa',
        @OdbiorcaWojewodztwo = 'Mazowieckie',
        @Gabaryt = 'A',
        @DostawaDoDomu = 0, -- Dostawa do paczkomatu
        @PaczkomatDocelowy = NULL; -- nie podano paczkomatu
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH

BEGIN TRY
    EXEC sp_NadajPrzesylkeV2
        @NadawcaID = 1,
        @OdbiorcaEmail = 'test3@example.com',
        @OdbiorcaImie = 'Test',
        @OdbiorcaNazwisko = 'Trzeci',
        @OdbiorcaTelefon = '123456789',
        @OdbiorcaUlica = 'Testowa 3',
        @OdbiorcaKodPocztowy = '00-003',
        @OdbiorcaMiasto = 'Warszawa',
        @OdbiorcaWojewodztwo = 'Mazowieckie',
        @Gabaryt = 'B',
        @DostawaDoDomu = 1, -- Dostawa do domu
        @PaczkomatDocelowy = 'WAW01'; -- Podano paczkomat
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH

BEGIN TRY
    EXEC sp_NadajPrzesylkeV2
        @NadawcaID = 1,
        @OdbiorcaEmail = 'test4@example.com',
        @OdbiorcaImie = 'Test',
        @OdbiorcaNazwisko = 'Czwarty',
        @OdbiorcaTelefon = '123456789',
        @OdbiorcaUlica = 'Testowa 4',
        @OdbiorcaKodPocztowy = '00-004',
        @OdbiorcaMiasto = 'Warszawa',
        @OdbiorcaWojewodztwo = 'Mazowieckie',
        @Gabaryt = 'C',
        @DostawaDoDomu = 0,
        @PaczkomatDocelowy = 'FAKE99'; -- Nieistniejący paczkomat
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH