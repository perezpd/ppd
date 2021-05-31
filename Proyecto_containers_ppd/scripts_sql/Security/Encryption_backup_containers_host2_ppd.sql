/* OWNER PEREZ PONTE DIEGO*/

/*********************************************************************************************/
/*********************** ENCRYPTED BACKUP RESTORE in HOST2      ******************************/
/*******************    restore the Encrypt backup, certificate      *************************/
/******************* TEST DELETING THE DATABASE in another machine  **************************/
/*********************************************************************************************/

use master

-- Attempt to restore without certificate
RESTORE DATABASE [containers_ppd_test]
FROM DISK = 'C:\ppd\Backups\BackupContainers1_Encrypt.bak'
GO


--Msg 33111, Level 16, State 3, Line 4
--Cannot find server certificate with thumbprint '0xEC1A21EEB540D26AE9FF40DD3BAE3BD1F316B644'.
--Msg 3013, Level 16, State 1, Line 4
--RESTORE DATABASE is terminating abnormally.

-- Restoring the certificate.
CREATE CERTIFICATE CertificateContainersDBcert_restored
  FROM FILE = 'C:\ppd\certificates\CertificateContainersDBcert.cert'
  WITH PRIVATE KEY ( 
    FILE = N'C:\ppd\certificates\BackupCertPPD.pvk',
 DECRYPTION BY PASSWORD = 'Abcd1234.'
  );
GO


-- Attempt to restore after having the certificate
RESTORE DATABASE [containers_ppd_test]
FROM DISK = 'C:\ppd\Backups\BackupContainers1_Encrypt.bak'
GO

--Processed 616 pages for database 'containers_ppd_test', file 'containers_ppd_test_dat' on file 1.
--Processed 6 pages for database 'containers_ppd_test', file 'containers_ppd_test_log' on file 1.
--RESTORE DATABASE successfully processed 622 pages in 0.044 seconds (110.340 MB/sec).

-- test if data is correct and there
use containers_ppd_test

Select * FROM [dbo].[modelo_cont_ppd];
--id_modelo	modelo	carga_max	mgw	tara	imagen	dimension_ppd_id_dimension	dimension_ppd_id_dimension2	dimension_ppd_id_dimension3
--1000	20 FEET DRY VAN	28260	30480	2200	NULL	1000	1001	1002
--1001	20 FEET OPEN TOP	2400	27120	3120	NULL	1003	1004	1005
--1002	20 FEET PALLET WIDE	27990	30480	2490	NULL	1006	1007	1008
--1003	20 FEET PALLET WIDE HIGH CUBE	27990	30480	2490	NULL	1009	1010	1011
--1004	40 FEET DRY VAN	28650	32500	3850	NULL	1012	1013	1014
--1005	40 FEET DRY VAN HIGH CUBE	29870	35000	5130	NULL	1015	1016	1017
--1006	40 FEET PALLET WIDE	29850	34000	4150	NULL	1018	1019	1020
--1007	40 FEET PALLET WIDE HIGH CUBE	29850	34000	4150	NULL	1021	1022	1023

-- DONE!!