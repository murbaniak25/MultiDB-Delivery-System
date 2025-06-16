USE DeliveryDB
GO

sp_configure

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Database Mail XPs', 1;
RECONFIGURE;

SELECT SERVERPROPERTY('Edition');