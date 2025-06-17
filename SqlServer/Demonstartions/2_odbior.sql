USE DeliveryDB
GO


select * from HistoriaStatusowPrzesylek where PrzesylkaID = 2;
select * from KodyOdbioru where PrzesylkaID = 2;


EXEC sp_OdbierzPrzesylkeZKodem @PrzesylkaId = 2, @KodOdbioru = 'MOUV81';
EXEC sp_OdbierzPrzesylkeZKodem @PrzesylkaId = 2, @KodOdbioru = 'GVAEXA';

EXEC sp_AktualizujStatusPrzesylki 
    @PrzesylkaID = 2,
    @NowyStatus = 'W paczkomacie',
    @Opis = 'paczka czeka w paczkomacie',
    @LokalizacjaID = 7;


EXEC sp_OdbierzPrzesylkeZKodem @PrzesylkaId = 2, @KodOdbioru = 'GVAEXA';


select * from vw_SzczegolyPrzesylki where PrzesylkaID = 2

select * from HistoriaStatusowPrzesylek where PrzesylkaID = 2;
select * from Przesylki where PrzesylkaID = 2;
select * from KodyOdbioru where PrzesylkaID = 2;