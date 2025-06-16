USE DeliveryDB
GO

DECLARE @TestPrzesylkaID INT;

EXEC sp_NadajPrzesylkeV2
    @NadawcaID = 1,
    @OdbiorcaEmail = 'xd123@riseup.net',
    @OdbiorcaImie = 'XD',
    @OdbiorcaNazwisko = 'Testowy',
    @OdbiorcaTelefon = '666777888',
    @OdbiorcaUlica = 'Główna 123',
    @OdbiorcaKodPocztowy = '00-123',
    @OdbiorcaMiasto = 'Warszawa',
    @OdbiorcaWojewodztwo = 'Mazowieckie',
    @Gabaryt = 'A',
    @DostawaDoDomu = 0,
    @PaczkomatDocelowy = 'KRK01';

SELECT TOP 1 @TestPrzesylkaID = PrzesylkaID 
FROM Przesylki 
ORDER BY PrzesylkaID DESC;

SELECT 
    ko.KodOdbioru,
    ko.DataUtworzenia,
    ko.DataWygasniecia,
    k.Email AS EmailOdbiorcy
FROM KodyOdbioru ko
INNER JOIN Przesylki p ON ko.PrzesylkaID = p.PrzesylkaID
INNER JOIN OdbiorcyPrzesylki op ON p.PrzesylkaID = op.PrzesylkaID
INNER JOIN Klienci k ON op.OdbiorcaID = k.KlientID
WHERE ko.PrzesylkaID = @TestPrzesylkaID;

SELECT TOP 3
    AdresEmail,
    Temat,
    TrescTekst
FROM KolejkaNotyfikacji
WHERE AdresEmail = 'xd123@riseup.net'
ORDER BY DataUtworzenia DESC;

