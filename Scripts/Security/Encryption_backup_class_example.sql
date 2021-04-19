

use master
go
-- 15/04/2021
-- ======= Backup database with encryption ========
-- 

--
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Abcd1234.'
GO

-- Create an encryption certificate
CREATE CERTIFICATE DBBackupEncryptCert
WITH SUBJECT = 'Backup Encryption Certificate'
GO

SELECT name, pvt_key_encryption_type, subject
FROM sys.certificates
GO

/*
name									pvt_key_encryption_type	subject
##MS_SQLResourceSigningCertificate##	NA						MS_SQLResourceSigningCertificate
##MS_SQLReplicationSigningCertificate##	NA	MS_SQLReplicationSigningCertificate
##MS_SQLAuthenticatorCertificate##		NA	MS_SQLAuthenticatorCertificate
##MS_AgentSigningCertificate##			NA	MS_AgentSigningCertificate
##MS_PolicySigningCertificate##			NA	MS_PolicySigningCertificate
##MS_SmoExtendedSigningCertificate##	NA	MS_SmoExtendedSigningCertificate
##MS_SchemaSigningCertificate3AD2C1F412E64C5724F4EB805ED2334862F3FBD5##	NA	MS_SchemaSigningCertificate3AD2C1F412E64C5724F4EB805ED2334862F3FBD5
Cert_April_2021							MK	Customer Credit Card Number
DBBackupEncryptCert						MK	Backup Encryption Certificate
*/



-- BACKUP MASTER KEY & CERTIFICATE ENCRYPTION
-- best practise to separate the storage place of both encrypted files 

--Backup Master Key & Encryption Certificate
BACKUP CERTIFICATE DBBackupEncryptCert
TO FILE= 'C:\Backups\BackupDBBackupEncryptCert.cert'
WITH PRIVATE KEY
(
FILE = 'C:\data\BackupCert.pvk',
ENCRYPTION BY PASSWORD = 'Abcd1234.'
)
GO

--BACKUP MASTER KEY TO FILE = 'C:\Backups\BackupMasterKey.key'

BACKUP MASTER KEY TO FILE = 'C:\Backups\BackupMasterKey.key'
ENCRYPTION BY PASSWORD ='Abcd1234.'
GO


--BACKUP DATABASE WITH ENCRYPTION OPTION & REQUIRED ENCRYPTION ALGORITHM

BACKUP DATABASE Pubs
TO DISK = 'C:\Backups\BackupUserDB1_Encrypt.bak'
WITH
ENCRYPTION
(
ALGORITHM = AES_256,
SERVER CERTIFICATE = DBBackupEncryptCert
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
Processed 600 pages for database 'Pubs', file 'pubs' on file 1.
100 percent processed.
Processed 2 pages for database 'Pubs', file 'pubs_log' on file 1.
BACKUP DATABASE successfully processed 602 pages in 0.110 seconds (42.689 MB/sec).
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
kill 54 -- kill the SPID number
GO

-- DELETE AND RESTORE
DROP DATABASE pubs
GO

-- Steps to restore encrypted backup
-- 1- Server on which Encrypted backup going to restore has Master key & Encryption certificate. No Change is restore steps either from script or GUI reuired.

RESTORE DATABASE Pubs
FROM DISK = 'C:\Backups\BackupUserDB1_Encrypt.bak'
GO

-- BORRO LABASE DE DATOS Y COMO ESTOY EN UN SERVER QUE TIENE EL CERTTIFICADO FUNCIONA. SI LO HAGO EN OTRO, ME DA ERROR