CREATE DATABASE DeliveryDB
COLLATE Polish_CI_AS;

GO
--TABELE
USE DeliveryDB;
GO

CREATE TABLE ObiektInfrastruktury (
    ObiektID INT IDENTITY(1,1) PRIMARY KEY,
    TypObiektu VARCHAR(20) NOT NULL CHECK (TypObiektu IN ('Sortownia', 'DropPoint', 'Skrytka')),
    Nazwa VARCHAR(100),
    AdresID INT NOT NULL
);

CREATE TABLE Adresy (
    AdresID INT IDENTITY(1,1) PRIMARY KEY,
    Ulica VARCHAR(100) NOT NULL,
    KodPocztowy VARCHAR(10) NOT NULL,
    Miasto VARCHAR(50) NOT NULL,
    Wojewodztwo VARCHAR(50) NOT NULL,
    Kraj VARCHAR(50) NOT NULL
);

CREATE TABLE Klienci (
    KlientID INT IDENTITY(1,1) PRIMARY KEY,
    TypKlienta VARCHAR(20) NOT NULL,
    Imie VARCHAR(50),
    Nazwisko VARCHAR(100),
    NazwaFirmy VARCHAR(100),
    Nip VARCHAR(15),
    Email VARCHAR(100) NOT NULL,
    Telefon VARCHAR(20) NOT NULL,
    AdresID INT NOT NULL,
    FOREIGN KEY (AdresID) REFERENCES Adresy(AdresID)
);

CREATE TABLE Sortownie (
    SortowniaID INT PRIMARY KEY,
    Telefon VARCHAR(20),
    Email VARCHAR(100),
    GodzinyPracy VARCHAR(50),
    CzyAktywny BIT DEFAULT 1,
    ManagerID INT,
    FOREIGN KEY (SortowniaID) REFERENCES ObiektInfrastruktury(ObiektID)
);

CREATE TABLE Droppointy (
    DroppointID INT PRIMARY KEY,
    Typ VARCHAR(20) CHECK (Typ IN ('Paczkomat', 'PunktPartnerski')) NOT NULL,
    CzyAktywny BIT DEFAULT 1,
    GodzinyPracy VARCHAR(50),
    WlascicielID INT,
    SortowniaID INT NOT NULL,
    FOREIGN KEY (DroppointID) REFERENCES ObiektInfrastruktury(ObiektID),
    FOREIGN KEY (SortowniaID) REFERENCES Sortownie(SortowniaID)
);

CREATE TABLE SkrytkiPaczkomatow (
    SkrytkaID INT PRIMARY KEY,
    DroppointID INT NOT NULL,
    Gabaryt CHAR(1) NOT NULL, --Rodzaj gabarytu (A/B/C) do u�ycia w procedurach w po��czeniu z tabelami s�ownikowymi
    Status VARCHAR(20) DEFAULT 'Wolna',
    FOREIGN KEY (SkrytkaID) REFERENCES ObiektInfrastruktury(ObiektID),
    FOREIGN KEY (DroppointID) REFERENCES Droppointy(DroppointID)
);

CREATE TABLE PracownicySortowni (
    PracownikID INT IDENTITY(1,1) PRIMARY KEY,
    SortowniaID INT NOT NULL,
    Imie VARCHAR(50),
    Nazwisko VARCHAR(100),
    Stanowisko VARCHAR(50),
    Email VARCHAR(100),
    Telefon VARCHAR(20),
    DataZatrudnienia DATE,
    FOREIGN KEY (SortowniaID) REFERENCES Sortownie(SortowniaID)
);

CREATE TABLE Kurierzy (
    KurierID INT IDENTITY(1,1) PRIMARY KEY,
    PrzesylkaID INT,
    SortowniaID INT NOT NULL,
    Imie VARCHAR(50),
    Nazwisko VARCHAR(100),
    DataZatrudnienia DATE,
    Telefon VARCHAR(20),
    Email VARCHAR(100),
	Wojewodztwo VARCHAR(50),
    FOREIGN KEY (SortowniaID) REFERENCES Sortownie(SortowniaID)
);



CREATE TABLE Przesylki (
    PrzesylkaID INT IDENTITY(1,1) PRIMARY KEY,
    NadawcaID INT NOT NULL,
    DroppointID INT,
    SortowniaID INT NOT NULL,
    KurierID INT NOT NULL,
    AdresNadaniaID INT NOT NULL,
    SkrytkaID INT,
	Gabaryt CHAR(1) NOT NULL, --Rodzaj gabarytu (A/B/C) do u�ycia w procedurach w po��czeniu z tabelami s�ownikowymi
    FOREIGN KEY (NadawcaID) REFERENCES Klienci(KlientID),
    FOREIGN KEY (DroppointID) REFERENCES Droppointy(DroppointID),
    FOREIGN KEY (SortowniaID) REFERENCES Sortownie(SortowniaID),
    FOREIGN KEY (KurierID) REFERENCES Kurierzy(KurierID),
    FOREIGN KEY (AdresNadaniaID) REFERENCES Adresy(AdresID),
    FOREIGN KEY (SkrytkaID) REFERENCES SkrytkiPaczkomatow(SkrytkaID)
);

CREATE TABLE Zwroty (
    ZwrotID INT IDENTITY(1,1) PRIMARY KEY,
    KlientID INT NOT NULL,
    PrzesylkaID INT NOT NULL,
    Data DATE NOT NULL,
    Przyczyna VARCHAR(200) NOT NULL,
    Status VARCHAR(20) CHECK (Status IN ('Nowy', 'W trakcie', 'Zako�czony', 'Anulowany')),
    FOREIGN KEY (KlientID) REFERENCES Klienci(KlientID),
    FOREIGN KEY (PrzesylkaID) REFERENCES Przesylki(PrzesylkaID)
);

CREATE TABLE OperacjeKurierskie (
    OperacjaID INT IDENTITY(1,1) PRIMARY KEY,
    PrzesylkaID INT NOT NULL,
    KurierID INT NOT NULL,
    CzasRozpoczecia DATETIME2 NOT NULL,
    CzasZakonczenia DATETIME2 NOT NULL,
    Status VARCHAR(20),
    Uwagi VARCHAR(500),
    FOREIGN KEY (PrzesylkaID) REFERENCES Przesylki(PrzesylkaID),
    FOREIGN KEY (KurierID) REFERENCES Kurierzy(KurierID)
);

CREATE TABLE OperacjeSortownicze (
    OperacjaID INT IDENTITY(1,1) PRIMARY KEY,
    PrzesylkaID INT NOT NULL,
    PracownikID INT NOT NULL,
    TypOperacji VARCHAR(50) NOT NULL,
    CzasRozpoczecia DATETIME2 NOT NULL,
    CzasZakonczenia DATETIME2 NOT NULL,
    Status VARCHAR(20),
    Uwagi VARCHAR(500),
    FOREIGN KEY (PrzesylkaID) REFERENCES Przesylki(PrzesylkaID),
    FOREIGN KEY (PracownikID) REFERENCES PracownicySortowni(PracownikID)
);

CREATE TABLE Powiadomienia (
    PowiadomieniID INT IDENTITY(1,1) PRIMARY KEY,
    KlientID INT,
    PrzesylkaID INT,
    TypPowiadomienia VARCHAR(50),
    Tresc VARCHAR(500),
    Kanal VARCHAR(20) CHECK (Kanal IN ('Email', 'SMS', 'Push')),
    DataWyslania DATETIME2,
    FOREIGN KEY (KlientID) REFERENCES Klienci(KlientID),
    FOREIGN KEY (PrzesylkaID) REFERENCES Przesylki(PrzesylkaID)
);

CREATE TABLE AwarieInfrastruktury (
    AwariaID INT IDENTITY(1,1) PRIMARY KEY,
    TypObiektu VARCHAR(20) NOT NULL,
    ObiektID INT NOT NULL,
    Data DATETIME2 DEFAULT GETDATE(),
    Opis VARCHAR(500),
    Status VARCHAR(20) DEFAULT 'Otwarta' CHECK (Status IN ('Otwarta', 'W trakcie', 'Naprawiona', 'Anulowana')),
    Priorytet VARCHAR(10) DEFAULT 'Sredni',
    PracownikID INT NOT NULL,
    FOREIGN KEY (ObiektID) REFERENCES ObiektInfrastruktury(ObiektID),
    FOREIGN KEY (PracownikID) REFERENCES PracownicySortowni(PracownikID)
);
CREATE TABLE OdbiorcyPrzesylki(
	PrzesylkaID INT NOT NULL,
	OdbiorcaID INT NOT NULL,
	CzyGlowny BIT Default 0,
	Kolejnosc INT DEFAULT 1,
	PRIMARY KEY (PrzesylkaID, OdbiorcaID),
	FOREIGN KEY (PrzesylkaID) REFERENCES Przesylki(PrzesylkaID),
	FOREIGN KEY (OdbiorcaID) REFERENCES Klienci(KlientID)
);

CREATE TABLE WojewodztwaSortowni (
    SortowniaID INT NOT NULL,
    Wojewodztwo VARCHAR(50) NOT NULL,
    PRIMARY KEY (SortowniaID, Wojewodztwo),
    FOREIGN KEY (SortowniaID) REFERENCES Sortownie(SortowniaID)
);

--To tabela, kt�ra pozwala na po��czenie ca�ej logiki trasy przesy�ki
CREATE TABLE TrasaPrzesylki (
    PrzesylkaID INT PRIMARY KEY,
    SortowniaStartowaID INT NOT NULL,
    SortowniaDocelowaID INT NOT NULL,
    DataWyjazdu DATETIME2,
    DataPrzyjazdu DATETIME2,
    FOREIGN KEY (PrzesylkaID) REFERENCES Przesylki(PrzesylkaID),
    FOREIGN KEY (SortowniaStartowaID) REFERENCES Sortownie(SortowniaID),
    FOREIGN KEY (SortowniaDocelowaID) REFERENCES Sortownie(SortowniaID)
);
--tutaj tabela na bledy, jest kolumna potwierdzone zeby weryfikowac glownie zgloszenia przez uzytkownikow
CREATE TABLE ZgloszeniaBledow (
    ZgloszenieID INT IDENTITY(1,1) PRIMARY KEY,
    KodBledu VARCHAR(10) NOT NULL,
    OpisZgloszenia VARCHAR(500),
    DataZgloszenia DATETIME2 DEFAULT GETDATE(),
    ZrodloZgloszenia VARCHAR(20) CHECK (ZrodloZgloszenia IN ('Kurier', 'Pracownik', 'Uzytkownik')) NOT NULL,
    PracownikID INT NULL,
    KurierID INT NULL,
    KlientID INT NULL,
    ObiektID INT,
    Potwierdzone BIT DEFAULT 0,
    FOREIGN KEY (PracownikID) REFERENCES PracownicySortowni(PracownikID),
    FOREIGN KEY (KurierID) REFERENCES Kurierzy(KurierID),
    FOREIGN KEY (KlientID) REFERENCES Klienci(KlientID),
    FOREIGN KEY (ObiektID) REFERENCES ObiektInfrastruktury(ObiektID)
);

ALTER TABLE ObiektInfrastruktury 
ADD FOREIGN KEY (AdresID) REFERENCES Adresy(AdresID);

ALTER TABLE Sortownie 
ADD FOREIGN KEY (ManagerID) REFERENCES PracownicySortowni(PracownikID);

ALTER TABLE Kurierzy 
ADD FOREIGN KEY (PrzesylkaID) REFERENCES Przesylki(PrzesylkaID);

--INDEKSY moga sie przydac do szybszego filtrowania
CREATE INDEX IX_ObiektInfrastruktury_AdresID ON ObiektInfrastruktury(AdresID);
CREATE INDEX IX_Klienci_AdresID ON Klienci(AdresID);
CREATE INDEX IX_Sortownie_ManagerID ON Sortownie(ManagerID);
CREATE INDEX IX_Droppointy_SortowniaID ON Droppointy(SortowniaID);
CREATE INDEX IX_Droppointy_WlascicielID ON Droppointy(WlascicielID);
CREATE INDEX IX_SkrytkiPaczkomatow_DroppointID ON SkrytkiPaczkomatow(DroppointID);
CREATE INDEX IX_PracownicySortowni_SortowniaID ON PracownicySortowni(SortowniaID);
CREATE INDEX IX_Kurierzy_SortowniaID ON Kurierzy(SortowniaID);
CREATE INDEX IX_Kurierzy_PrzesylkaID ON Kurierzy(PrzesylkaID);
CREATE INDEX IX_Przesylki_DroppointID ON Przesylki(DroppointID);
CREATE INDEX IX_Przesylki_KurierID ON Przesylki(KurierID);
CREATE INDEX IX_Przesylki_AdresNadaniaID ON Przesylki(AdresNadaniaID);
CREATE INDEX IX_Przesylki_SkrytkaID ON Przesylki(SkrytkaID);
CREATE INDEX IX_Zwroty_KlientID ON Zwroty(KlientID);
CREATE INDEX IX_Zwroty_PrzesylkaID ON Zwroty(PrzesylkaID);
CREATE INDEX IX_OperacjeKurierskie_PrzesylkaID ON OperacjeKurierskie(PrzesylkaID);
CREATE INDEX IX_OperacjeKurierskie_KurierID ON OperacjeKurierskie(KurierID);
CREATE INDEX IX_OperacjeSortownicze_PrzesylkaID ON OperacjeSortownicze(PrzesylkaID);
CREATE INDEX IX_OperacjeSortownicze_PracownikID ON OperacjeSortownicze(PracownikID);
CREATE INDEX IX_Powiadomienia_KlientID ON Powiadomienia(KlientID);
CREATE INDEX IX_Powiadomienia_PrzesylkaID ON Powiadomienia(PrzesylkaID);
CREATE INDEX IX_AwarieInfrastruktury_PracownikID ON AwarieInfrastruktury(PracownikID);
CREATE INDEX IX_ZgloszeniaBledow_PracownikID ON ZgloszeniaBledow(PracownikID);
CREATE INDEX IX_ZgloszeniaBledow_KurierID ON ZgloszeniaBledow(KurierID);
CREATE INDEX IX_ZgloszeniaBledow_KlientID ON ZgloszeniaBledow(KlientID);
CREATE INDEX IX_ZgloszeniaBledow_ObiektID ON ZgloszeniaBledow(ObiektID);
CREATE INDEX IX_OdbiorcyPrzesylki_OdbiorcaID ON OdbiorcyPrzesylki(OdbiorcaID);
CREATE INDEX IX_WojewodztwaSortowni_Wojewodztwo ON WojewodztwaSortowni(Wojewodztwo);
CREATE INDEX IX_TrasaPrzesylki_SortowniaStartowaID ON TrasaPrzesylki(SortowniaStartowaID);
CREATE INDEX IX_TrasaPrzesylki_SortowniaDocelowaID ON TrasaPrzesylki(SortowniaDocelowaID);

--tabele s�ownikowe

--CENY US�UG
CREATE TABLE CennikPodstawowy (
    ID_Cennika INT PRIMARY KEY,
    TypUslugi VARCHAR(50),
    Gabaryt CHAR(1),
    Strefa VARCHAR(20),
    CenaNetto DECIMAL(10,2),
    StawkaVAT DECIMAL(4,2),
    CenaBrutto DECIMAL(10,2),
    DataOd DATE,
    DataDo DATE,
    Aktywny BIT
);

CREATE TABLE Dodatki (
    IdDodatku INT PRIMARY KEY,
    Nazwa VARCHAR(100),
    CenaNetto DECIMAL(10,2),
    VAT DECIMAL(4,2),
    CenaBrutto DECIMAL(10,2),
    Opis VARCHAR(255)
);

--LIMITY ROZMIAR�W

CREATE TABLE Gabaryty (
    Gabaryt CHAR(1) PRIMARY KEY,
    MaxDlugoscCM INT,
    MaxSzerokoscCM INT,
    MaxWysokoscCM INT,
    MaxObwodCM INT,
    MaxWagaKG DECIMAL(5,2)
);

CREATE TABLE DopasowanieSkrytek (
    Gabaryt CHAR(1) PRIMARY KEY,
    PasujaceSkrytki VARCHAR(50),
    Alternatywa VARCHAR(100)
);

--PARAMETRY SYSTEMU
CREATE TABLE ParametryOgolne (
    Parametr VARCHAR(100) PRIMARY KEY,
    Wartosc DECIMAL(10,2),
    Jednostka VARCHAR(20)
);

CREATE TABLE ParametryPowiadomien (
    Typ VARCHAR(100) PRIMARY KEY,
    Czas INT,
    Jednostka VARCHAR(10),
    Szablon VARCHAR(500)
);

--KODY B��D�W
CREATE TABLE KodyBledow (
    KodBledu VARCHAR(10) PRIMARY KEY,
    Kategoria VARCHAR(50),
    OpisBledu VARCHAR(200),
    PoziomWaznosci VARCHAR(20) CHECK (PoziomWaznosci IN ('NISKI', 'SREDNI', 'WYSOKI', 'KRYTYCZNY'))
);

--KURSY SORTOWNI
CREATE TABLE KursySortownie (
    KursID INT PRIMARY KEY,
    Trasa VARCHAR(20),
    GodzinaWyjazdu TIME,
    DniTygodnia VARCHAR(50),
    MaxPojemnosc INT
);

--TRASY LOGISTYCZNE
CREATE TABLE CzasyPrzejazdow (
    Trasa VARCHAR(20) PRIMARY KEY,
    DystansKM INT,
    CzasPrzejazdu VARCHAR(20),
    KosztPaliwa DECIMAL(10,2)
);

CREATE TABLE SzablonyNotyfikacji (
    SzablonID INT IDENTITY(1,1) PRIMARY KEY,
    TypZdarzenia VARCHAR(50) NOT NULL,
    TematEmaila VARCHAR(200),
    TrescHTML VARCHAR(MAX),
    TrescTekst VARCHAR(1000),
    CzyAktywny BIT DEFAULT 1,
    DataUtworzenia DATETIME2 DEFAULT GETDATE()
);

-- Tabela kolejki notyfikacji (dla symulacji wysyłki)
CREATE TABLE KolejkaNotyfikacji (
    KolejkaID INT IDENTITY(1,1) PRIMARY KEY,
    AdresEmail VARCHAR(100),
    Temat VARCHAR(200),
    TrescHTML VARCHAR(MAX),
    TrescTekst VARCHAR(1000),
    TypZdarzenia VARCHAR(50),
    StatusWysylki VARCHAR(20) DEFAULT 'OCZEKUJE',
    DataUtworzenia DATETIME2 DEFAULT GETDATE(),
    DataWyslania DATETIME2,
    ProbaWysylki INT DEFAULT 0,
    Bledy VARCHAR(500)
);

-- Tabela historii statusów przesyłek
CREATE TABLE HistoriaStatusowPrzesylek (
    HistoriaID INT IDENTITY(1,1) PRIMARY KEY,
    PrzesylkaID INT NOT NULL,
    Status VARCHAR(50) NOT NULL,
    Opis VARCHAR(500),
    LokalizacjaID INT,
    DataZmiany DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (PrzesylkaID) REFERENCES Przesylki(PrzesylkaID)
);

ALTER TABLE Przesylki ALTER COLUMN DroppointID INT NULL;