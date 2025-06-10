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
    Rozmiar VARCHAR(10) NOT NULL,
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
    FOREIGN KEY (SortowniaID) REFERENCES Sortownie(SortowniaID)
);

CREATE TABLE Przesylki (
    PrzesylkaID INT IDENTITY(1,1) PRIMARY KEY,
    NadawcaID INT NOT NULL,
    DroppointID INT NOT NULL,
    SortowniaID INT NOT NULL,
    KurierID INT NOT NULL,
    AdresNadaniaID INT NOT NULL,
    SkrytkaID INT,
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
    Status VARCHAR(20),
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
    Status VARCHAR(20) DEFAULT 'Otwarta',
    Priorytet VARCHAR(10) DEFAULT 'Sredni',
    PracownikID INT NOT NULL,
    FOREIGN KEY (ObiektID) REFERENCES ObiektInfrastruktury(ObiektID),
    FOREIGN KEY (PracownikID) REFERENCES PracownicySortowni(PracownikID)
);
CREATE TABLE OdbiorcyPrzesy³ki(
	PrzesylkaID INT NOT NULL,
	OdbiorcaID INT NOT NULL,
	CzyGlowny BIT Default 0,
	Kolejnosc INT DEFAULT 1,
	PRIMARY KEY (PrzesylkaID, OdbiorcaID),
	FOREIGN KEY (PrzesylkaID) REFERENCES Przesylki(PrzesylkaID),
	FOREIGN KEY (OdbiorcaID) REFERENCES Klienci(KlientID)
);

ALTER TABLE ObiektInfrastruktury 
ADD FOREIGN KEY (AdresID) REFERENCES Adresy(AdresID);

ALTER TABLE Sortownie 
ADD FOREIGN KEY (ManagerID) REFERENCES PracownicySortowni(PracownikID);

ALTER TABLE Kurierzy 
ADD FOREIGN KEY (PrzesylkaID) REFERENCES Przesylki(PrzesylkaID);

CREATE INDEX IX_Przesylki_NadawcaID ON Przesylki(NadawcaID);
CREATE INDEX IX_Przesylki_SortowniaID ON Przesylki(SortowniaID);
CREATE INDEX IX_AwarieInfrastruktury_ObiektID ON AwarieInfrastruktury(ObiektID);
CREATE INDEX IX_AwarieInfrastruktury_Status ON AwarieInfrastruktury(Status);
CREATE INDEX IX_Klienci_Email ON Klienci(Email);
CREATE INDEX IX_Klienci_Telefon ON Klienci(Telefon);