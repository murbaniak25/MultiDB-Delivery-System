USE DeliveryDB
GO

sp_configure

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Database Mail XPs', 1;
RECONFIGURE;

EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
EXEC sp_MSSet_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1;
EXEC sp_MSSet_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1;


EXEC sp_addlinkedserver 
    @server = 'ORACLE_ANALYTICS',
    @srvproduct = 'Oracle',
    @provider = 'OraOLEDB.Oracle',
    @datasrc = 'localhost:1521/Delivery';

-- Dodaj login
EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = 'ORACLE_ANALYTICS',
    @useself = 'false',
    @locallogin = NULL,
    @rmtuser = 'admin',  
    @rmtpassword = 'admin123';

SELECT *
FROM OPENQUERY(ORACLE_ANALYTICS, 'SELECT * FROM D_KURIER_PROFIL');