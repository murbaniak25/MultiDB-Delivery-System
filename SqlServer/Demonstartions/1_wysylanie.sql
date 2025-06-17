USE DeliveryDB
GO

-- normalna dostawa do paczkomatu
EXEC sp_NadajPrzesylkeV2
    @NadawcaID = 1,
    @OdbiorcaEmail = 'test.gdansk@example.com',
    @OdbiorcaImie = 'Test',
    @OdbiorcaNazwisko = 'Gdański',
    @OdbiorcaTelefon = '700800900',
    @OdbiorcaUlica = 'Morska 10',
    @OdbiorcaKodPocztowy = '80-100',
    @OdbiorcaMiasto = 'Gdańsk',
    @OdbiorcaWojewodztwo = 'Pomorskie',
    @Gabaryt = 'B',
    @PaczkomatDocelowy = 'KRK01',
    @DostawaDoDomu = 0;

-- dostawa do domu
EXEC sp_NadajPrzesylkeV2
    @NadawcaID = 1, 
    @OdbiorcaEmail = 'test.gdansk@example.com',
    @OdbiorcaImie = 'Test',
    @OdbiorcaNazwisko = 'Gdański',
    @OdbiorcaTelefon = '700800900',
    @OdbiorcaUlica = 'Morska 10',
    @OdbiorcaKodPocztowy = '80-100',
    @OdbiorcaMiasto = 'Gdańsk',
    @OdbiorcaWojewodztwo = 'Pomorskie',
    @Gabaryt = 'B',
    @PaczkomatDocelowy = NULL,
    @DostawaDoDomu = 1;

-- dostawa do paczkomaty + mylacy adres
EXEC sp_NadajPrzesylkeV2
    @NadawcaID = 1, 
    @OdbiorcaEmail = 'test.krakow@example.com',
    @OdbiorcaImie = 'Test',
    @OdbiorcaNazwisko = 'Krakowski',
    @OdbiorcaTelefon = '600700800',
    @OdbiorcaUlica = 'Testowa 1',
    @OdbiorcaKodPocztowy = '00-001',
    @OdbiorcaMiasto = 'Warszawa', -- Adres odbiorcy w Warszawie
    @OdbiorcaWojewodztwo = 'Mazowieckie', -- ale mieszka w Mazowieckim
    @Gabaryt = 'A',
    @PaczkomatDocelowy = 'KRK01',
    @DostawaDoDomu = 0;


EXEC sp_SymulujCyklZyciaPrzesylkiV2 @PrzesylkaId = 2;

select * from vw_SzczegolyPrzesylki where PrzesylkaID = 2;
select * from vw_HistoriaPrzesylki where PrzesylkaID = 2;