
-- 20/04/2021 - Create a encrypted backup from a DB

use master
go
sp_who2
GO
kill 53
GO

--Msg 6104, Level 16, State 1, Line 8
--Cannot use KILL to kill your own process.

-- WATCH OUT!!! Delete all content related to this script in C:\data



-- create a new database for this example
DROP DATABASE IF EXISTS PPD_encriptar
go
CREATE DATABASE PPD_encriptar;
GO
-- HINT : CREATE DATABASE IN PROGRAM FILES

USE PPD_encriptar;
GO
-- create a table inside the DB
DROP TABLE IF EXISTS PPD_encriptarTable
GO
CREATE TABLE PPD_encriptarTable (
    ID int IDENTITY(1,1000) PRIMARY KEY NOT NULL,
    value int
);
GO
-- insert some data but using a procedure
-- if procedure exists we alter the procedure
CREATE OR ALTER PROCEDURE InsertPPD_encriptarTable
AS
DECLARE @i int = 1
WHILE @i <100
    BEGIN
        INSERT PPD_encriptarTable (value) VALUES (@i)
        Set @i +=1
    END
GO

-- execute de procedure to perform the data insertion
EXECUTE InsertPPD_encriptarTable;
GO
SELECT * FROM PPD_encriptarTable;
GO
-- (99 rows affected)

-- ============= MASTER KEY ================
--- After create database, table procedure and fill the table.
USE MASTER;
GO
-- create master key and certificate in database master
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Abcd1234.';
GO

-- HINT : IF EXISTS 
-- Msg 15578, Level 16, State 1, Line 58
--There is already a master key in the database. Please drop it before performing this statement.
-- NO PROBLEM, we can use this.
-- We could do DROP MASTER KEY to remov it... (just in case)

-- ============= CERTIFICATE ================
DROP CERTIFICATE PPD_encriptarDBCert 
GO
--Msg 15151, Level 16, State 1, Line 69
--Cannot drop the certificate 'PPD_encriptarDBCert', because it does not exist or you do not have permission.

CREATE CERTIFICATE PPD_encriptarDBCert
    WITH SUBJECT = 'PPD_encriptarDB Backup Certificate';
GO

-- Export the backup certificate to a file
BACKUP CERTIFICATE PPD_encriptarDBCert 
TO FILE = 'C:\data\PPD_encriptarDBCert.cert' -- the certificate encrypted
WITH PRIVATE KEY (
			FILE = 'C:\data\PPD_encriptarDBCert.key', -- the key to decript the certificate
			ENCRYPTION BY PASSWORD = 'Abcd1234.')
GO

-- Perform the backup of the database with encryption using the certificate.
BACKUP DATABASE PPD_encriptar
TO DISK = 'C:\data\PPD_encriptar.bak' -- til here we have a normal backup
WITH ENCRYPTION (ALGORITHM = AES_256, SERVER CERTIFICATE = PPD_encriptarDBCert)
GO
-- RESULT
--Processed 384 pages for database 'PPD_encriptar', file 'PPD_encriptar' on file 1.
--Processed 6 pages for database 'PPD_encriptar', file 'PPD_encriptar_log' on file 1.
--BACKUP DATABASE successfully processed 390 pages in 0.075 seconds (40.618 MB/sec).


-- insert additional records
USE PPD_encriptar;
GO
EXECUTE InsertPPD_encriptarTable;
go

SELECT * FROM PPD_encriptarTable;
GO
-- (198 rows affected)


-- THIS EXAMPLE EXAMPLE WITHOUT USING SECOND SERVER

-- TAKE DATABASE PPD_encriptar offline
 
ALTER DATABASE PPD_encriptar SET OFFLINE WITH ROLLBACK IMMEDIATE
go

-- Failed to restart the current database. The current database is switched to master.

-- GUI IS OFF-LINE

-- delete .mdf data file from the hard drive
-- C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\PPD_encriptar.MDF
-- DATABASE OFFLINE ALLOWS DELETE
 

 -- DATABASE ONLINE AGAIN
 -- mejor desde GUI

ALTER DATABASE PPD_encriptar SET ONLINE WITH  ROLLBACK IMMEDIATE
go

--Msg 5120, Level 16, State 101, Line 127
--Unable to open the physical file "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\PPD_encriptar.mdf". Operating system error 2: "2(The system cannot find the file specified.)".
--Msg 5181, Level 16, State 5, Line 127
--Could not restart database "PPD_encriptar". Reverting to the previous status.
--Msg 5069, Level 16, State 1, Line 127
--ALTER DATABASE statement failed.


-- GUI PPD_encriptar RECOVERY PENDING (REFRESH the database list)

-- BUT LOOKING TO GUI IS ONLINE

USE master;
GO
-- attempt to take TailLogDB online
BACKUP LOG PPD_encriptar
TO DISK = 'C:\data\PPD_encriptarTailLogDB.log'
WITH CONTINUE_AFTER_ERROR,ENCRYPTION (ALGORITHM = AES_256, SERVER CERTIFICATE = PPD_encriptarDBCert)
GO


--Processed 14 pages for database 'PPD_encriptar', file 'PPD_encriptar_log' on file 1.
--BACKUP LOG successfully processed 14 pages in 0.007 seconds (15.555 MB/sec).

/*   NOT DONE FROM HERE */
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
WHERE database_name = 'PPD_encriptar'
ORDER BY b.backup_start_date  DESC;
 GO

--database_name	key_algorithm	encryptor_thumbprint	encryptor_type	media_set_id	is_encrypted	type	is_compressed	physical_device_name
--PPD_encriptar	aes_256	0x7C9B35C38289A83BF47DBDFE2101C6691B66A9D0	CERTIFICATE	1005	1	L	1	C:\data\PPD_encriptarTailLogDB.log
--PPD_encriptar	aes_256	0x7C9B35C38289A83BF47DBDFE2101C6691B66A9D0	CERTIFICATE	1004	1	D	1	C:\data\PPD_encriptar.bak
--PPD_encriptar	aes_256	0x2C262EDE0B2723896FE43B07FFC1050571F29DF0	CERTIFICATE	1003	1	L	1	C:\data\PPD_encriptarTailLogDB.log
--PPD_encriptar	aes_256	0x2C262EDE0B2723896FE43B07FFC1050571F29DF0	CERTIFICATE	1002	1	D	1	C:\data\PPD_encriptar.bak
 

/*   NOT DONE UNTIL HERE */ 
-- clean up the instance
DROP DATABASE PPD_encriptar;
GO

/*   NOT DONE FROM HERE */ 
-- Commands completed successfully.
-- REFRESH. NO DATABASE


DROP CERTIFICATE PPD_encriptarDBCert;
GO

-- Commands completed successfully.

DROP MASTER KEY;
GO

-- <Commands completed successfully.

--Use RESTORE FILELISTONLY to get the logical names of the data files in the backup. This is especially useful when you’re working with an unfamiliar backup file.
 
RESTORE FILELISTONLY FROM DISK='C:\data\PPD_encriptar.bak'
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


/*   NOT DONE UNTIL HERE */ 
USE master
GO
 -- RECREATE master key and certificate
DROP MASTER KEY
GO
--Msg 15580, Level 16, State 1, Line 226
--Cannot drop master key because certificate 'Cert_April_2021' is encrypted by it.
DROP CERTIFICATE PPD_encriptarDBCert
GO
DROP SYMMETRIC KEY SK_CreditCards_April_2021;
GO

DROP CERTIFICATE Cert_April_2021
GO

DROP CERTIFICATE DBBackupEncryptCert;
GO

DROP CERTIFICATE CertificateContainersDBcert;
GO
--Commands completed successfully.
DROP SYMMETRIC KEY PPD_encriptarDBCert
GO
--Msg 15151, Level 16, State 1, Line 233
--Cannot drop the symmetric key 'PPD_encriptarDBCert', because it does not exist or you do not have permission.

-- attempt again
DROP MASTER KEY
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Abcd1234.';
GO


-- restore the certificate
CREATE CERTIFICATE PPD_encriptarDBCert
FROM FILE = 'C:\data\PPD_encriptarDBCert.cert'
WITH PRIVATE KEY (FILE = 'C:\data\PPD_encriptarDBCert.key',
DECRYPTION BY PASSWORD = 'Abcd1234.');
GO

-- EN ALGUNOS CASOS
--Msg 15232, Level 16, State 1, Line 209
--A certificate with name 'PPD_encriptarDBCert' already exists or this certificate already has been added to the database.
-- LO BORRO
-- <Commands completed successfully.

--Use RESTORE WITH MOVE to move and/or rename database files to a new path.
 
RESTORE DATABASE PPD_encriptar 
FROM DISK = 'C:\data\PPD_encriptar.bak'
WITH NORECOVERY,
MOVE 'PPD_encriptar' TO 'C:\data\PPD_encriptar_Data.mdf', 
MOVE 'PPD_encriptar_Log' TO 'C:\data\PPD_encriptar_Log.ldf', 
REPLACE, STATS = 10;
GO


--10 percent processed.
--20 percent processed.
--30 percent processed.
--41 percent processed.
--51 percent processed.
--61 percent processed.
--71 percent processed.
--80 percent processed.
--90 percent processed.
--100 percent processed.
--Processed 384 pages for database 'PPD_encriptar', file 'PPD_encriptar' on file 1.
--Processed 6 pages for database 'PPD_encriptar', file 'PPD_encriptar_log' on file 1.
--RESTORE DATABASE successfully processed 390 pages in 0.047 seconds (64.816 MB/sec).

-- HINT PPD_encriptar RESTORING.. --in object explorer the DB appears as (Restoring...)
-- GUI PPD_encriptar (RESTORING)

-- attempt the restore log 
RESTORE LOG PPD_encriptar
FROM DISK = 'C:\data\PPD_encriptarTailLogDB.log';
GO


--Processed 0 pages for database 'PPD_encriptar', file 'PPD_encriptar' on file 1.
--Processed 14 pages for database 'PPD_encriptar', file 'PPD_encriptar_log' on file 1.
--RESTORE LOG successfully processed 14 pages in 0.018 seconds (6.049 MB/sec).

-- GUI PPD_encriptar ON LINE

--Data validation 
USE PPD_encriptar 
GO
SELECT * FROM PPD_encriptarTable;
GO

-- (198 rows affected)

-- clean up the instance

USE MASTER
GO
DROP DATABASE PPD_encriptar;
GO

-- GUI NO DATABASE PPD_encriptar

-- SOMETIMES
--Msg 3702, Level 16, State 3, Line 252
--Cannot drop database "PPD_encriptar" because it is currently in use.

SP_WHO2
GO
KILL 53
GO


DROP CERTIFICATE PPD_encriptarDBCert;
GO

-- Commands completed successfully.

DROP MASTER KEY;
GO

-- Commands completed successfully.
-- ====================================================
-- == RESTORE TEACHER'S DB SQL_encriptar ===
-- new DB exists in C:\data\external
USE MASTER;
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Abcd1234.';
GO
-- restore the certificate
CREATE CERTIFICATE PPD_encriptarDBCert
FROM FILE = 'C:\data\external\SQL_encriptarDBCert.cert'
WITH PRIVATE KEY (FILE = 'C:\data\external\SQL_encriptarDBCert.key',
DECRYPTION BY PASSWORD = 'Abcd1234.');
GO

--Use RESTORE WITH MOVE to move and/or rename database files to a new path.
 
RESTORE DATABASE SQL_encriptar 
FROM DISK = 'C:\data\external\SQL_encriptar.bak'
WITH NORECOVERY,
MOVE 'SQL_encriptar' TO 'C:\data\external\SQL_encriptar_Data.mdf', 
MOVE 'SQL_encriptar_Log' TO 'C:\data\external\SQL_encriptar_Log.ldf', 
REPLACE, STATS = 10;
GO

--11 percent processed.
--20 percent processed.
--31 percent processed.
--40 percent processed.
--51 percent processed.
--60 percent processed.
--71 percent processed.
--80 percent processed.
--91 percent processed.
--100 percent processed.
--Processed 352 pages for database 'SQL_encriptar', file 'SQL_encriptar' on file 1.
--Processed 6 pages for database 'SQL_encriptar', file 'SQL_encriptar_log' on file 1.
--RESTORE DATABASE successfully processed 358 pages in 0.062 seconds (45.103 MB/sec).

-- IN object explorer SQL_encriptar status seems as (Restoring...)

-- attempt the restore log 
RESTORE LOG SQL_encriptar
FROM DISK = 'C:\data\external\SQL_encriptarTailLogDB.log';
GO

--Processed 0 pages for database 'SQL_encriptar', file 'SQL_encriptar' on file 1.
--Processed 14 pages for database 'SQL_encriptar', file 'SQL_encriptar_log' on file 1.
--RESTORE LOG successfully processed 14 pages in 0.019 seconds (5.730 MB/sec).

--Data validation 
USE SQL_encriptar 
GO
SELECT * FROM SQL_encriptarTable;
GO

--(198 rows affected)

