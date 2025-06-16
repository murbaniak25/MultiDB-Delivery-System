EXEC sp_addlinkedserver
    @server = N'OracleLinked',
    @srvproduct = N'Oracle',
    @provider = N'OraOLEDB.Oracle',
    @datasrc = N'DeliveryDB'; --Data source moze sie roznic, mozesz je sprawdzic w tnsnames.ora

EXEC sp_addlinkedsrvlogin
    @rmtsrvname = N'OracleLinked',
    @useself = N'false',
    @locallogin = NULL,
    @rmtuser = N'ADMIN',
    @rmtpassword = N'admin123';

SELECT * FROM OPENQUERY(OracleLinked, 'SELECT * FROM TEST_TABLE');