# System Zarządzania Siecią Dostaw i Paczkomatów - DeliveryDB

## Opis projektu
Zaawansowany system heterogenicznej rozproszonej bazy danych dla firmy kurierskiej obsługującej sieć paczkomatów. System integruje różne źródła danych (SQL Server, Oracle, Excel) oraz realizuje kompleksowe zadania logistyczne i analityczne.

---

## 1. Założenia projektowe

### 1.1 Wstęp
Projekt zakłada stworzenie funkcjonalnego systemu zarządzania przesyłkami i paczkomatami, integrującego heterogeniczne źródła danych oraz realizującego podstawowe zadania logistyczne i analityczne. Nie obejmuje on zaawansowanych zagadnień optymalizacyjnych, takich jak problem komiwojażera czy problem plecakowy.

### 1.2 Założenia systemowe
- Walidacja i kompletność danych (gabaryty, dane odbiorcy, wybór paczkomatu lub adresu).
- Obsługa klientów i adresów z unikalnym zapisem.
- Dobór sortowni według województwa i kuriera według rekomendacji lub lokalnego algorytmu.
- Weryfikacja dostępności paczkomatów i skrytek.
- Szacowanie czasu dostawy na podstawie tras i typu dostawy.
- Rejestracja historii statusów i tras przesyłki z powiadomieniami.
- Obsługa zgłoszeń awarii i błędów.
- Transakcyjność operacji z mechanizmami rollback.

### 1.3 Parametry czasowe systemu
- +4 godziny — czas obsługi w sortowni
- +4 godziny — czas dostawy do domu
- +2 godziny — czas dostawy do paczkomatu
- Godziny doręczeń: 8:00–20:00 z odpowiednią korektą
- Domyślny czas transportu między sortowniami: 18 godzin (jeśli brak danych w tabeli czasów przejazdu)

---

## 2. Architektura rozproszonej bazy danych

### 2.1 Komponenty systemu
- **SQL Server** — Serwer operacyjny (główny system transakcyjny OLTP)
- **Oracle Database** — Centrum analityczne (system raportowania i OLAP)
- **Źródła zewnętrzne** — pliki Excel z danymi słownikowymi i konfiguracyjnymi

---

## 3. Mechanizmy integracji

### 3.1 Zapytania AD HOC - OPENROWSET
- Pobieranie wyników analiz i rekomendacji z Oracle
- Synchronizacja parametrów konfiguracyjnych
- Automatyczny import danych z 5 plików Excel (cenniki, kody błędów, kursy sortowni, limity rozmiarów, parametry systemu)

### 3.2 Serwery połączone (Linked Servers)
- SQL Server → Oracle (linked server "ORACLE_ANALYTICS")
- SQL Server → Excel (Provider: Microsoft.ACE.OLEDB.12.0)
- Dostęp do funkcji analitycznych i danych słownikowych w czasie rzeczywistym

### 3.3 Transakcje rozproszone (MS DTC)
- Transakcje obejmujące SQL Server i Oracle
- Operacje: nadawanie przesyłek, aktualizacja statusów, operacje finansowe
- Mechanizmy rollback i recovery zapewniające spójność ACID

---

## 4. Replikacja migawkowa SQL Server → Oracle

### 4.1 Architektura replikacji
- Codzienna replikacja danych o 02:00
- Widoki źródłowe agregujące dane operacyjne do postaci analitycznej
- Dane replikowane z SQL Server do Oracle Database (centrum analityczne)

### 4.2 Widoki do replikacji
- V_STAT_KURIERZY_SNAPSHOT — statystyki wydajności kurierów
- V_STAT_SORTOWNIE_SNAPSHOT — efektywność sortowni
- V_STAT_PRZESYLKI_SNAPSHOT — analizy przesyłek
- V_STAT_DROPPOINTY_SNAPSHOT — wykorzystanie paczkomatów
- V_STAT_BLEDY_AWARIE_SNAPSHOT — agregacja błędów i awarii
- V_STAT_AGREGACJE_MIESIECZNE — miesięczne podsumowania

### 4.3 Partycjonowanie w Oracle
- Partycjonowanie według daty aktualizacji (DataAktualizacji)
- Automatyczne tworzenie partycji co miesiąc
- Optymalizacja zapytań analitycznych

### 4.4 Implementacja replikacji
- Realizacja replikacji z wykorzystaniem SSIS (SQL Server Integration Services)

---

## 5. Główne funkcjonalności systemu

- Zarządzanie przesyłkami (walidacja, dobór sortowni i kuriera, dostępność paczkomatów)
- Szacowanie czasu dostawy i monitorowanie statusów
- Obsługa awarii i zgłoszeń błędów
- Bezpieczeństwo transakcji i spójność danych
- Kompleksowa integracja heterogenicznych źródeł danych (SQL Server, Oracle, Excel)

---

## 6. Przykładowe scenariusze użycia (demo)

```sql
USE DeliveryDB
GO

-- Normalna dostawa do paczkomatu
EXEC sp_NadajPrzesylkeV2
    @NadawcaID = 1,
    @OdbiorcaEmail = 'test.gdansk@example.com',
    @OdbiorcaImie = 'Test',
    @OdbiorcaNazwisko = 'Gdański',
    @OdbiorcaTelefon = '700800900',
    @OdbiorcaUlica = 'Morska 10',
    @OdbiorcaKodPocztowy = '80-100',
    @OdbiorcaMiasto = 'Gdańsk',
    @OdbiorcaWojewodztwo = 'Pomorskie',
    @Gabaryt = 'B',
    @PaczkomatDocelowy = 'KRK01',
    @DostawaDoDomu = 0;

-- Dostawa do domu
EXEC sp_NadajPrzesylkeV2
    @NadawcaID = 1, 
    @OdbiorcaEmail = 'test.gdansk@example.com',
    @OdbiorcaImie = 'Test',
    @OdbiorcaNazwisko = 'Gdański',
    @OdbiorcaTelefon = '700800900',
    @OdbiorcaUlica = 'Morska 10',
    @OdbiorcaKodPocztowy = '80-100',
    @OdbiorcaMiasto = 'Gdańsk',
    @OdbiorcaWojewodztwo = 'Pomorskie',
    @Gabaryt = 'B',
    @PaczkomatDocelowy = NULL,
    @DostawaDoDomu = 1;

-- Dostawa do paczkomatu z mylącym adresem odbiorcy
EXEC sp_NadajPrzesylkeV2
    @NadawcaID = 1, 
    @OdbiorcaEmail = 'test.krakow@example.com',
    @OdbiorcaImie = 'Test',
    @OdbiorcaNazwisko = 'Krakowski',
    @OdbiorcaTelefon = '600700800',
    @OdbiorcaUlica = 'Testowa 1',
    @OdbiorcaKodPocztowy = '00-001',
    @OdbiorcaMiasto = 'Warszawa',
    @OdbiorcaWojewodztwo = 'Mazowieckie',
    @Gabaryt = 'A',
    @PaczkomatDocelowy = 'KRK01',
    @DostawaDoDomu = 0;

-- Symulacja cyklu życia przesyłki o ID=2
EXEC sp_SymulujCyklZyciaPrzesylkiV2 @PrzesylkaId = 2;

-- Pobranie szczegółów przesyłki i historii
SELECT * FROM vw_SzczegolyPrzesylki WHERE PrzesylkaID = 2;
SELECT * FROM vw_HistoriaPrzesylki WHERE PrzesylkaID = 2;

-- Historia statusów i kodów odbioru dla przesyłki 2
SELECT * FROM HistoriaStatusowPrzesylek WHERE PrzesylkaID = 2;
SELECT * FROM KodyOdbioru WHERE PrzesylkaID = 2;

-- Próba odbioru przesyłki z kodem odbioru
EXEC sp_OdbierzPrzesylkeZKodem @PrzesylkaId = 2, @KodOdbioru = 'MOUV81';
EXEC sp_OdbierzPrzesylkeZKodem @PrzesylkaId = 2, @KodOdbioru = 'GVAEXA';

-- Aktualizacja statusu przesyłki
EXEC sp_AktualizujStatusPrzesylki 
    @PrzesylkaID = 2,
    @NowyStatus = 'W paczkomacie',
    @Opis = 'paczka czeka w paczkomacie',
    @LokalizacjaID = 7;

-- Ponowna próba odbioru przesyłki
EXEC sp_OdbierzPrzesylkeZKodem @PrzesylkaId = 2, @KodOdbioru = 'GVAEXA';

-- Ponowne pobranie danych przesyłki i historii
SELECT * FROM vw_SzczegolyPrzesylki WHERE PrzesylkaID = 2;
SELECT * FROM HistoriaStatusowPrzesylek WHERE PrzesylkaID = 2;
SELECT * FROM Przesylki WHERE PrzesylkaID = 2;
SELECT * FROM KodyOdbioru WHERE PrzesylkaID = 2;

---
```
### Licencja  
## System wewnętrzny - wszystkie prawa zastrzeżone

### Zespół  
## Architekt systemu: Michał Urbaniak  
## Developer SQL: Jędrzej Małaczyński
