# System Zarządzania Siecią Dostaw i Paczkomatów - DeliveryDB

## 📋 Opis projektu
Zaawansowany system rozproszonej bazy danych dla firmy kurierskiej obsługującej sieć paczkomatów. System umożliwia kompleksowe zarządzanie przesyłkami, paczkomatami, kurierami oraz monitorowanie całej infrastruktury logistycznej w czasie rzeczywistym.

## 🚀 Główne funkcjonalności
- **Nadawanie i śledzenie przesyłek** - pełny cykl życia przesyłki od nadania do doręczenia
- **Zarządzanie paczkomatami** - inteligentne przypisywanie skrytek, monitoring zajętości
- **System powiadomień** - automatyczne powiadomienia SMS/Email dla klientów
- **Obsługa zwrotów** - kompleksowy proces zwrotów z automatycznym zwalnianiem skrytek
- **Zarządzanie awariami** - system zgłaszania i śledzenia awarii infrastruktury
- **Raporty i analizy** - rozbudowane widoki i procedury raportowe

## 💻 Technologie
- **MS SQL Server 2019** - główna baza transakcyjna (OLTP)
- **Oracle 19c** - baza analityczna (OLAP)
- **Excel** - dane konfiguracyjne i słownikowe
- **PowerShell** - skrypty deploymentu i automatyzacji

## 📁 Struktura projektu

### SQL Server - Baza operacyjna
```
DeliveryDB/
├── Tabele podstawowe/
│   ├── Klienci                 # Dane klientów (osoby i firmy)
│   ├── Adresy                  # Adresy wszystkich obiektów
│   ├── Przesylki               # Rejestr przesyłek
│   ├── ObiektInfrastruktury    # Sortownie, paczkomaty, skrytki
│   ├── Kurierzy                # Dane kurierów
│   └── PracownicySortowni      # Pracownicy sortowni
├── Tabele operacyjne/
│   ├── OperacjeKurierskie      # Historia operacji kurierów
│   ├── OperacjeSortownicze     # Operacje w sortowniach
│   ├── Powiadomienia           # Historia powiadomień
│   ├── Zwroty                  # Obsługa zwrotów
│   └── AwarieInfrastruktury    # Rejestr awarii
└── Tabele słownikowe/
    ├── Gabaryty                # Rozmiary przesyłek
    ├── CennikPodstawowy        # Cennik usług
    ├── KodyBledow              # Słownik błędów
    └── ParametrySystemu        # Konfiguracja systemu
```

### Procedury składowane
- **sp_DodajKlienta** - rejestracja nowych klientów z walidacją
- **sp_NadajPrzesylke** - nadawanie przesyłek z automatycznym przypisaniem kuriera
- **sp_PrzypiszDoSkrytki** - inteligentne przypisywanie do skrytek
- **sp_ZarejestrujOperacjeSortownicza** - rejestracja operacji w sortowni
- **sp_WyslijPowiadomienie** - wysyłanie powiadomień do klientów
- **sp_ZarejestrujZwrot** - obsługa zwrotów
- **sp_ZglosAwarie** - zgłaszanie awarii infrastruktury
- **sp_RaportPrzesylekKuriera** - raporty dla kurierów
- **sp_StatystykiSortowni** - statystyki pracy sortowni

### Widoki systemowe
- **vw_StatusPrzesylek** - kompleksowy status wszystkich przesyłek
- **vw_MonitoringPaczkomatow** - monitoring zajętości i awarii
- **vw_ObciazenieKurierow** - analiza wydajności kurierów
- **vw_AktywneAwarie** - lista aktywnych awarii
- **vw_DashboardOperacyjny** - główny dashboard systemu
- **vw_EfektywnoscSystemu** - kluczowe wskaźniki KPI

### Oracle - Baza analityczna
- Statystyki wykorzystania infrastruktury
- Analizy trendów i sezonowości
- Prognozy obciążenia sieci
- Raporty finansowe i rozliczenia

### Excel - Dane konfiguracyjne
- `Ceny_uslug.xlsx` - cenniki i strefy taryfowe
- `Kody_Bledow.xlsx` - słownik błędów systemowych
- `Kursy_Sortownie.xlsx` - harmonogramy kursów
- `Limity_Rozmiarow.xlsx` - gabaryty przesyłek
- `Parametry_Systemu.xlsx` - parametry konfiguracyjne

## 🛠️ Instalacja

### Wymagania systemowe
1. MS SQL Server 2019 lub nowszy
2. Oracle 19c lub nowszy (opcjonalnie)
3. MS Excel 2016 lub nowszy
4. Min. 8GB RAM, 50GB przestrzeni dyskowej

### Kroki instalacji

1. **Utworzenie bazy danych**
   ```sql
   -- Wykonaj skrypt tworzący bazę i tabele
   sqlcmd -S localhost -i DeliveryDB_Tables.sql
   ```

2. **Instalacja procedur składowanych**
   ```sql
   -- Zainstaluj procedury
   sqlcmd -S localhost -d DeliveryDB -i DeliveryDB_Procedures.sql
   ```

3. **Utworzenie widoków i danych testowych**
   ```sql
   -- Utwórz widoki i załaduj dane demonstracyjne
   sqlcmd -S localhost -d DeliveryDB -i DeliveryDB_Views_Demo.sql
   ```

4. **Import danych z Excel** (opcjonalnie)
   ```sql
   -- Skonfiguruj linked server do Excel
   EXEC sp_addlinkedserver 
       @server = 'ExcelSource',
       @srvproduct = 'Excel',
       @provider = 'Microsoft.ACE.OLEDB.12.0',
       @datasrc = 'C:\DeliveryDB\Config\*.xlsx',
       @provstr = 'Excel 12.0;HDR=YES';
   ```

## 📊 Użytkowanie

### Podstawowe operacje

**1. Nadanie przesyłki:**
```sql
EXEC sp_NadajPrzesylke 
    @NadawcaID = 1,
    @OdbiorcaID = 2,
    @Gabaryt = 'A',
    @DroppointID = 7,
    @AdresNadaniaID = 11;
```

**2. Sprawdzenie statusu przesyłki:**
```sql
SELECT * FROM vw_StatusPrzesylek 
WHERE PrzesylkaID = 1;
```

**3. Przypisanie do skrytki:**
```sql
EXEC sp_PrzypiszDoSkrytki @PrzesylkaID = 1;
```

**4. Zgłoszenie awarii:**
```sql
EXEC sp_ZglosAwarie 
    @TypObiektu = 'DropPoint',
    @ObiektID = 7,
    @Opis = 'Nie działa ekran dotykowy',
    @Priorytet = 'Wysoki',
    @PracownikID = 1;
```

**5. Monitoring paczkomatów:**
```sql
SELECT * FROM vw_MonitoringPaczkomatow 
WHERE Miasto = 'Warszawa';
```

## 📈 Przykładowe scenariusze biznesowe

### Scenariusz 1: Pełny cykl przesyłki
1. Klient nadaje przesyłkę w punkcie nadania
2. System automatycznie przypisuje kuriera
3. Przesyłka trafia do sortowni
4. Po sortowaniu jest transportowana do sortowni docelowej
5. Kurier dostarcza do paczkomatu
6. System przypisuje odpowiednią skrytkę
7. Klient otrzymuje SMS z kodem odbioru
8. Po odbiorze skrytka jest automatycznie zwalniana

### Scenariusz 2: Obsługa awarii
1. Użytkownik zgłasza problem ze skrytką
2. System rejestruje awarię z priorytetem
3. Paczkomat jest dezaktywowany dla nowych przesyłek
4. Serwis otrzymuje zlecenie naprawy
5. Po naprawie paczkomat wraca do pełnej funkcjonalności

### Scenariusz 3: Proces zwrotu
1. Odbiorca zgłasza chęć zwrotu
2. System generuje etykietę zwrotną
3. Skrytka w paczkomacie jest zwalniana
4. Nadawca otrzymuje powiadomienie o zwrocie
5. Przesyłka wraca do nadawcy

## 🔧 Administracja

### Harmonogram zadań
- **Co 5 minut**: Sprawdzanie przekroczonych terminów odbioru
- **Co godzinę**: Aktualizacja statusów przesyłek
- **Codziennie 6:00**: Generowanie raportów dziennych
- **Co tydzień**: Optymalizacja indeksów i statystyk

### Monitoring wydajności
```sql
-- Sprawdzenie obciążenia systemu
SELECT * FROM vw_DashboardOperacyjny;

-- Analiza efektywności
SELECT * FROM vw_EfektywnoscSystemu;
```

### Backup i odzyskiwanie
```sql
-- Pełny backup
BACKUP DATABASE DeliveryDB 
TO DISK = 'C:\Backup\DeliveryDB_Full.bak'
WITH FORMAT, COMPRESSION;

-- Backup różnicowy (codzienny)
BACKUP DATABASE DeliveryDB 
TO DISK = 'C:\Backup\DeliveryDB_Diff.bak'
WITH DIFFERENTIAL, COMPRESSION;
```

## 📞 Wsparcie techniczne

### Najczęstsze problemy

**Problem: Brak wolnych skrytek**
```sql
-- Sprawdź dostępność
EXEC sp_SprawdzDostepnoscSkrytek @DroppointID = 7;
```

**Problem: Błąd przypisania kuriera**
```sql
-- Sprawdź dostępnych kurierów
SELECT * FROM vw_ObciazenieKurierow 
WHERE SortowniaID = 1;
```

## 🔐 Bezpieczeństwo
- Szyfrowanie danych wrażliwych (dane osobowe)
- Audyt wszystkich operacji krytycznych
- Role i uprawnienia według stanowisk
- Regularne przeglądy bezpieczeństwa

## 📝 Dokumentacja API
Pełna dokumentacja procedur składowanych i widoków dostępna w katalogu `/docs`

## 🚧 Rozwój systemu

### Planowane funkcjonalności
- [ ] Integracja z aplikacją mobilną
- [ ] System predykcji obciążenia paczkomatów
- [ ] Automatyczna optymalizacja tras kurierów
- [ ] Rozszerzenie o obsługę przesyłek międzynarodowych
- [ ] Dashboard real-time w Power BI

## 📄 Licencja
System wewnętrzny - wszystkie prawa zastrzeżone

## 👥 Zespół
- Architekt systemu: [Twoje imię]
- Developer SQL: [Twoje imię]
- Projekt realizowany w ramach kursu Rozproszone Bazy Danych

---
*Ostatnia aktualizacja: Styczeń 2025*