USE DeliveryDB;
GO

CREATE OR ALTER PROCEDURE sp_DodajKlienta
    @TypKlienta VARCHAR(20),
    @Imie VARCHAR(50) = NULL,
    @Nazwisko VARCHAR(100) = NULL,
    @NazwaFirmy VARCHAR(100) = NULL,
    @Nip VARCHAR(15) = NULL,
    @Email VARCHAR(100),
    @Telefon VARCHAR(20),
    @Ulica VARCHAR(100),
    @KodPocztowy VARCHAR(10),
    @Miasto VARCHAR(50),
    @Wojewodztwo VARCHAR(50),
    @Kraj VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF @TypKlienta NOT IN ('Osoba', 'Firma')
        BEGIN
            RAISERROR('Nieprawidłowy typ klienta. Dozwolone: Osoba, Firma', 16, 1);
            RETURN;
        END
        
        IF @TypKlienta = 'Osoba' AND (@Imie IS NULL OR @Nazwisko IS NULL)
        BEGIN
            RAISERROR('Dla typu Osoba wymagane są Imię i Nazwisko', 16, 1);
            RETURN;
        END
        
        IF @TypKlienta = 'Firma' AND (@NazwaFirmy IS NULL OR @Nip IS NULL)
        BEGIN
            RAISERROR('Dla typu Firma wymagane są NazwaFirmy i NIP', 16, 1);
            RETURN;
        END
        
        DECLARE @AdresID INT;
        
        INSERT INTO Adresy (Ulica, KodPocztowy, Miasto, Wojewodztwo, Kraj)
        VALUES (@Ulica, @KodPocztowy, @Miasto, @Wojewodztwo, @Kraj);
        
        SET @AdresID = SCOPE_IDENTITY();
        
        INSERT INTO Klienci (TypKlienta, Imie, Nazwisko, NazwaFirmy, Nip, Email, Telefon, AdresID)
        VALUES (@TypKlienta, @Imie, @Nazwisko, @NazwaFirmy, @Nip, @Email, @Telefon, @AdresID);
        
        DECLARE @KlientID INT = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
        
        SELECT @KlientID AS NowyKlientID;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO