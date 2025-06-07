# System Zarządzania Siecią Dostaw i Paczkomatów - RBD

## Opis projektu
System rozproszonej bazy danych dla firmy kurierskiej obsługującej sieć paczkomatów. Projekt wykorzystuje heterogeniczne środowisko składające się z MS SQL Server, Oracle i Excel.

## Technologie
- **MS SQL Server 2019** - baza transakcyjna (OLTP)
- **Oracle 19c** - baza analityczna (OLAP)
- **Excel** - dane konfiguracyjne
- **PowerShell** - skrypty deploymentu

## Struktura projektu

### SQL Server
Główna baza operacyjna zawierająca:
- Dane klientów i adresów
- Rejestr przesyłek
- Stan paczkomatów i skrytek
- Kurierów i pracowników
- Historie statusów

### Oracle
Baza analityczna z:
- Statystykami wykorzystania
- Analizami wydajności
- Prognozami obciążenia
- Raportami finansowymi

### Excel
Pliki konfiguracyjne:
- Cenniki usług
- Strefy dostaw
- Parametry systemu
- Harmonogramy

## Instalacja

### Wymagania
1. MS SQL Server 2019 lub nowszy
2. Oracle 19c lub nowszy
3. MS Excel 2016 lub nowszy
4. Sterowniki:
   - Oracle Client dla SQL Server
   - Microsoft ACE OLEDB 12.0

### Kroki instalacji

1. **SQL Server**
   ```bash
   cd 02_SQL_Server
   sqlcmd -S localhost -i 01_Create_Database.sql
   sqlcmd -S localhost -d RBD_Dostawa -i 02_Create_Tables.sql
   # ... pozostałe skrypty
   ```

2. **Oracle**
   ```bash
   cd 03_Oracle
   sqlplus sys as sysdba @01_Create_User.sql
   sqlplus rbd_user/haslo @02_Create_Tables.sql
   # ... pozostałe skrypty
   ```

3. **Konfiguracja Linked Servers**
   ```bash
   sqlcmd -S localhost -d RBD_Dostawa -i 08_Create_Linked_Servers.sql
   ```

4. **Import danych z Excel**
   - Umieść pliki Excel w katalogu C:\RBD_Config\
   - Uruchom skrypty integracyjne

## Użytkowanie

### Podstawowe operacje

**Nadanie przesyłki:**
```sql
EXEC sp_NadajPrzesylke 
    @NadawcaID = 1001,
    @OdbiorcaID = 2001,
    @TypPrzesylki = 'STANDARD',
    @Gabaryt = 'A',
    @PaczkomatOdbioru = 'WAW01M'
```

**Sprawdzenie statusu:**
```sql
SELECT * FROM vw_StatusPrzesylki WHERE NumerPrzesylki = '630099990000123456789012'
```

**Raport dzienny:**
```sql
EXEC sp_RaportDzienny @Data = '2025-01-20'
```


## Harmonogram zadań

- **Co 5 minut**: Aktualizacja statusów przesyłek
- **Co godzinę**: Synchronizacja z Oracle
- **Codziennie 2:00**: Generowanie raportów
- **Co tydzień**: Optymalizacja indeksów


## Licencja

Projekt wewnętrzny - poufne
