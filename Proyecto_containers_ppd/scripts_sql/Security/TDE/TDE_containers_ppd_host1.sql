/* OWNER PEREZ PONTE DIEGO*/

/*********************************************************************************************/
/*******************      TRANSPARENT DATA ENCRYPTION (TDE)       ****************************/
/*******************          ENCRYPTS THE MDF FILE!!!            ****************************/
/****************  TWE MUST PRESERVE THE SECURITY OF THE CERTIFICATE  ************************/
/*********************************************************************************************/


-- 22/04/2021

-- encript database on computer where we have our data

USE master;
GO 
-- CREATE MASTER KEY
-- to encrypt the certificate
CREATE MASTER KEY
  ENCRYPTION BY PASSWORD = 'abcd1234.';
GO 

-- CREATE CERTIFICATE
CREATE CERTIFICATE PPD_containers_cert
  WITH SUBJECT = 'PPD Cert for Containers TDE';
GO 

-- BACKUP THE CERTIFICATE IN C:\data

-- See certificate in SSMS: -BD MASTER -> -SECURITY -> -CERTIFICATES


-- CERTIFICATES T-SQL

SELECT TOP 1 * 
FROM sys.certificates 
ORDER BY name DESC
GO

--name	certificate_id	principal_id	pvt_key_encryption_type	pvt_key_encryption_type_desc	is_active_for_begin_dialog	issuer_name	cert_serial_number	sid	string_sid	subject	expiry_date	start_date	thumbprint	attested_by	pvt_key_last_backup_date	key_length
--PPD_containers_cert	260	1	MK	ENCRYPTED_BY_MASTER_KEY	1	PPD Cert for Containers TDE	5c 62 c8 d4 8b af 3f b0 42 22 c3 7b b9 16 2e ca	0x01060000000000090100000032066ACD79F04464CA2FA8D4ADAEFD9EC1056D8A	S-1-9-1-3446277682-1682239609-3567792074-2667425453-2322400705	PPD Cert for Containers TDE	2022-05-30 11:58:17.000	2021-05-30 11:58:17.000	0x32066ACD79F04464CA2FA8D4ADAEFD9EC1056D8A	NULL	NULL	2048

-- Back up the certificate and its private key
-- Remember the password!
BACKUP CERTIFICATE PPD_containers_cert
  TO FILE = 'C:\data\certificates\PPD_PPD_containers_cert_for_tde.cer'
  WITH PRIVATE KEY ( 
    FILE = 'C:\data\certificates\PPD_containers_cert_key_for_tde.pvk',
 ENCRYPTION BY PASSWORD = 'Abcd1234.'
  );
GO
-- Look at Folder C:\data\certificates
--> we hace there the PPD_cert_1_key_for_tde.pvk and PPD_cert_1_for_tde.cer



DROP DATABASE IF EXISTS PPDContainersWithTDE
GO
-- Create our test database
CREATE DATABASE [PPDContainersWithTDE];
GO 

-- Create the DEK (DATABASE ENCRYPTION KEY)so we can turn on encryption
USE [PPDContainersWithTDE];
GO 

CREATE DATABASE ENCRYPTION KEY
  WITH ALGORITHM = AES_256
  ENCRYPTION BY SERVER CERTIFICATE PPD_containers_cert;
GO 

-- INFORMATION

SELECT  * 
FROM sys.dm_database_encryption_keys
GO
-- encryption_state 1 and encryptor_type = CERTIFICATE
/*
database_id	encryption_state	create_date	regenerate_date	modify_date	set_date	opened_date	key_algorithm	key_length	encryptor_thumbprint	encryptor_type	percent_complete
2			3	2021-05-30 11:04:18.237	2021-05-30 11:04:18.237	2021-05-30 11:04:18.237	1900-01-01 00:00:00.000	2021-05-30 11:04:18.237	AES	256	0x	ASYMMETRIC KEY	0
11			1	2021-05-30 12:02:19.263	2021-05-30 12:02:19.263	2021-05-30 12:02:19.263	1900-01-01 00:00:00.000	2021-05-30 12:02:19.263	AES	256	0x32066ACD79F04464CA2FA8D4ADAEFD9EC1056D8A	CERTIFICATE	0
*/

-- Exit out of the database. If we have an active 
-- connection, encryption won't complete.
USE [master];
GO 



/**********************   FROM HERE WE SHOULD ENABLE ENCRYPTION TDE *************************/

-- we can enable TDE either in SSMS or Transact SQL
-- ======================================================
-- Turn on TDE we can do it two ways:
-- T-SQL OR SSMS

ALTER DATABASE [PPDContainersWithTDE]  SET ENCRYPTION ON;
GO 

--This starts the encryption process on the database. 
-- Is very important the password I specified for the database master key. 
-- As is implied, when we go to do the restore on the second server, 
-- I'm going to use a different password
-- but having the same password is not required, but having the same certificate is. 
-- We'll get to that as we look at it in the restore process.

--Even on databases that are basically empty, it does take a few seconds to encrypt the database.
--  You can check the status of the encryption with the following query:


-- HOW TO SEE THE ENCRYPTION STATE???
-- We're looking for encryption_state = 3
-- Query periodically until you see that state
-- It shouldn't take long


SELECT  * 
FROM sys.dm_database_encryption_keys
GO

--database_id	encryption_state	create_date	regenerate_date	modify_date	set_date	opened_date	key_algorithm	key_length	encryptor_thumbprint	encryptor_type	percent_complete
--2				3	2021-05-26 16:44:36.393	2021-05-26 16:44:36.393	2021-05-26 16:44:36.393	1900-01-01 00:00:00.000	2021-05-26 16:44:36.393	AES	256	0x	ASYMMETRIC KEY	0
--10			3	2021-05-26 16:14:04.600	2021-05-26 16:14:04.600	2021-05-26 16:14:04.600	2021-05-26 16:44:36.387	2021-05-26 16:14:04.600	AES	256	0x32066ACD79F04464CA2FA8D4ADAEFD9EC1056D8A	CERTIFICATE	0

-- to associate the database to its id
SELECT DB_Name(database_id) AS 'Database', encryption_state 
FROM sys.dm_database_encryption_keys;
GO

--Database				encryption_state
--tempdb				3
--PPDContainersWithTDE	3

-- Now is time to backup the database files so we can restore it later elsewhere
BACKUP DATABASE [PPDContainersWithTDE]
TO DISK = 'C:\Backups\PPDContainersWithTDE_Full.bak';
GO 

--Processed 368 pages for database 'PPDContainersWithTDE', file 'PPDContainersWithTDE' on file 1.
--Processed 3 pages for database 'PPDContainersWithTDE', file 'PPDContainersWithTDE_log' on file 1.
--BACKUP DATABASE successfully processed 371 pages in 0.113 seconds (25.589 MB/sec).


BACKUP LOG [PPDContainersWithTDE]
TO DISK = 'C:\Backups\PPDContainersWithTDE_log.bak'
With NORECOVERY
GO

--Processed 4 pages for database 'PPDContainersWithTDE', file 'PPDContainersWithTDE_log' on file 1.
--BACKUP LOG successfully processed 4 pages in 0.066 seconds (0.436 MB/sec).

------------------------------------
-- NOW IS TIME TO PERFORM ACTIONS IN OTHER SERVER
-- IN A SECOND INSTANCE WE COULD:

-- ---->RESTORE BACKUP WITHOUT CERTIFICATE
-- ----> TRY TO ATTACH .mdf .ldf
-- ----> and finally RESTORE THE BACKUP WITH CERTIFICATE

------------------------------------
--RESTORE DATABASE  [PPDContainersWithTDE] WITH RECOVERY;
--GO

-- CONCLUSIONS
--    This performs allow us to protect our data, see the proyect documentation
-- and the script for host2 to see how TDE is working after move data to another computer.
--    It is very important to quit our certificate backups to another place so
-- intruders cannot use it to restore de DB