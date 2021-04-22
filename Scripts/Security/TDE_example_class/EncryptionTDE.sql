-- TRANSPARENT DATA ENCRYPTION (TDE)

-- AT REST
-- mdf, ndf, ldf

--Configuring a SQL Server database for TDE is a straight-forward process. It consists of:

--Creating the database master key in the master database.
--Creating a certificate encrypted by that key.
--Backing up the certificate and the certificate's private key. While this isn't required to encrypt the database, you want to do this immediately.
--Creating a database encryption key in the database that's encrypted by the certificate.
--Altering the database to turn encryption on.

USE [master];
GO 

-- Create the database master key
-- to encrypt the certificate
CREATE MASTER KEY
  ENCRYPTION BY PASSWORD = 'abcd1234.';
GO 

-- Create the certificate we're going to use for TDE
CREATE CERTIFICATE TDECert
  WITH SUBJECT = 'TDE Cert for Test';
GO 
-- VER EN SSMS EL CERTIFICADO    -BD MASTER -SECURITY -CERTIFICATES


-- CERTIFICATES T-SQL

SELECT TOP 1 * 
FROM sys.certificates 
ORDER BY name DESC
GO

--name	certificate_id	principal_id	pvt_key_encryption_type	pvt_key_encryption_type_desc	is_active_for_begin_dialog	issuer_name	cert_serial_number	sid	string_sid	subject	expiry_date	start_date	thumbprint	attested_by	pvt_key_last_backup_date	key_length
--TDECert	277	1	MK	ENCRYPTED_BY_MASTER_KEY	1	TDE Cert for Test	37 c5 aa 01 a2 ce 59 9d 44 7e 34 0e 1f 09 34 77	0x010600000000000901000000BF05FDBA4584C56ACAEC9AE38E0FF4EED74E7F83	S-1-9-1-3137144255-1791329349-3818581194-4008972174-2206158551	TDE Cert for Test	2022-04-21 14:59:51.000	2021-04-21 14:59:51.000	0xBF05FDBA4584C56ACAEC9AE38E0FF4EED74E7F83	NULL	NULL	2048


-- Back up the certificate and its private key
-- Remember the password!
BACKUP CERTIFICATE TDECert
  TO FILE = 'C:\CERTIFICADOS\TDECert.cer'
  WITH PRIVATE KEY ( 
    FILE = 'C:\CERTIFICADOS\TDECert_key.pvk',
 ENCRYPTION BY PASSWORD = 'Abcd1234.'
  );
GO
-- Look at Folder C:\CERTIFICADOS


DROP DATABASE IF EXISTS RecoveryWithTDE
GO
-- Create our test database
CREATE DATABASE [RecoveryWithTDE];
GO 

-- Create the DEK (DATABASE ENCRYPTION KEY)so we can turn on encryption
USE [RecoveryWithTDE];
GO 

CREATE DATABASE ENCRYPTION KEY
  WITH ALGORITHM = AES_256
  ENCRYPTION BY SERVER CERTIFICATE TDECert;
GO 

-- INFORMATION

SELECT  * 
FROM sys.dm_database_encryption_keys
GO


-- Exit out of the database. If we have an active 
-- connection, encryption won't complete.
USE [master];
GO 

-- Turn on TDE
-- T-SQL OR SSMS

ALTER DATABASE [RecoveryWithTDE]  SET ENCRYPTION ON;
GO 

--This starts the encryption process on the database. 
--Note the password I specified for the database master key. 
--As is implied, when we go to do the restore on the second server, 
-- I'm going to use a different password. 
-- Having the same password is not required, but having the same certificate is. 
-- We'll get to that as we look at the "gotchas" in the restore process.

--Even on databases that are basically empty, it does take a few seconds to encrypt the database.
--  You can check the status of the encryption with the following query:

-- We're looking for encryption_state = 3
-- Query periodically until you see that state
-- It shouldn't take long
SELECT DB_Name(database_id) AS 'Database', encryption_state 
FROM sys.dm_database_encryption_keys;
GO

--Database	encryption_state
--tempdb			3
--RecoveryWithTDE	3


-- hint

-- https://docs.microsoft.com/es-es/sql/relational-databases/system-dynamic-management-views/sys-dm-database-encryption-keys-transact-sql?view=sql-server-ver15

--encryption_state	int	Indicates whether the database is encrypted or not encrypted.

--0 = No database encryption key present, no encryption

--1 = Unencrypted

--2 = Encryption in progress

--3 = Encrypted

--4 = Key change in progress

--5 = Decryption in progress

--6 = Protection change in progress (The certificate or asymmetric key that is encrypting the database encryption key is being changed.)

-- As the comments indicate, we're looking for our database to show a state of 3, meaning the encryption is finished. 

-- When the encryption_state shows as 3, you should take a backup of the database, because we'll need it for the restore to the second server (your path may vary):

-- Now backup the database so we can restore it
-- Onto a second server

BACKUP DATABASE [RecoveryWithTDE]
TO DISK = 'C:\CERTIFICADOS\RecoveryWithTDE_Full.bak';
GO 

--Processed 288 pages for database 'RecoveryWithTDE', file 'RecoveryWithTDE' on file 1.
--Processed 3 pages for database 'RecoveryWithTDE', file 'RecoveryWithTDE_log' on file 1.
--BACKUP DATABASE successfully processed 291 pages in 0.347 seconds (6.531 MB/sec).

BACKUP LOG [RecoveryWithTDE]
TO DISK = 'C:\CERTIFICADOS\RecoveryWithTDE_log.bak'
With NORECOVERY
GO

--Processed 4 pages for database 'RecoveryWithTDE', file 'RecoveryWithTDE_log' on file 1.
--BACKUP LOG successfully processed 4 pages in 0.093 seconds (0.304 MB/sec).


------------------------------------
-- EN UNA SEGUNDA INSTANCIA PODEMOS

-- RESTORE BACKUP CON / SIN CERTIFICADO
-- ATTACH .mdf .ldf

-------------------------------------

-- RESTORE BACKUP CON / SIN CERTIFICADO


-- Si intento RESTORE eneste equipo funciona
-- Para el ejemplo habría que cambiar de Instancia
-- Attempt the restore without the certificate installed
RESTORE DATABASE [RecoveryWithTDE]
  FROM DISK = 'C:\BD\RecoveryWithTDE_Full.bak'
  WITH MOVE 'RecoveryWithTDE' TO 'C:\data\RecoveryWithTDE_2ndServer.mdf',
       MOVE 'RecoveryWithTDE_log' TO 'C:\data\RecoveryWithTDE_2ndServer_log.mdf';
GO

--Processed 288 pages for database 'RecoveryWithTDE', file 'RecoveryWithTDE' on file 1.
--Processed 3 pages for database 'RecoveryWithTDE', file 'RecoveryWithTDE_log' on file 1.
--RESTORE DATABASE successfully processed 291 pages in 0.228 seconds (9.941 MB/sec).




-- Now that we have the backup, let's restore this backup to a different instance of SQL Server.

-- Failed Restore - No Key, No Certificate

-- The first scenario for restoring a TDE protected database is the case where we try 
-- to do the restore and we have none of the encryption pieces in place. 
-- We don't have the database master key and we certainly don't have the certificate. 
-- This is why TDE is great. If you don't have these pieces, the restore simply 
-- won't work. Let's attempt the restore (note: your paths may be different):

-- Attempt the restore without the certificate installed
RESTORE DATABASE [RecoveryWithTDE]
  FROM DISK = 'C:\BD\RecoveryWithTDE_Full.bak'
  WITH MOVE 'RecoveryWithTDE' TO 'C:\data\RecoveryWithTDE_2ndServer.mdf',
       MOVE 'RecoveryWithTDE_log' TO 'C:\data\RecoveryWithTDE_2ndServer_log.mdf';
GO

--Msg 33111, Level 16, State 3, Line 130
--Cannot find server certificate with thumbprint '0x192834B1A8B932393B9101D24B8F759A49BB1397'.
--Msg 3013, Level 16, State 1, Line 130
--RESTORE DATABASE is terminating abnormally.

-- This will fail. Here's what you should see if you attempt the restore:

-- When SQL Server attempts the restore, it recognizes it needs a certificate, a specific certificate at that. Since the certificate isn't present, the restore fails.



-- Failed Restore - The Same Certificate Name, But Not the Same Certificate

-- The second scenario is where the database master key is present and there's a certificate with the same name as the first server (even the same subject), but it wasn't the certificate from the first server. Let's set that up and attempt the restore:

-- Let's create the database master key and a certificate with the same name
-- But not from the files. Note the difference in passwords
CREATE MASTER KEY
  ENCRYPTION BY PASSWORD = 'SecondServerPassw0rd!';
GO 

-- Though this certificate has the same name, the restore won't work
CREATE CERTIFICATE TDECert
  WITH SUBJECT = 'TDE Cert for Test';
GO 

-- Since we don't have the corrected certificate, this will fail, too.
RESTORE DATABASE [RecoveryWithTDE]
  FROM DISK = N'C:\BD\RecoveryWithTDE_Full.bak'
  WITH MOVE 'RecoveryWithTDE' TO N'C:\data\RecoveryWithTDE_2ndServer.mdf',
       MOVE 'RecoveryWithTDE_log' TO N'C:\data\RecoveryWithTDE_2ndServer_log.mdf';
GO
--Msg 33111, Level 16, State 3, Line 163
--Cannot find server certificate with thumbprint '0x192834B1A8B932393B9101D24B8F759A49BB1397'.
--Msg 3013, Level 16, State 1, Line 163
--RESTORE DATABASE is terminating abnormally.

-- Note the difference in the password for the database master key. It's different, but that's not the reason we'll fail with respect to the restore. It's the same problem as the previous case: we don't have the correct certificate. As a result, you'll get the same error as in the previous case.



----------

-- The Successful Restore

-- In order to perform a successful restore, we'll need the database master key in the master database in place and we'll need to restore the certificate used to encrypt the database, but we'll need to make sure we restore it with the private key. In checklist form:

--There's a database master key in the master database.
--The certificate used to encrypt the database is restored along with its private key.
--The database is restored.
--Since we have the database master key, let's do the final two steps. Of course, since we have to clean up the previous certificate, we'll have a drop certificate in the commands we issue:

-- Let's do this one more time. This time, with everything,
-- Including the private key.
DROP CERTIFICATE TDECert;
GO 

-- Restoring the certificate, but without the private key.
CREATE CERTIFICATE TDECert
  FROM FILE = 'C:\SQLBackups\TDECert.cer'
  WITH PRIVATE KEY ( 
    FILE = N'C:\SQLBackups\TDECert_key.pvk',
 DECRYPTION BY PASSWORD = 'APrivateKeyP4ssw0rd!'
  );
GO

-- We have the correct certificate and we've also restored the 
-- private key. Now everything should work. Finally!
RESTORE DATABASE [RecoveryWithTDE]
  FROM DISK = N'C:\SQLBackups\RecoveryWithTDE_Full.bak'
  WITH MOVE 'RecoveryWithTDE' TO N'C:\SQLData\RecoveryWithTDE_2ndServer.mdf',
       MOVE 'RecoveryWithTDE_log' TO N'C:\SQLData\RecoveryWithTDE_2ndServer_log.mdf';
GO

-- With everything in place, we are finally successful!

------------------------------------
-- EN UNA SEGUNDA INSTANCIA PODEMOS

-- ATTACH .mdf .ldf

-- DETACH (separar)

-- C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\RecoveryWithTDE.mdf

-- Voy al otro Servidor e intento ATTACH (adjuntar)

-- SIN CERTIFICADO ERROR
-- CON CERTIFICADO FUNCIONA ATTACH

-- ESTO SOLO FUNCIONABA CON LA VERSION ENTERPRISE, NO CON LA STANDARD
-- EN SQL SERVER 2019 FUNCIONA EN LA STANDARD

-- COPIO EN LA CARPETA CERTIFICADOS EL MDF/LDF PARA INTENTAR LA RESTAURACION EN OTRO SERVIDOR

-- COMO ESTA EN RESTORING NO PUEDO PONERLA FUERA DE LINEA PARA COPIAR LOS ARCHIVOS FISICOS.

-- PARA SACARLA DE RESTORING

RESTORE DATABASE [RecoveryWithTDE] WITH RECOVERY
GO

-- RESTORE DATABASE successfully processed 0 pages in 0.339 seconds (0.000 MB/sec).


-- DETACH DESDE GUI
-- BD DESAPARECE EXPLORADOR DE OBJETOS

-- ATTACH EN EL OTRO SERVIDOR

