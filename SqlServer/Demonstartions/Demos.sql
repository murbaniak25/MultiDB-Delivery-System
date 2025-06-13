USE DeliveryDB
GO

DECLARE @NadawcaID INT = 1; -- Marek 
DECLARE @OdbiorcaID INT = 2; -- Ewa
DECLARE @NowaPrzesylkaID INT;

-- Nadanie przesyłki
EXEC sp_NadajPrzesylke 
    @NadawcaID = @NadawcaID,
    @OdbiorcaID = @OdbiorcaID,
    @Gabaryt = 'A',
    @DroppointID = 7, -- Paczkomat w Krakowie
    @AdresNadaniaID = 11; -- Adres Marka

-- Pokaż status
SELECT TOP 1 * FROM vw_StatusPrzesylek ORDER BY PrzesylkaID DESC;

-------------------------------------------------------

--Przesyłka dociera do paczkomatu

-- Pobierz ID ostatniej przesyłki
SELECT TOP 1 @NowaPrzesylkaID = PrzesylkaID FROM Przesylki ORDER BY PrzesylkaID DESC;

-- Rejestracja w sortowni
EXEC sp_ZarejestrujOperacjeSortownicza 
    @PrzesylkaID = @NowaPrzesylkaID,
    @PracownikID = 2, -- Anna Nowak
    @TypOperacji = 'Przyjęcie od kuriera',
    @Uwagi = 'Przesyłka w dobrym stanie';

WAITFOR DELAY '00:00:01';

EXEC sp_ZarejestrujOperacjeSortownicza 
    @PrzesylkaID = @NowaPrzesylkaID,
    @PracownikID = 2,
    @TypOperacji = 'Sortowanie do wysyłki',
    @Uwagi = 'Kierunek: Kraków';

-- Przypisz do skrytki w paczkomacie
EXEC sp_PrzypiszDoSkrytki @PrzesylkaID = @NowaPrzesylkaID;

SELECT 
    PrzesylkaID,
    NadawcaNazwa,
    OdbiorcaNazwa,
    PunktOdbioru,
    Skrytka,
    StatusPrzesylki
FROM vw_StatusPrzesylek 
WHERE PrzesylkaID = @NowaPrzesylkaID;

-- Monitoring 

SELECT * FROM vw_MonitoringPaczkomatow WHERE Miasto = 'Kraków';

-- Awaria 

DECLARE @AwariaID INT;

-- Zgłoś awarię
EXEC sp_ZglosAwarie 
    @TypObiektu = 'DropPoint',
    @ObiektID = 7,
    @Opis = 'Ekran dotykowy nie reaguje na dotyk, klienci nie mogą odbierać przesyłek',
    @Priorytet = 'Wysoki',
    @PracownikID = 3; -- Piotr Wiśniewski

SELECT * FROM vw_AktywneAwarie;

-- Zwrot 

DECLARE @PrzesylkaDoZwrotuID INT;

EXEC sp_NadajPrzesylke 
    @NadawcaID = 3, -- Tomasz
    @OdbiorcaID = 4, -- Karolina
    @Gabaryt = 'B',
    @DroppointID = 9,
    @AdresNadaniaID = 13;

SELECT TOP 1 @PrzesylkaDoZwrotuID = PrzesylkaID FROM Przesylki ORDER BY PrzesylkaID DESC;

EXEC sp_PrzypiszDoSkrytki @PrzesylkaID = @PrzesylkaDoZwrotuID;

-- Zgłoś zwrot
EXEC sp_ZarejestrujZwrot 
    @KlientID = 4, -- Karolina
    @PrzesylkaID = @PrzesylkaDoZwrotuID,
    @Przyczyna = 'Produkt niezgodny z opisem';

PRINT 'Status przesyłki po zgłoszeniu zwrotu:'
SELECT 
    PrzesylkaID,
    NadawcaNazwa,
    OdbiorcaNazwa,
    StatusPrzesylki
FROM vw_StatusPrzesylek 
WHERE PrzesylkaID = @PrzesylkaDoZwrotuID;

-- Blad w systemie

EXEC sp_ZglosBlad 
    @KodBledu = 'ERR001',
    @OpisZgloszenia = 'Skrytka A-5 w paczkomacie WAW01 nie otwiera się pomimo poprawnego kodu',
    @ZrodloZgloszenia = 'Uzytkownik',
    @KlientID = 1,
    @ObiektID = 15;


-- obciazenie kurierzy 

DECLARE @i INT = 1;
WHILE @i <= 5
BEGIN
    INSERT INTO OperacjeKurierskie (PrzesylkaID, KurierID, CzasRozpoczecia, CzasZakonczenia, Status, Uwagi)
    VALUES 
        (@i, 1, DATEADD(HOUR, -@i, GETDATE()), DATEADD(MINUTE, -@i*30, GETDATE()), 'Dostarczona', 'OK'),
        (@i, 2, DATEADD(HOUR, -@i-1, GETDATE()), DATEADD(MINUTE, -@i*25, GETDATE()), 'Dostarczona', 'OK');
    SET @i = @i + 1;
END

SELECT 
    Kurier,
    Sortownia,
    LiczbaPrzesylek,
    PrzesylkiDzis,
    SredniCzasDostawy AS 'Śr. czas dostawy (min)'
FROM vw_ObciazenieKurierow
WHERE LiczbaPrzesylek > 0;

-- historia powiadomien 

SELECT TOP 5
    DataWyslania,
    Odbiorca,
    TypPowiadomienia,
    Kanal,
    Tresc
FROM vw_HistoriaPowiadomien;

-- dostepnosc skrytek w paczko 

EXEC sp_SprawdzDostepnoscSkrytek @DroppointID = 7;

-- zmiana statusu awarii 

EXEC sp_AktualizujStatusAwarii 
    @AwariaID = 1,
    @NowyStatus = 'Naprawiona';

SELECT * FROM vw_AktywneAwarie;