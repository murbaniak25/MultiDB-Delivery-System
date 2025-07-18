USE DeliveryDB;
GO

-- =============================================
-- DANE TESTOWE - PODSTAWOWE
-- =============================================

-- Adresy
INSERT INTO Adresy (Ulica, KodPocztowy, Miasto, Wojewodztwo, Kraj)
VALUES 
-- Adresy sortowni
('Logistyczna 1', '00-001', 'Warszawa', 'Mazowieckie', 'Polska'),
('Magazynowa 15', '30-001', 'Kraków', 'Małopolskie', 'Polska'),
('Przemysłowa 25', '50-001', 'Wrocław', 'Dolnośląskie', 'Polska'),
('Portowa 10', '80-001', 'Gdańsk', 'Pomorskie', 'Polska'),
('Fabryczna 5', '90-001', 'Łódź', 'Łódzkie', 'Polska'),
-- Adresy paczkomatów
('Marszałkowska 100', '00-100', 'Warszawa', 'Mazowieckie', 'Polska'),
('Floriańska 20', '30-100', 'Kraków', 'Małopolskie', 'Polska'),
('Świdnicka 40', '50-100', 'Wrocław', 'Dolnośląskie', 'Polska'),
('Długa 50', '80-100', 'Gdańsk', 'Pomorskie', 'Polska'),
('Piotrkowska 100', '90-100', 'Łódź', 'Łódzkie', 'Polska'),
-- Adresy klientów
('Kwiatowa 10', '00-200', 'Warszawa', 'Mazowieckie', 'Polska'),
('Słoneczna 5', '30-200', 'Kraków', 'Małopolskie', 'Polska'),
('Lipowa 15', '50-200', 'Wrocław', 'Dolnośląskie', 'Polska'),
('Morska 8', '80-200', 'Gdańsk', 'Pomorskie', 'Polska'),
('Wschodnia 12', '90-200', 'Łódź', 'Łódzkie', 'Polska');

-- Obiekty infrastruktury - Sortownie
INSERT INTO ObiektInfrastruktury (TypObiektu, Nazwa, AdresID)
VALUES 
('Sortownia', 'Sortownia Centralna Warszawa', 1),
('Sortownia', 'Sortownia Regionalna Kraków', 2),
('Sortownia', 'Sortownia Regionalna Wrocław', 3),
('Sortownia', 'Sortownia Regionalna Gdańsk', 4),
('Sortownia', 'Sortownia Regionalna Łódź', 5);

-- Sortownie
INSERT INTO Sortownie (SortowniaID, Telefon, Email, GodzinyPracy, CzyAktywny)
VALUES 
(1, '22-123-45-67', 'warszawa@sortownia.pl', '24/7', 1),
(2, '12-345-67-89', 'krakow@sortownia.pl', '24/7', 1),
(3, '71-234-56-78', 'wroclaw@sortownia.pl', '24/7', 1),
(4, '58-345-67-89', 'gdansk@sortownia.pl', '24/7', 1),
(5, '42-234-56-78', 'lodz@sortownia.pl', '24/7', 1);

-- Województwa obsługiwane przez sortownie
INSERT INTO WojewodztwaSortowni (SortowniaID, Wojewodztwo)
VALUES 
(1, 'Mazowieckie'), (1, 'Podlaskie'), (1, 'Warmińsko-Mazurskie'),
(2, 'Małopolskie'), (2, 'Podkarpackie'), (2, 'Świętokrzyskie'),
(3, 'Dolnośląskie'), (3, 'Opolskie'), (3, 'Lubuskie'),
(4, 'Pomorskie'), (4, 'Zachodniopomorskie'), (4, 'Kujawsko-Pomorskie'),
(5, 'Łódzkie'), (5, 'Wielkopolskie'), (5, 'Lubelskie');

-- Pracownicy sortowni
INSERT INTO PracownicySortowni (SortowniaID, Imie, Nazwisko, Stanowisko, Email, Telefon, DataZatrudnienia)
VALUES 
(1, 'Jan', 'Kowalski', 'Manager', 'j.kowalski@firma.pl', '500-100-100', '2020-01-01'),
(1, 'Anna', 'Nowak', 'Sortowacz', 'a.nowak@firma.pl', '500-100-101', '2021-03-15'),
(2, 'Piotr', 'Wiśniewski', 'Manager', 'p.wisniewski@firma.pl', '500-200-100', '2020-02-01'),
(2, 'Maria', 'Dąbrowska', 'Sortowacz', 'm.dabrowska@firma.pl', '500-200-101', '2021-06-01'),
(3, 'Tomasz', 'Lewandowski', 'Manager', 't.lewandowski@firma.pl', '500-300-100', '2020-03-01'),
(3, 'Katarzyna', 'Wójcik', 'Sortowacz', 'k.wojcik@firma.pl', '500-300-101', '2021-09-01'),
(4, 'Michał', 'Kamiński', 'Manager', 'm.kaminski@firma.pl', '500-400-100', '2020-04-01'),
(4, 'Joanna', 'Kowalczyk', 'Sortowacz', 'j.kowalczyk@firma.pl', '500-400-101', '2021-12-01'),
(5, 'Robert', 'Zieliński', 'Manager', 'r.zielinski@firma.pl', '500-500-100', '2020-05-01'),
(5, 'Agnieszka', 'Szymańska', 'Sortowacz', 'a.szymanska@firma.pl', '500-500-101', '2022-01-01');

-- Aktualizacja managerów w sortowniach
UPDATE Sortownie SET ManagerID = 1 WHERE SortowniaID = 1;
UPDATE Sortownie SET ManagerID = 3 WHERE SortowniaID = 2;
UPDATE Sortownie SET ManagerID = 5 WHERE SortowniaID = 3;
UPDATE Sortownie SET ManagerID = 7 WHERE SortowniaID = 4;
UPDATE Sortownie SET ManagerID = 9 WHERE SortowniaID = 5;

-- Kurierzy
INSERT INTO Kurierzy (SortowniaID, Imie, Nazwisko, DataZatrudnienia, Telefon, Email, Wojewodztwo)
VALUES 
(1, 'Adam', 'Małysz', '2021-01-15', '600-100-001', 'a.malysz@kurier.pl', 'Mazowieckie'),
(1, 'Kamil', 'Stoch', '2021-02-20', '600-100-002', 'k.stoch@kurier.pl', 'Mazowieckie'),
(2, 'Justyna', 'Kowalczyk', '2021-03-10', '600-200-001', 'j.kowalczyk@kurier.pl', 'Małopolskie'),
(2, 'Mariusz', 'Pudzianowski', '2021-04-05', '600-200-002', 'm.pudzianowski@kurier.pl', 'Małopolskie'),
(3, 'Robert', 'Lewandowski', '2021-05-15', '600-300-001', 'r.lewandowski@kurier.pl', 'Dolnośląskie'),
(3, 'Wojciech', 'Szczęsny', '2021-06-20', '600-300-002', 'w.szczesny@kurier.pl', 'Dolnośląskie'),
(4, 'Marcin', 'Gortat', '2021-07-10', '600-400-001', 'm.gortat@kurier.pl', 'Pomorskie'),
(4, 'Bartosz', 'Kurek', '2021-08-05', '600-400-002', 'b.kurek@kurier.pl', 'Pomorskie'),
(5, 'Zbigniew', 'Boniek', '2021-09-15', '600-500-001', 'z.boniek@kurier.pl', 'Łódzkie'),
(5, 'Grzegorz', 'Lato', '2021-10-20', '600-500-002', 'g.lato@kurier.pl', 'Łódzkie');

-- Obiekty infrastruktury - Paczkomaty
INSERT INTO ObiektInfrastruktury (TypObiektu, Nazwa, AdresID)
VALUES 
('DropPoint', 'WAW01 - Marszałkowska', 6),
('DropPoint', 'KRK01 - Floriańska', 7),
('DropPoint', 'WRO01 - Świdnicka', 8),
('DropPoint', 'GDA01 - Długa', 9),
('DropPoint', 'LOD01 - Piotrkowska', 10);

-- Droppointy (Paczkomaty)
INSERT INTO Droppointy (DroppointID, Typ, CzyAktywny, GodzinyPracy, SortowniaID)
VALUES 
(6, 'Paczkomat', 1, '24/7', 1),
(7, 'Paczkomat', 1, '24/7', 2),
(8, 'Paczkomat', 1, '24/7', 3),
(9, 'Paczkomat', 1, '24/7', 4),
(10, 'Paczkomat', 1, '24/7', 5);

INSERT INTO Klienci (TypKlienta, Imie, Nazwisko, Email, Telefon, AdresID)
VALUES 
('Osoba', 'Marek', 'Testowy', 'marek.testowy@email.com', '700-100-100', 11),
('Osoba', 'Ewa', 'Przykładowa', 'ewa.przykladowa@email.com', '700-100-101', 12),
('Osoba', 'Tomasz', 'Demonstracyjny', 'tomasz.demo@email.com', '700-100-102', 13),
('Osoba', 'Karolina', 'Pokazowa', 'karolina.pokaz@email.com', '700-100-103', 14),
('Osoba', 'Paweł', 'Prezentacyjny', 'pawel.prezent@email.com', '700-100-104', 15);

INSERT INTO Klienci (TypKlienta, NazwaFirmy, Nip, Email, Telefon, AdresID)
VALUES 
('Firma', 'TechCorp Sp. z o.o.', '1234567890', 'biuro@techcorp.pl', '22-500-600-700', 11),
('Firma', 'HandelMax SA', '0987654321', 'kontakt@handelmax.pl', '12-600-700-800', 12);



DECLARE @i INT = 11;
DECLARE @paczkomatID INT = 6;
DECLARE @skrytkaNum INT;

WHILE @paczkomatID <= 10
BEGIN
    SET @skrytkaNum = 1;
    -- Dodaj skrytki A (10 sztuk)
    WHILE @skrytkaNum <= 10
    BEGIN
        INSERT INTO ObiektInfrastruktury (TypObiektu, Nazwa, AdresID)
        VALUES ('Skrytka', 'Skrytka A-' + CAST(@skrytkaNum AS VARCHAR), 
                (SELECT AdresID FROM ObiektInfrastruktury WHERE ObiektID = @paczkomatID));
        
        INSERT INTO SkrytkiPaczkomatow (SkrytkaID, DroppointID, Gabaryt, Status)
        VALUES (@i, @paczkomatID, 'A', 'Wolna');
        
        SET @i = @i + 1;
        SET @skrytkaNum = @skrytkaNum + 1;
    END
    
    -- Dodaj skrytki B (8 sztuk)
    SET @skrytkaNum = 1;
    WHILE @skrytkaNum <= 8
    BEGIN
        INSERT INTO ObiektInfrastruktury (TypObiektu, Nazwa, AdresID)
        VALUES ('Skrytka', 'Skrytka B-' + CAST(@skrytkaNum AS VARCHAR), 
                (SELECT AdresID FROM ObiektInfrastruktury WHERE ObiektID = @paczkomatID));
        
        INSERT INTO SkrytkiPaczkomatow (SkrytkaID, DroppointID, Gabaryt, Status)
        VALUES (@i, @paczkomatID, 'B', 'Wolna');
        
        SET @i = @i + 1;
        SET @skrytkaNum = @skrytkaNum + 1;
    END
    
    -- Dodaj skrytki C (5 sztuk)
    SET @skrytkaNum = 1;
    WHILE @skrytkaNum <= 5
    BEGIN
        INSERT INTO ObiektInfrastruktury (TypObiektu, Nazwa, AdresID)
        VALUES ('Skrytka', 'Skrytka C-' + CAST(@skrytkaNum AS VARCHAR), 
                (SELECT AdresID FROM ObiektInfrastruktury WHERE ObiektID = @paczkomatID));
        
        INSERT INTO SkrytkiPaczkomatow (SkrytkaID, DroppointID, Gabaryt, Status)
        VALUES (@i, @paczkomatID, 'C', 'Wolna');
        
        SET @i = @i + 1;
        SET @skrytkaNum = @skrytkaNum + 1;
    END
    
    SET @paczkomatID = @paczkomatID + 1;
END;

-- Szablony notyfikacji
INSERT INTO SzablonyNotyfikacji (TypZdarzenia, TematEmaila, TrescHTML, TrescTekst)
VALUES
('NADANIE', 'Twoja przesyłka #{ID} została nadana', 
 '<h2>Przesyłka nadana!</h2><p>Twoja przesyłka o numerze <strong>#{ID}</strong> została przekazana kurierowi.</p><p>Przewidywany czas dostawy: <strong>{CZAS_DOSTAWY}</strong></p>',
 'Twoja przesyłka #{ID} została nadana. Przewidywany czas dostawy: {CZAS_DOSTAWY}'),
 
('W_SORTOWNI', 'Przesyłka #{ID} w sortowni {SORTOWNIA}',
 '<h2>Przesyłka w sortowni</h2><p>Twoja przesyłka dotarła do sortowni <strong>{SORTOWNIA}</strong>.</p>',
 'Twoja przesyłka dotarła do sortowni {SORTOWNIA}'),
 
('W_DOSTAWIE', 'Przesyłka #{ID} jest w drodze do Ciebie',
 '<h2>Przesyłka w dostawie!</h2><p>Kurier dostarczy Twoją przesyłkę dzisiaj.</p>',
 'Kurier dostarczy Twoją przesyłkę dzisiaj'),
 
('W_PACZKOMACIE', 'Odbierz przesyłkę #{ID} z paczkomatu',
 '<h2>Przesyłka czeka na odbiór!</h2><p>Twoja przesyłka znajduje się w paczkomacie <strong>{PACZKOMAT}</strong>.</p><p>Kod odbioru: <strong>{KOD}</strong></p>',
 'Przesyłka czeka w paczkomacie {PACZKOMAT}. Kod odbioru: {KOD}'),
 
('AWARIA', 'Opóźnienie w dostawie przesyłki #{ID}',
 '<h2>Informacja o opóźnieniu</h2><p>Z powodu awarii technicznej Twoja przesyłka może być dostarczona z opóźnieniem.</p>',
 'Z powodu awarii technicznej Twoja przesyłka może być dostarczona z opóźnieniem');