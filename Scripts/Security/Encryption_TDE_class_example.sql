-- 22/04/2021
-- TRANSPARENT DATA ENCRYPTION (TDE)
-- ENCRYPTS THE MDF FILE!!! WE MUST PRESERVE THE SECURITY OF THE CERTIFICATE
USE master;
GO 
-- CREATE MASTER KEY
-- to encrypt the certificate
CREATE MASTER KEY
  ENCRYPTION BY PASSWORD = 'abcd1234.';
GO 

-- CREATE CERTIFICATE
CREATE CERTIFICATE PPD_cert
  WITH SUBJECT = 'PPD Cert for Test TDE';
GO 

-- BACKUP THE CERTIFICATE IN C:\data

-- VER EN SSMS EL CERTIFICADO    -BD MASTER -SECURITY -CERTIFICATES


-- CERTIFICATES T-SQL

SELECT TOP 1 * 
FROM sys.certificates 
ORDER BY name DESC
GO

--name	certificate_id	principal_id	pvt_key_encryption_type	pvt_key_encryption_type_desc	is_active_for_begin_dialog	issuer_name	cert_serial_number	sid	string_sid	subject	expiry_date	start_date	thumbprint	attested_by	pvt_key_last_backup_date	key_length
--PPD_encriptarDBCert	263	1	MK	ENCRYPTED_BY_MASTER_KEY	1	SQL_encriptarDB Backup Certificate	2d 4e fb e1 5c f5 ee 86 43 70 63 2e 6b fa 50 bf	0x0106000000000009010000007C9B35C38289A83BF47DBDFE2101C6691B66A9D0	S-1-9-1-3275070332-1000900994-4273831412-1774584097-3500762651	SQL_encriptarDB Backup Certificate	2022-04-13 07:14:52.000	2021-04-13 07:14:52.000	0x7C9B35C38289A83BF47DBDFE2101C6691B66A9D0	NULL	NULL	2048

-- Back up the certificate and its private key
-- Remember the password!
BACKUP CERTIFICATE PPD_cert
  TO FILE = 'C:\data\PPD_cert_for_tde.cer'
  WITH PRIVATE KEY ( 
    FILE = 'C:\data\PPD_cert_key_for_tde.pvk',
 ENCRYPTION BY PASSWORD = 'Abcd1234.'
  );
GO
-- Look at Folder C:\CERTIFICADOS


DROP DATABASE IF EXISTS PPDRecoveryWithTDE
GO
-- Create our test database
CREATE DATABASE [PPDRecoveryWithTDE];
GO 

-- Create the DEK (DATABASE ENCRYPTION KEY)so we can turn on encryption
USE [PPDRecoveryWithTDE];
GO 

CREATE DATABASE ENCRYPTION KEY
  WITH ALGORITHM = AES_256
  ENCRYPTION BY SERVER CERTIFICATE PPD_cert;
GO 

-- INFORMATION

SELECT  * 
FROM sys.dm_database_encryption_keys
GO


-- Exit out of the database. If we have an active 
-- connection, encryption won't complete.
USE [master];
GO 
-- ======================================================
-- Turn on TDE
-- T-SQL OR SSMS

ALTER DATABASE [PPDRecoveryWithTDE]  SET ENCRYPTION ON;
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

--Database				encryption_state
--tempdb				3
--PPDRecoveryWithTDE	3


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

BACKUP DATABASE [PPDRecoveryWithTDE]
TO DISK = 'C:\backups\PPDRecoveryWithTDE_Full.bak';
GO 

--Processed 360 pages for database 'PPDRecoveryWithTDE', file 'PPDRecoveryWithTDE' on file 1.
--Processed 2 pages for database 'PPDRecoveryWithTDE', file 'PPDRecoveryWithTDE_log' on file 1.
--BACKUP DATABASE successfully processed 362 pages in 0.077 seconds (36.646 MB/sec).

BACKUP LOG [PPDRecoveryWithTDE]
TO DISK = 'C:\data\PPDRecoveryWithTDE_log.bak'
With NORECOVERY
GO

--Processed 3 pages for database 'PPDRecoveryWithTDE', file 'PPDRecoveryWithTDE_log' on file 1.
--BACKUP LOG successfully processed 3 pages in 0.023 seconds (0.934 MB/sec).



------------------------------------
-- TESTS TO PERFORM WITH OTHER BACKUPS AND CERITFICATES OR IN OTHER SERVER
-- EN UNA SEGUNDA INSTANCIA PODEMOS 

-- RESTORE BACKUP CON / SIN CERTIFICADO
-- ATTACH .mdf .ldf

-------------------------------------

-- RESTORE BACKUP CON / SIN CERTIFICADO


-- Si intento RESTORE eneste equipo funciona
-- instrucci�n no completa
RESTORE DATABASE [PPDRecoveryWithTDE]
  FROM DISK = 'C:\Backups\RecoveryWithTDE_Full.bak'
  WITH MOVE 'RecoveryWithTDE' TO 'C:\data\RecoveryWithTDE_2ndServer.mdf',
       MOVE 'RecoveryWithTDE_log' TO 'C:\data\RecoveryWithTDE_2ndServer_log.mdf';
GO


-- Para el ejemplo habr�a que cambiar de Instancia
-- Attempt the restore without the certificate installed



-- >>>>>>>>> This is the backup form the teacher!!!!!!!<<<<<<
RESTORE DATABASE [RecoveryWithTDE]
  FROM DISK = 'C:\Backups\RecoveryWithTDE_Full.bak'
  WITH MOVE 'RecoveryWithTDE' TO 'C:\data\RecoveryWithTDE_2ndServer.mdf',
       MOVE 'RecoveryWithTDE_log' TO 'C:\data\RecoveryWithTDE_2ndServer_log.mdf';
GO

-- from the teacher
--Msg 33111, Level 16, State 3, Line 162
--Cannot find server certificate with thumbprint '0xBF05FDBA4584C56ACAEC9AE38E0FF4EED74E7F83'.
--Msg 3013, Level 16, State 1, Line 162
--RESTORE DATABASE is terminating abnormally.

-- with mine

-->>>>>>>>>>>>>>>>>>>>>>>>TO DO



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

-- Attempt the restore teachers bd without the certificate installed
RESTORE DATABASE [RecoveryWithTDE]
  FROM DISK = 'C:\Backups\RecoveryWithTDE_Full.bak'
  WITH MOVE 'RecoveryWithTDE' TO 'C:\data\RecoveryWithTDE_2ndServer.mdf',
       MOVE 'RecoveryWithTDE_log' TO 'C:\data\RecoveryWithTDE_2ndServer_log.mdf';
GO
-- of course it failsssss we dont have the certificate

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
CREATE CERTIFICATE PPD_second_cert
  WITH SUBJECT = 'TDE Cert for Test';
GO 

-- Since we don't have the corrected certificate, this will fail, too.
RESTORE DATABASE [RecoveryWithTDE]
  FROM DISK = N'C:\Backups\RecoveryWithTDE_Full.bak'
  WITH MOVE 'RecoveryWithTDE' TO N'C:\data\RecoveryWithTDE_teachers.mdf',
       MOVE 'RecoveryWithTDE_log' TO N'C:\data\RecoveryWithTDE_teachers_log.mdf';
GO

-- in efect it fails with teh new certificates..... 

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
DROP CERTIFICATE PPD_teachers_cert;
GO 

-- Restoring the certificate, but without the private key.
CREATE CERTIFICATE PPD_teachers_cert
  FROM FILE = 'C:\data\teacher_files\TDECert.cer'
  WITH PRIVATE KEY ( 
    FILE = N'C:\data\teacher_files\TDECert_key.pvk',
 DECRYPTION BY PASSWORD = 'Abcd1234.'
  );
GO

-- We have the correct certificate and we've also restored the 
-- private key. Now everything should work. Finally!
RESTORE DATABASE [RecoveryWithTDE]
  FROM DISK = N'C:\data\teacher_files\RecoveryWithTDE_Full.bak'
  WITH MOVE 'RecoveryWithTDE' TO N'C:\data\RecoveryWithTDE_2ndServer.mdf',
       MOVE 'RecoveryWithTDE_log' TO N'C:\data\RecoveryWithTDE_2ndServer_log.mdf';
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

RESTORE DATABASE [PPDRecoveryWithTDE] WITH RECOVERY
GO

--RESTORE DATABASE successfully processed 0 pages in 0.155 seconds (0.000 MB/sec).


-- RESTORE DATABASE successfully processed 0 pages in 0.339 seconds (0.000 MB/sec).


-- DETACH DESDE GUI
-- BD DESAPARECE EXPLORADOR DE OBJETOS

-- ATTACH EN EL OTRO SERVIDOR



