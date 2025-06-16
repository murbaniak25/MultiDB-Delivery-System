USE DeliveryDB
GO


select * from HistoriaStatusowPrzesylek
select * from KodyOdbioru where PrzesylkaID = 36;
select * from Przesylki where PrzesylkaID = 36;

EXEC sp_OdbierzPrzesylkeZKodem @PrzesylkaId = 36, @KodOdbioru = 'MOUV81';
EXEC sp_OdbierzPrzesylkeZKodem @PrzesylkaId = 36, @KodOdbioru = 'GVAEXA';

EXEC sp_AktualizujStatusPrzesylki 
    @PrzesylkaID = 36,
    @NowyStatus = 'W paczkomacie',
    @Opis = 'paczka czeka w paczkomacie',
    @LokalizacjaID = 7;


EXEC sp_OdbierzPrzesylkeZKodem @PrzesylkaId = 36, @KodOdbioru = 'GVAEXA';


select * from vw_SzczegolyPrzesylki where PrzesylkaID = 36

select * from HistoriaStatusowPrzesylek where PrzesylkaID = 36;
select * from Przesylki where PrzesylkaID = 36;
select * from KodyOdbioru where PrzesylkaID = 36;