/* OWNER PEREZ PONTE DIEGO*/

/*********************************************************************************************/
/*******************************     ENCRYPTION        ***************************************/
/*********************  Encrypt backup, certificate and master key ***************************/
/******************* TEST DELETING THE DATABASE in another machine  **************************/
/*********************************************************************************************/

use master
go
-- 19/04/2021
-- ======= Backup database containers with encryption ========

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Abcd1234.'
GO

-- Create an encryption certificate for containers DB
CREATE CERTIFICATE CertificateContainersDBcert
WITH SUBJECT = 'Containers Backup Encryption Certificate'
GO

SELECT name, pvt_key_encryption_type, subject
FROM sys.certificates
Where name = 'CertificateContainersDBcert'
GO
-- result: this is our new certificate to use with DB containers
--name							pvt_key_encryption_type		subject
--CertificateContainersDBcert	MK							Containers Backup Encryption Certificate

-- BACKUP MASTER KEY & CERTIFICATE ENCRYPTION
-- I separate the storage place of both encrypted files 

--Backup Master Key & Encryption Certificate
-- SUMMARY OF THE NEW FILES WE ARE GOING TO CREATE:
--BACKUP CERTIFICATE = 'C:\BackupsPPD\CertificateContainersDBcert.cert'
--BACKUP CERTIFICATE ENCRYPTED WITH MASTER KEY TO FILE = 'C:\data\BackupCertPPD.pvk'
--BACKUP MASTER KEY TO FILE = 'C:\Backups\BackupMasterKey.key'


-- backup cert and encrypted cert
BACKUP CERTIFICATE CertificateContainersDBcert
TO FILE= 'C:\Backups\CertificateContainersDBcert.cert'
WITH PRIVATE KEY
(
FILE = 'C:\data\BackupCertPPD.pvk',
ENCRYPTION BY PASSWORD = 'Abcd1234.'
)
GO

-- BACKUP MASTER KEY
BACKUP MASTER KEY TO FILE = 'C:\Backups\BackupMasterKeyPPD.key'
ENCRYPTION BY PASSWORD ='Abcd1234.'
GO


--BACKUP DATABASE WITH ENCRYPTION OPTION & REQUIRED ENCRYPTION ALGORITHM
BACKUP DATABASE [containers_ppd_test]
TO DISK = 'C:\Backups\BackupContainers1_Encrypt.bak'
WITH
ENCRYPTION
(
ALGORITHM = AES_256,
SERVER CERTIFICATE = CertificateContainersDBcert
),
STATS = 10 -- this is green in SSMS beacuse it is doing a % increment
GO

/* RESULT
10 percent processed.
21 percent processed.
30 percent processed.
41 percent processed.
50 percent processed.
61 percent processed.
70 percent processed.
81 percent processed.
90 percent processed.
Processed 520 pages for database 'containers_ppd_test', file 'containers_ppd_test' on file 1.
100 percent processed.
Processed 2 pages for database 'containers_ppd_test', file 'containers_ppd_test_log' on file 1.
BACKUP DATABASE successfully processed 522 pages in 0.085 seconds (47.891 MB/sec).
*/



-- We want to delete DB now, so we remove de DB and  if it is in use, 
-- we can see with this sentence which process is usin it and kill it

sp_who2
GO
/*
SPID	Status	Login	HostName	BlkBy	DBName	Command	CPUTime	DiskIO	LastBatch	ProgramName	SPID	REQUESTID
1    	BACKGROUND                    	sa	  .	  .	NULL	XTP_CKPT_AGENT  	0	0	04/19 17:42:08	                                              	1    	0    
2    	BACKGROUND                    	sa	  .	  .	NULL	LOG WRITER      	0	0	04/19 17:42:08	                                              	2    	0    
*/
-- We can finish the process using the DB with kill
kill 54 -- kill the SPID number
GO

-- DELETE AND RESTORE
DROP DATABASE [containers_ppd_test]
GO
-- Now we have already the cert and the key so restore is successful

RESTORE DATABASE [containers_ppd_test]
FROM DISK = 'C:\Backups\BackupContainers1_Encrypt.bak'
GO

--Processed 520 pages for database 'containers_ppd_test', file 'containers_ppd_test' on file 1.
--Processed 2 pages for database 'containers_ppd_test', file 'containers_ppd_test_log' on file 1.
--RESTORE DATABASE successfully processed 522 pages in 0.048 seconds (84.808 MB/sec).