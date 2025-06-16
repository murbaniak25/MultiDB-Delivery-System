USE DeliveryDB;
GO

EXEC sp_addlinkedserver 
    @server = 'Excel_CenyUslug', 
    @srvproduct = 'Excel', 
    @provider = 'Microsoft.ACE.OLEDB.12.0', 
    @datasrc = 'C:\ExcelData\Ceny_uslug.xlsx', 
    @provstr = 'Excel 12.0;IMEX=1;HDR=YES;';

INSERT INTO dbo.CennikPodstawowy (ID_Cennika, TypUslugi, Gabaryt, Strefa, CenaNetto, StawkaVAT, CenaBrutto, DataOd, DataDo, Aktywny)
SELECT 
    [ID_Cennika],
    [Typ_Uslugi],
    [Gabaryt],
    [Strefa],
    [Cena_netto],
    [Stawka_VAT],
    [Cena_Brutto],
    CAST([Data_Od] AS DATE),
    CAST([Data_Do] AS DATE),
    CASE WHEN [Aktykny] = 'TAK' THEN 1 ELSE 0 END
FROM OPENQUERY(Excel_CenyUslug, 'SELECT * FROM [Cennik_Podst$]');

EXEC sp_dropserver 'Excel_CenyUslug', 'droplogins';

-----

EXEC sp_addlinkedserver 
    @server = 'Excel_Dodatki', 
    @srvproduct = 'Excel', 
    @provider = 'Microsoft.ACE.OLEDB.12.0', 
    @datasrc = 'C:\ExcelData\Ceny_uslug.xlsx', 
    @provstr = 'Excel 12.0;IMEX=1;HDR=YES;';

INSERT INTO dbo.Dodatki (IdDodatku, Nazwa, CenaNetto, VAT, CenaBrutto, Opis)
SELECT 
    [Id_Dodatku],
    [Nazwa],
    [Cena_Netto],
    [VAT],
    [Cena_Brutto],
    [Opis]
FROM OPENQUERY(Excel_Dodatki, 'SELECT * FROM [Dodatki$]');

EXEC sp_dropserver 'Excel_Dodatki', 'droplogins';


-----EXEC sp_addlinkedserver 
    @server = 'Excel_KodyBledow', 
    @srvproduct = 'Excel', 
    @provider = 'Microsoft.ACE.OLEDB.12.0', 
    @datasrc = 'C:\ExcelData\Kody_Bledow.xlsx', 
    @provstr = 'Excel 12.0;IMEX=1;HDR=YES;';

INSERT INTO dbo.KodyBledow (KodBledu, Kategoria, OpisBledu, PoziomWaznosci)
SELECT 
    [Kod_Bledu],
    [Kategoria],
    [Opis_Bledu],
    [Poziom_Waznosci]
FROM OPENQUERY(Excel_KodyBledow, 'SELECT * FROM [S³ownik_Bledow$]');

EXEC sp_dropserver 'Excel_KodyBledow', 'droplogins';

----

EXEC sp_addlinkedserver 
    @server = 'Excel_KursySortownie', 
    @srvproduct = 'Excel', 
    @provider = 'Microsoft.ACE.OLEDB.12.0', 
    @datasrc = 'C:\ExcelData\Kursy_Sortownie.xlsx', 
    @provstr = 'Excel 12.0;IMEX=1;HDR=YES;';

INSERT INTO dbo.KursySortownie (KursID, Trasa, GodzinaWyjazdu, DniTygodnia, MaxPojemnosc)
SELECT 
    [ID_Kursu ],
    [Trasa],
    CAST([Godzina_Wyjazdu] AS TIME),
    [Dni_Tygodnia],
    [Limit_Paczek]
FROM OPENQUERY(Excel_KursySortownie, 'SELECT * FROM [Krusy_TIR$]');

EXEC sp_dropserver 'Excel_KursySortownie', 'droplogins';


----
EXEC sp_addlinkedserver 
    @server = 'Excel_LimityRozmiarow', 
    @srvproduct = 'Excel', 
    @provider = 'Microsoft.ACE.OLEDB.12.0', 
    @datasrc = 'C:\ExcelData\Limity_Rozmiarow.xlsx', 
    @provstr = 'Excel 12.0;IMEX=1;HDR=YES;';

INSERT INTO dbo.Gabaryty (Gabaryt, MaxDlugoscCM, MaxSzerokoscCM, MaxWysokoscCM, MaxObwodCM, MaxWagaKG)
SELECT 
    [Gabaryt],
    [Max_Dlugosc_CM],
    [Max_Szerokosc_CM],
    [Max_Wysokosc_CM],
    [Max_Obwod_CM],
    [Max_Waga_KG]
FROM OPENQUERY(Excel_LimityRozmiarow, 'SELECT * FROM [Gabaryty$]');

EXEC sp_dropserver 'Excel_LimityRozmiarow', 'droplogins';

----

EXEC sp_addlinkedserver 
    @server = 'Excel_ParametrySystemu', 
    @srvproduct = 'Excel', 
    @provider = 'Microsoft.ACE.OLEDB.12.0', 
    @datasrc = 'C:\ExcelData\Parametry_Systemu.xlsx', 
    @provstr = 'Excel 12.0;IMEX=1;HDR=YES;';

INSERT INTO dbo.ParametryOgolne (Parametr, Wartosc, Jednostka)
SELECT 
    [Parametr],
    [Wartosc],
    [jednostka]
FROM OPENQUERY(Excel_ParametrySystemu, 'SELECT * FROM [Parametry_Ogolne$]');

EXEC sp_dropserver 'Excel_ParametrySystemu', 'droplogins';

----

EXEC sp_addlinkedserver 
    @server = 'Excel_ParametryPowiadomien', 
    @srvproduct = 'Excel', 
    @provider = 'Microsoft.ACE.OLEDB.12.0', 
    @datasrc = 'C:\ExcelData\Parametry_Systemu.xlsx', 
    @provstr = 'Excel 12.0;IMEX=1;HDR=YES;';

INSERT INTO dbo.ParametryPowiadomien (Typ, Czas, Jednostka, Szablon)
SELECT 
    [Typ],
    [Czas],
    [Jednostka],
    [Szablon]
FROM OPENQUERY(Excel_ParametryPowiadomien, 'SELECT * FROM [Parametry_Powiadomien$]');

EXEC sp_dropserver 'Excel_ParametryPowiadomien', 'droplogins';
