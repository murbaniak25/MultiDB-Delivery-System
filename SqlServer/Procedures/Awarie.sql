USE DeliveryDB;
GO

CREATE OR ALTER PROCEDURE sp_ZglosAwarie
    @TypObiektu VARCHAR(20),
    @ObiektID INT,
    @Opis VARCHAR(500),
    @Priorytet VARCHAR(10),
    @PracownikID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Walidacja priorytetu
        IF @Priorytet NOT IN ('Niski', 'Sredni', 'Wysoki', 'Krytyczny')
        BEGIN
            SET @Priorytet = 'Sredni';
        END
        
        -- Walidacja typu obiektu
        IF @TypObiektu NOT IN ('Sortownia', 'DropPoint', 'Skrytka')
        BEGIN
            RAISERROR('Nieprawidłowy typ obiektu', 16, 1);
            RETURN;
        END
        
        INSERT INTO AwarieInfrastruktury (TypObiektu, ObiektID, Opis, Priorytet, PracownikID)
        VALUES (@TypObiektu, @ObiektID, @Opis, @Priorytet, @PracownikID);
        
        DECLARE @AwariaID INT = SCOPE_IDENTITY();
        
        -- Jeśli to krytyczna awaria droppointa, dezaktywuj go
        IF @Priorytet = 'Krytyczny' AND @TypObiektu = 'DropPoint'
        BEGIN
            UPDATE Droppointy SET CzyAktywny = 0 WHERE DroppointID = @ObiektID;
        END
        
        SELECT @AwariaID AS NowaAwariaID;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_ZglosBlad
    @KodBledu VARCHAR(10),
    @OpisZgloszenia VARCHAR(500),
    @ZrodloZgloszenia VARCHAR(20),
    @PracownikID INT = NULL,
    @KurierID INT = NULL,
    @KlientID INT = NULL,
    @ObiektID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM KodyBledow WHERE KodBledu = @KodBledu)
        BEGIN
            RAISERROR('Nieznany kod błędu', 16, 1);
            RETURN;
        END
        
        IF @ZrodloZgloszenia NOT IN ('Kurier', 'Pracownik', 'Uzytkownik')
        BEGIN
            RAISERROR('Nieprawidłowe źródło zgłoszenia', 16, 1);
            RETURN;
        END
        
        INSERT INTO ZgloszeniaBledow (
            KodBledu, OpisZgloszenia, ZrodloZgloszenia, 
            PracownikID, KurierID, KlientID, ObiektID
        )
        VALUES (
            @KodBledu, @OpisZgloszenia, @ZrodloZgloszenia,
            @PracownikID, @KurierID, @KlientID, @ObiektID
        );
        
        SELECT SCOPE_IDENTITY() AS ZgloszenieID;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO


CREATE OR ALTER PROCEDURE sp_AktualizujStatusAwarii
    @AwariaID INT,
    @NowyStatus VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @NowyStatus NOT IN ('Otwarta', 'W trakcie', 'Naprawiona', 'Anulowana')
        BEGIN
            RAISERROR('Nieprawidłowy status awarii', 16, 1);
            RETURN;
        END
        
        UPDATE AwarieInfrastruktury 
        SET Status = @NowyStatus 
        WHERE AwariaID = @AwariaID;
        
        IF @NowyStatus = 'Naprawiona'
        BEGIN
            DECLARE @TypObiektu VARCHAR(20), @ObiektID INT;
            
            SELECT @TypObiektu = TypObiektu, @ObiektID = ObiektID
            FROM AwarieInfrastruktury
            WHERE AwariaID = @AwariaID;
            
            IF @TypObiektu = 'DropPoint'
            BEGIN
                UPDATE Droppointy SET CzyAktywny = 1 WHERE DroppointID = @ObiektID;
            END
        END
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO