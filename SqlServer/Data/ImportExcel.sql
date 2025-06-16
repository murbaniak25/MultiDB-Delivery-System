USE DeliveryDB
GO

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
FROM OPENROWSET(
    'Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\ExcelData\Ceny_uslug.xlsx;HDR=YES;IMEX=1',
    'SELECT * FROM [Cennik_Podst$]'
);

INSERT INTO dbo.Dodatki (IdDodatku, Nazwa, CenaNetto, VAT, CenaBrutto, Opis)
SELECT
    [Id_Dodatku],
    [Nazwa],
    [Cena_Netto],
    [VAT],
    [Cena_Brutto],
    [Opis]
FROM OPENROWSET(
    'Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\ExcelData\Ceny_uslug.xlsx;HDR=YES;IMEX=1',
    'SELECT * FROM [Dodatki$]'
);

INSERT INTO dbo.KodyBledow (KodBledu, Kategoria, OpisBledu, PoziomWaznosci)
SELECT
    [Kod_Bledu],
    [Kategoria],
    [Opis_Bledu],
    [Poziom_Waznosci]
FROM OPENROWSET(
    'Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\ExcelData\Kody_Bledow.xlsx;HDR=YES;IMEX=1',
    'SELECT * FROM [S³ownik_Bledow$]'
);

INSERT INTO dbo.KursySortownie (KursID, Trasa, GodzinaWyjazdu, DniTygodnia, MaxPojemnosc)
SELECT
    [ID_Kursu ],
    [Trasa],
    CAST([Godzina_Wyjazdu] AS TIME),
    [Dni_Tygodnia],
    [Limit_Paczek]
FROM OPENROWSET(
    'Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\ExcelData\Kursy_Sortownie.xlsx;HDR=YES;IMEX=1',
    'SELECT * FROM [Krusy_TIR$]'
);

INSERT INTO dbo.Gabaryty (Gabaryt, MaxDlugoscCM, MaxSzerokoscCM, MaxWysokoscCM, MaxObwodCM, MaxWagaKG)
SELECT
    [Gabaryt],
    [Max_Dlugosc_CM],
    [Max_Szerokosc_CM],
    [Max_Wysokosc_CM],
    [Max_Obwod_CM],
    [Max_Waga_KG]
FROM OPENROWSET(
    'Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\ExcelData\Limity_Rozmiarow.xlsx;HDR=YES;IMEX=1',
    'SELECT * FROM [Gabaryty$]'
);

INSERT INTO dbo.ParametryOgolne (Parametr, Wartosc, Jednostka)
SELECT
    [Parametr],
    [Wartosc],
    [jednostka]
FROM OPENROWSET(
    'Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\ExcelData\Parametry_Systemu.xlsx;HDR=YES;IMEX=1',
    'SELECT * FROM [Parametry_Ogolne$]'
);

INSERT INTO dbo.ParametryPowiadomien (Typ, Czas, Jednostka, Szablon)
SELECT
    [Typ],
    [Czas],
    [Jednostka],
    [Szablon]
FROM OPENROWSET(
    'Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\ExcelData\Parametry_Systemu.xlsx;HDR=YES;IMEX=1',
    'SELECT * FROM [Parametry_Powiadomien$]'
);

INSERT INTO dbo.CzasyPrzejazdow (Trasa, DystansKM, CzasPrzejazdu, KosztPaliwa)
SELECT
    [Trasa],
    CAST(REPLACE([Dystans], ' km', '') AS INT),
    [Czas],
    CAST(REPLACE([Koszt_Paliwa], ' zl', '') AS DECIMAL(10,2))
FROM OPENROWSET(
    'Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\ExcelData\Kursy_Sortownie.xlsx;HDR=YES;IMEX=1',
    'SELECT * FROM [Czas_Przejazdu$]'
);

INSERT INTO dbo.DopasowanieSkrytek (Gabaryt, PasujaceSkrytki, Alternatywa)
SELECT
    [Gabaryt],
    [Pasujace_Skrytki],
    [Alternatywa]
FROM OPENROWSET(
    'Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\ExcelData\Limity_Rozmiarow.xlsx;HDR=YES;IMEX=1',
    'SELECT * FROM [Dopasowanie$]'
);
