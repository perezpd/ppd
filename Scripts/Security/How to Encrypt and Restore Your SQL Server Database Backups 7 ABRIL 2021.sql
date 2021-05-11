-- USANDO BD DE USUARIO NO MASTER

-- How to Encrypt and Restore Your SQL Server Database Backups
use master
go
sp_who2
go
kill 53
go


DROP DATABASE IF EXISTS BackupEncryptionDemo
GO
CREATE DATABASE BackupEncryptionDemo
GO
USE BackupEncryptionDemo
GO

CREATE TABLE BackupEncryptionDemo.dbo.Test(Id INT IDENTITY, Blah NVARCHAR(10))
INSERT INTO BackupEncryptionDemo.dbo.Test(Blah) VALUES('Testing')
INSERT INTO BackupEncryptionDemo.dbo.Test(Blah) VALUES('Testing2')
GO


CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Abcd1234.'
go

 
CREATE CERTIFICATE BackupEncryptionDemoCERT 
   WITH SUBJECT = 'BackupEncryptionDemoBackup Encryption Certificate';  
GO  

BACKUP DATABASE BackupEncryptionDemo
TO DISK = 'C:\ENCRYPTION\BackupEncryptionDemoBackup.bak'  
WITH  
  COMPRESSION,  
  ENCRYPTION   
   (  
   ALGORITHM = AES_256,  
   SERVER CERTIFICATE = BackupEncryptionDemoCERT
   ),  
  STATS = 10  
GO


-- Warning: The certificate used for encrypting the database encryption key has not been backed up. You should immediately back up the certificate and the private key associated with the certificate. If the certificate ever becomes unavailable or if you must restore or attach the database on another server, you must have backups of both the certificate and the private key or you will not be able to open the database.

BACKUP CERTIFICATE BackupEncryptionDemoCERT
   TO FILE = 'C:\ENCRYPTION\BackupEncryptionDemoCERT.cer'
   WITH PRIVATE KEY(
      FILE='C:\ENCRYPTION\BackupEncryptionDemoCERT.ppk', 
      ENCRYPTION BY PASSWORD ='Abcd1234.'
   )
GO

-- 2 backup. no me da warning

BACKUP DATABASE BackupEncryptionDemo
TO DISK = 'C:\ENCRYPTION\BackupEncryptionDemoBackup2.bak'  
WITH  
  COMPRESSION,  
  ENCRYPTION   
   (  
   ALGORITHM = AES_256,  
   SERVER CERTIFICATE = BackupEncryptionDemoCERT
   ),  
  STATS = 10  
GO

-- Now we have our encrypted backup, 
-- let’s try to restore it on our FIRST server…
DROP DATABASE BackupEncryptionDemo 
GO
RESTORE DATABASE BackupEncryptionDemo 
   FROM DISK = 'C:\ENCRYPTION\BackupEncryptionDemoBackup.bak' 
   WITH 
      MOVE 'BackupEncryptionDemo' TO 'c:\Data\EncryptionDemo.mdf', 
      MOVE 'BackupEncryptionDemo_log' TO 'C:\Data\EncryptionDemo_log.ldf'
go

USE [BackupEncryptionDemo]
GO
SELECT * FROM [dbo].[Test]
GO
----------------------------------------------------------

-- Now we have our encrypted backup, 
-- let’s try to restore it on our SECOMD server…

--We can’t restore it because it was encrypted with a certificate that we don’t yet have
-- on this server and without this certificate the backup can’t be decrypted.

--As before we can’t store any certificates without a master key so let’s get that created…

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Abcd1234.'
GO

CREATE CERTIFICATE BackupEncryptionDemoCERT
   FROM FILE = 'C:\ENCRYPTION\BackupEncryptionDemoCERT.cer'
GO

--At this point, depending on your credentials there is a good chance you will see an 
-- error similar to this…

-- This is because the NTFS permissions SQL Server put on the certificate and private key 
-- backup don’t give access to the service account your destination server is running under. 
-- To fix this open a Command Prompt window as Administrator and run the following command, 
-- replacing the username (MSSQLSERVER) with the account your server is running under and 
-- point it at the directory the backup keys are stored in…

--      icacls C:\ENCRYPTION /grant MSSQLSERVER:(GR) /T

--This will have now granted our SQL Server account read access to these files so let’s try restoring that certificate again…

     
CREATE CERTIFICATE BackupEncryptionDemoCERT
   FROM FILE = 'C:\ENCRYPTION\BackupEncryptionDemoCERT.cer'
GO



-- That time it should go through with no error, so we now have our certificate and master key all setup, Let’s try restoring that backup again…

RESTORE DATABASE BackupEncryptionDemo 
   FROM DISK = 'C:\ENCRYPTION\BackupEncryptionDemoBackup.bak' 
   WITH 
      MOVE 'BackupEncryptionDemo' TO 'c:\Data\EncryptionDemo.mdf', 
      MOVE 'BackupEncryptionDemo_log' TO 'C:\Data\EncryptionDemo_log.ldf'
go

-- Still no luck, the restore failed because the keys we restored are corrupt. 
-- This is because when we restored the certificate we didn’t specify our private key 
-- and password file to decrypt it, let’s drop the certificate we restored and try again…


DROP CERTIFICATE SuperSafeBackupCertificate
GO

CREATE CERTIFICATE BackupEncryptionDemoCERT
   FROM FILE = 'C:\ENCRYPTION\BackupEncryptionDemoCERT.cer'
   WITH PRIVATE KEY(
      FILE ='C:\ENCRYPTION\BackupEncryptionDemoCERT.ppk', 
      DECRYPTION BY PASSWORD='Abcd1234.'
   )
go


RESTORE DATABASE BackupEncryptionDemo 
   FROM DISK = 'C:\ENCRYPTION\BackupEncryptionDemoBackup.bak' 
   WITH 
      MOVE 'BackupEncryptionDemo' TO 'c:\Data\EncryptionDemo.mdf', 
      MOVE 'BackupEncryptionDemo_log' TO 'C:\Data\EncryptionDemo_log.ldf'
go



