

ALTER DATABASE database_name SET ENCRYPTION OFF --> user database.
DROP DATABASE ENCRYPTION KEY --> user database.
DROP CERTIFICATE certificate_name --> master database 
DROP MASTER KEY --> master database.
-----------------------------------------
use master
go

-- Backup database with encryption
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Abcd1234.'
Go

-- Create an encryption certificate
CREATE CERTIFICATE DBBackupEncryptCert
WITH SUBJECT = 'Backup Encryption Certificate'
GO

SELECT name, pvt_key_encryption_type, subject
FROM sys.certificates
Go


-- Backup Master key & encryption certificate
BACKUP CERTIFICATE DBBackupEncryptCert
TO FILE = 'C:\Backup\BackupDBBackupEncryptCert.cert'
WITH PRIVATE KEY
(
FILE = 'C:\Backup\BackupCert.pvk',
ENCRYPTION BY PASSWORD = 'Abcd1234.'
)
GO


BACKUP MASTER KEY TO FILE = 'C:\Backup\BackupMasterKey.key'
ENCRYPTION BY PASSWORD = 'Abcd1234.'
GO


-- Backup database with encryption option & required encryption algorithm
BACKUP DATABASE Pubs
TO DISK = 'C:\Backup\BackupUserDB1_Encrypt.bak'
WITH
ENCRYPTION
(
ALGORITHM = AES_256,
SERVER CERTIFICATE = DBBackupEncryptCert
),
STATS = 10 
GO
-- BACKUP DATABASE successfully processed 378 pages in 0.554 seconds (5.317 MB/sec).


sp_who2
go
kill 54
go
-- RESTORE
DROP DATABASE Pubs
GO
-- Steps to restore encrypted backup 
-- 1 – Server on which Encrypted backup going to restore has Master key & Encryption certificate. No Change is restore steps either from script or GUI required.
RESTORE DATABASE Pubs 
FROM DISK = 'C:\Backup\BackupUserDB1_Encrypt.bak'
GO

-- RESTORE DATABASE successfully processed 378 pages in 0.782 seconds (3.767 MB/sec).


-- 2 - Server on which Encrypted backup going to restore, Master key & Encryption certificate does not exists
RESTORE DATABASE Pubs 
FROM DISK = 'C:\Backup\BackupUserDB1_Encrypt.bak'
GO

-- Provocara ERROR
-- Mensaje
--Msg 33111, Level 16, State 3, Line 1
--Cannot find server certificate with thumbprint ......
--Msg 3013, Level 16, State 1, Line 1
--RESTORE DATABASE is terminating abnormally.