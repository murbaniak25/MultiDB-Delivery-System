USE DeliveryDB
GO

select * from vw_SzczegolyPrzesylki where PrzesylkaID = 9
select * from HistoriaStatusowPrzesylek where PrzesylkaID = 9
select * from OdbiorcyPrzesylki where PrzesylkaID = 9

EXEC sp_ZarejestrujZwrot
    @KlientID = 12,
    @PrzesylkaID = 10,
    @Przyczyna = 'Uszkodzona zawartość';

EXEC sp_SymulujZwrotPrzesylki @PrzesylkaID = 10;


EXEC sp_ZarejestrujZwrot
    @KlientID = 12,
    @PrzesylkaID = 4,
    @Przyczyna = 'Nie dotarła jeszcze';


-- po 14 dniach na zwrot
UPDATE HistoriaStatusowPrzesylek
SET DataZmiany = DATEADD(DAY, -20, GETDATE())
WHERE PrzesylkaID = 9 AND Status = 'Dostarczona';

EXEC sp_ZarejestrujZwrot
    @KlientID = 15,
    @PrzesylkaID = 9,
    @Przyczyna = 'Za późno na zwrot';