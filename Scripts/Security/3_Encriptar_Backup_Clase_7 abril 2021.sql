
-- https://www.SQL_encriptar.com/understanding-database-backup-encryption-sql-server/

use master
go
sp_who2
GO
kill 53
GO

--Msg 6104, Level 16, State 1, Line 8
--Cannot use KILL to kill your own process.

-- BORRAR TODO CONTENIDO CARPETA TEMP



-- create a new database for this example
DROP DATABASE IF EXISTS SQL_encriptar
go
CREATE DATABASE SQL_encriptar;
GO
-- HINT : CREATE DATABASE IN PROGRAM FILES

USE SQL_encriptar;
GO
-- insert some data
DROP TABLE IF EXISTS SQL_encriptarTable
GO
CREATE TABLE SQL_encriptarTable (
    ID int IDENTITY(1,1000) PRIMARY KEY NOT NULL,
    value int
);
GO
CREATE OR ALTER PROCEDURE InsertSQL_encriptarTable
AS
DECLARE @i int = 1
WHILE @i <100
    BEGIN
        INSERT SQL_encriptarTable (value) VALUES (@i)
        Set @i +=1
    END
GO
EXECUTE InsertSQL_encriptarTable;
GO
SELECT * FROM SQL_encriptarTable;
GO
-- (99 rows affected)


USE MASTER;
GO
-- create master key and certificate in database master
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Abcd1234.';
GO

-- HINT : IF EXISTS 
-- Msg 15578, Level 16, State 1, Line 54
--There is already a master key in the database. Please drop it before performing this statement.
-- NO PROBLEM

DROP CERTIFICATE SQL_encriptarDBCert
GO
CREATE CERTIFICATE SQL_encriptarDBCert
    WITH SUBJECT = 'SQL_encriptarDB Backup Certificate';
GO

-- export the backup certificate to a file
BACKUP CERTIFICATE SQL_encriptarDBCert 
TO FILE = 'c:\temp\SQL_encriptarDBCert.cert'
WITH PRIVATE KEY (
			FILE = 'c:\temp\SQL_encriptarDBCert.key',
			ENCRYPTION BY PASSWORD = 'Abcd1234.')
GO

-- backup the database with encryption
BACKUP DATABASE SQL_encriptar
TO DISK = 'c:\temp\SQL_encriptar.bak'
WITH ENCRYPTION (ALGORITHM = AES_256, SERVER CERTIFICATE = SQL_encriptarDBCert)
GO

-- insert additional records
USE SQL_encriptar;
GO
EXECUTE InsertSQL_encriptarTable;
go

SELECT * FROM SQL_encriptarTable;
GO

-- (198 rows affected)


-- OUR EXAMPLE WITHOUT USING SECOND SERVER

-- TAKE DATABASE SQL_encriptar offline
 
ALTER DATABASE SQL_encriptar SET OFFLINE WITH  ROLLBACK IMMEDIATE
go

-- Failed to restart the current database. The current database is switched to master.

-- GUI IS OFF-LINE

-- delete .mdf data file from the hard drive
-- C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\SQL_encriptar.MDF
-- DATABASE OFFLINE ALLOWS DELETE
 

 -- DATABASE ONLINE AGAIN
 -- mejor desde GUI

ALTER DATABASE SQL_encriptar SET ONLINE WITH  ROLLBACK IMMEDIATE
go

--Msg 5120, Level 16, State 101, Line 113
--Unable to open the physical file "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\SQL_encriptar.mdf". Operating system error 2: "2(The system cannot find the file specified.)".
--Msg 5181, Level 16, State 5, Line 113
--Could not restart database "SQL_encriptar". Reverting to the previous status.
--Msg 5069, Level 16, State 1, Line 113
--ALTER DATABASE statement failed.

--GUI SQL_encriptar RECOVERY PENDING

-- BUT LOOKING TO GUI IS ONLINE

USE master;
GO
-- attempt to take TailLogDB online
BACKUP LOG SQL_encriptar
TO DISK = 'c:\temp\SQL_encriptarTailLogDB.log'
WITH CONTINUE_AFTER_ERROR,ENCRYPTION (ALGORITHM = AES_256, SERVER CERTIFICATE = SQL_encriptarDBCert)
go


--Processed 14 pages for database 'SQL_encriptar', file 'SQL_encriptar_log' on file 1.
--BACKUP LOG successfully processed 14 pages in 0.047 seconds (2.316 MB/sec).



--Check for the backup
 
SELECT 
 b.database_name,
    key_algorithm,
    encryptor_thumbprint,
    encryptor_type,
	b.media_set_id,
    is_encrypted, 
	type,
    is_compressed,
	bf.physical_device_name
	 FROM msdb.dbo.backupset b
INNER JOIN msdb.dbo.backupmediaset m ON b.media_set_id = m.media_set_id
INNER JOIN msdb.dbo.backupmediafamily bf on bf.media_set_id=b.media_set_id
WHERE database_name = 'SQL_encriptar'
ORDER BY b.backup_start_date  DESC;

 GO

--database_name	key_algorithm	encryptor_thumbprint	encryptor_type	media_set_id	is_encrypted	type	is_compressed	physical_device_name
--SQL_encriptar	aes_256	0x7C9B35C38289A83BF47DBDFE2101C6691B66A9D0	CERTIFICATE	1005	1	L	1	c:\temp\SQL_encriptarTailLogDB.log
--SQL_encriptar	aes_256	0x7C9B35C38289A83BF47DBDFE2101C6691B66A9D0	CERTIFICATE	1004	1	D	1	c:\temp\SQL_encriptar.bak
--SQL_encriptar	aes_256	0x2C262EDE0B2723896FE43B07FFC1050571F29DF0	CERTIFICATE	1003	1	L	1	c:\temp\SQL_encriptarTailLogDB.log
--SQL_encriptar	aes_256	0x2C262EDE0B2723896FE43B07FFC1050571F29DF0	CERTIFICATE	1002	1	D	1	c:\temp\SQL_encriptar.bak
 
 
 -- clean up the instance
 
DROP DATABASE SQL_encriptar;
GO

-- Commands completed successfully.
-- REFRESH. NO DATABASE


DROP CERTIFICATE SQL_encriptarDBCert;
GO

-- Commands completed successfully.

DROP MASTER KEY;
GO

-- <Commands completed successfully.

--Use RESTORE FILELISTONLY to get the logical names of the data files in the backup. This is especially useful when you’re working with an unfamiliar backup file.
 
RESTORE FILELISTONLY FROM DISK='C:\TEMP\SQL_encriptar.bak'
 GO

-- Msg 33111, Level 16, State 3, Line 116
--Cannot find server certificate with thumbprint '0x2C262EDE0B2723896FE43B07FFC1050571F29DF0'.
--Msg 3013, Level 16, State 1, Line 116
--RESTORE FILELIST is terminating abnormally.

-- SECOND SERVER

-- HINT : DAR PERMISO A LA CARPETA TEMPORAL 
-- (NTFS) SEGURIDAD USERS CONTROL TOTAL
-- SINI NO PUEDE ACCEDER AL CERTIFICADO

-- https://dba.stackexchange.com/questions/149776/restoring-encrypted-database-on-another-server-using-backup-encryption

-- https://dba.stackexchange.com/questions/211777/issue-restoring-certificate-to-sql-server-when-different-service-account-used

USE master
GO
 -- RECREATE master key and certificate
DROP MASTER KEY
GO
DROP CERTIFICATE SQL_encriptarDBCert
GO
DROP SYMMETRIC KEY SQL_encriptarDBCert
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Abcd1234.';
GO


-- restore the certificate
CREATE CERTIFICATE SQL_encriptarDBCert
FROM FILE = 'C:\TEMPORAL\SQL_encriptarDBCert.cert'
WITH PRIVATE KEY (FILE = 'C:\TEMPORAL\SQL_encriptarDBCert.key',
DECRYPTION BY PASSWORD = 'Abcd1234.');
GO

-- EN ALGUNOS CASOS
--Msg 15232, Level 16, State 1, Line 209
--A certificate with name 'SQL_encriptarDBCert' already exists or this certificate already has been added to the database.
-- LO BORRO
-- <Commands completed successfully.

--Use RESTORE WITH MOVE to move and/or rename database files to a new path.
 
RESTORE DATABASE SQL_encriptar 
FROM DISK = 'c:\temporal\SQL_encriptar.bak'
WITH NORECOVERY,
MOVE 'SQL_encriptar' TO 'c:\temporal\SQL_encriptar_Data.mdf', 
MOVE 'SQL_encriptar_Log' TO 'c:\temporal\SQL_encriptar_Log.ldf', 
REPLACE, STATS = 10;
GO


--91 percent processed.
--100 percent processed.
--Processed 352 pages for database 'SQL_encriptar', file 'SQL_encriptar' on file 1.
--Processed 6 pages for database 'SQL_encriptar', file 'SQL_encriptar_log' on file 1.
--RESTORE DATABASE successfully processed 358 pages in 0.083 seconds (33.691 MB/sec).

-- HINT SQL_encriptar RESTORING
-- GUI SQL_ENCRIPTAR (RESTORING)

-- attempt the restore log 
RESTORE LOG SQL_encriptar
FROM DISK = 'c:\temporal\SQL_encriptarTailLogDB.log';
GO


--Processed 0 pages for database 'SQL_encriptar', file 'SQL_encriptar' on file 1.
--Processed 14 pages for database 'SQL_encriptar', file 'SQL_encriptar_log' on file 1.
--RESTORE LOG successfully processed 14 pages in 0.007 seconds (15.555 MB/sec).

-- HINT SQL_encriptar RESTORING
-- GUI SQL_ENCRIPTAR ON LINE

--Data validation 
USE SQL_encriptar 
GO
SELECT * FROM SQL_encriptarTable;
GO

-- (198 rows affected)

-- clean up the instance

USE MASTER
GO
DROP DATABASE SQL_encriptar;
GO

-- GUI NO DATABASE SQL_encriptar

-- SOMETIMES
--Msg 3702, Level 16, State 3, Line 252
--Cannot drop database "SQL_encriptar" because it is currently in use.

SP_WHO2
GO
KILL 53
GO


DROP CERTIFICATE SQL_encriptarDBCert;
GO

-- Commands completed successfully.

DROP MASTER KEY;
GO

-- Commands completed successfully.
