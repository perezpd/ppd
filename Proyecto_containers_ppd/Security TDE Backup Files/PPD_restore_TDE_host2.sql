  /* OWNER PEREZ PONTE DIEGO*/

/*********************************************************************************************/
/*******************      TRANSPARENT DATA ENCRYPTION (TDE)       ****************************/
/*******************    TRY TO RESTORE FILES IN NEW SERVER!!!     ****************************/
/*******************         TWE MUST HAVE THE CERTIFICATE!       ****************************/
/*********************************************************************************************/


-- 22/04/2021
-- try to restore database backup on a new computer (host2) where we have moved our data


-- RESTORE BACKUP WITHOUT CERTIFICATE
USE master;
GO

-- Attempt the restore without the certificate installed
RESTORE DATABASE [PPDContainersWithTDE]
  FROM DISK = 'C:\ppd\Backups\PPDContainersWithTDE_Full.bak'
  WITH MOVE 'PPDContainersWithTDE' TO 'C:\ppd\data\PPDContainersWithTDE_host2_Full.mdf',
       MOVE 'PPDContainersWithTDE_log' TO 'C:\ppd\data\PPDContainersWithTDE_host2_log.mdf';
GO

--Msg 33111, Level 16, State 3, Line 19
--Cannot find server certificate with thumbprint '0x32066ACD79F04464CA2FA8D4ADAEFD9EC1056D8A'.
--Msg 3013, Level 16, State 1, Line 19
--RESTORE DATABASE is terminating abnormally.

/********************************************************************/
/********   Try to FAKE KEY MASTER and certificate NAME *************/
/********************************************************************/



-- Create the database master key and a certificate with the same name than in host1
-- HEre we not use the same files imported from the host1
CREATE MASTER KEY
  ENCRYPTION BY PASSWORD = 'abcd1234.'; --same password
GO 

-- Create a certificate with the same name and subject than in host1
CREATE CERTIFICATE PPD_containers_cert_for_tde
  WITH SUBJECT = 'PPD Cert for Containers TDE';
GO 

-- TRy same restore sentence again. We don't have the corrected certificate, this will fail, too.
RESTORE DATABASE [PPDContainersWithTDE]
  FROM DISK = 'C:\ppd\Backups\PPDContainersWithTDE_Full.bak'
  WITH MOVE 'PPDContainersWithTDE' TO 'C:\ppd\data\PPDContainersWithTDE_host2_Full.mdf',
       MOVE 'PPDContainersWithTDE_log' TO 'C:\ppd\data\PPDContainersWithTDE_host2_log.mdf';
GO
--Msg 33111, Level 16, State 3, Line 48
--Cannot find server certificate with thumbprint '0x32066ACD79F04464CA2FA8D4ADAEFD9EC1056D8A'.
--Msg 3013, Level 16, State 1, Line 48
--RESTORE DATABASE is terminating abnormally.
/*
 CONCLUSION:
We cannot fake the certificates and the keys to restore database even if we have the script of teh original creation of them.
The the restore is impossible and we have our data secure.
*/ 



/********************************************************************/
/********   Restore KEY MASTER and certificate from Host1 ************/
/********************************************************************/

-- Attempt a Successful Restore

/* Requirements */
-- 1. We need database master key in the master database. It has not to be the one restored from host 1
-- 2. We must have the certificate used in host1 to encrypt the database restored here with with its private key.
-- 1. We have to clean up the previous certificate.

-- We need to drop all previous certificates adn keys to ensure restore the originals From host 1
DROP CERTIFICATE PPD_containers_cert_for_tde;
GO 

-- Restoring the certificate, but without the private key.
CREATE CERTIFICATE PPD_containers_cert_for_tde
  FROM FILE = 'C:\ppd\certificates\PPD_PPD_containers_cert_for_tde.cer'
  WITH PRIVATE KEY ( 
    FILE = N'C:\ppd\certificates\PPD_containers_cert_key_for_tde.pvk',
 DECRYPTION BY PASSWORD = 'Abcd1234.'
  );
GO

-- Try again when we already have the certificate from host1 and with restored the 
-- private key.
RESTORE DATABASE [PPDContainersWithTDE]
  FROM DISK = 'C:\ppd\Backups\PPDContainersWithTDE_Full.bak'
  WITH MOVE 'PPDContainersWithTDE' TO 'C:\ppd\data\PPDContainersWithTDE_host2_Full.mdf',
       MOVE 'PPDContainersWithTDE_log' TO 'C:\ppd\data\PPDContainersWithTDE_host2_log.mdf';
GO

--Processed 360 pages for database 'PPDContainersWithTDE', file 'PPDContainersWithTDE' on file 1.
--Processed 2 pages for database 'PPDContainersWithTDE', file 'PPDContainersWithTDE_log' on file 1.
--RESTORE DATABASE successfully processed 362 pages in 0.031 seconds (91.025 MB/sec).


/*  CONCLUSION */
-- After all the pieces are in place are done we got a successful restoring!
