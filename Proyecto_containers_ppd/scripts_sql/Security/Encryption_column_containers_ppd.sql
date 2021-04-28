/* OWNER PEREZ PONTE DIEGO*/

/*********************************************************************************************/
/*******************************     ENCRYPTION        ***************************************/
/************ Encrypt column using EncargadoLuis certificate and master key ******************/
/*******************    TEST SELECTING THE TABLES by another user    **************************/
/*********************************************************************************************/
use master
go
-- 20/04/2021
-- ======== TEST WITH SIMMETRIC KEY ==========================
-- SECURE the column Nserie from containers db with 
-- encryption for user EncargadoLuis
-- ============================================================
USE [containers_ppd_test];
GO


--Check data in teh original table
SELECT TOP 5 * FROM [Mgmt].[contenedor_ppd];
--id_contenedor	nserie	digitoctrl	modelo_cont_ppd_id_modelo	estado_cont_ppd_id_estado
--1000			347965	0			1000						1
--1001			367905	1			1001						2
--1002			245605	0			1006						3
--1003			367905	1			1001						4
--1004			135905	1			1001						5

DROP TABLE IF EXISTS containers_to_encrypt_ppd
GO

-- create a new table for this example
SELECT TOP 5 * INTO containers_to_encrypt_ppd 
FROM [Mgmt].[contenedor_ppd];
GO

--(5 rows affected)
SELECT count(*) as rows FROM containers_to_encrypt_ppd 
-- rows 
-- 5

-- grant permission for the user EncargadoLuis in the table
GRANT SELECT, INSERT, UPDATE, DELETE ON containers_to_encrypt_ppd TO [EncargadoLuis];
GO

-- 
CREATE SYMMETRIC KEY Management_Luis_Key
AUTHORIZATION [EncargadoLuis]
WITH ALGORITHM=AES_256
ENCRYPTION BY PASSWORD = 'ppdabcd1234.' 
GO

-- Add new encrypted column
ALTER TABLE containers_to_encrypt_ppd
ADD nserie_secured VARBINARY(100);


-- impersonation to user [EncargadoLuis]
EXECUTE AS USER='EncargadoLuis';
GO
-- now we are luis
SELECT USER as CurrentUser;
go
--CurrentUser
--EncargadoLuis

-- ====  OPEN the SYMMETRIC KEY BY Luis TO USE IT =====

OPEN SYMMETRIC KEY [Management_Luis_Key] DECRYPTION BY PASSWORD='ppdabcd1234.'
GO

SELECT count(*) as rows FROM containers_to_encrypt_ppd 
-- rows 
-- 5

-- now we update all data with the encrypted values


UPDATE containers_to_encrypt_ppd
SET nserie_secured = ENCRYPTBYKEY(
				KEY_GUID('Management_Luis_Key'),(
					SELECT nserie FROM containers_to_encrypt_ppd as source 
					WHERE containers_to_encrypt_ppd.id_contenedor = source.id_contenedor)
				);
GO

SELECT id_contenedor as c_id, nserie_secured FROM containers_to_encrypt_ppd;
-- tenemos el campo encryptado
--c_id	nserie_secured
--1000	0x007D0DD067C2B84B8C725A35B8465A7A02000000EF737185DFEFDC7B071CF8122016461D4609F1780AC802B1E50DED1852B9E14D
--1001	0x007D0DD067C2B84B8C725A35B8465A7A02000000F1ED693CBC779A16038D51B0F0FFDEC61549ECD5BD636F987F72589D5FA7C9A6
--1002	0x007D0DD067C2B84B8C725A35B8465A7A020000005AF457470D837CAF55B8AC877706BF2CF2029D0AB81A13485A32A7297123B740
--1003	0x007D0DD067C2B84B8C725A35B8465A7A02000000FFA1DB9529EFA35280BD9B9DD1C1183E3736B23C28CAC99A8200675101FFD20D
--1004	0x007D0DD067C2B84B8C725A35B8465A7A02000000F53213980D1800941826A116343788B53FEC911F7C1D06D3BE6E7401CE3FBB18

-- Now Luis can delete the value of nserie in all containers
UPDATE containers_to_encrypt_ppd
SET nserie = ''
GO
-- now nserie is only in the encrypted column
SELECT id_contenedor as c_id,nserie, nserie_secured FROM containers_to_encrypt_ppd;
--c_id	nserie	nserie_secured
--1000			0x007D0DD067C2B84B8C725A35B8465A7A02000000EF737185DFEFDC7B071CF8122016461D4609F1780AC802B1E50DED1852B9E14D
--1001			0x007D0DD067C2B84B8C725A35B8465A7A02000000F1ED693CBC779A16038D51B0F0FFDEC61549ECD5BD636F987F72589D5FA7C9A6
--1002			0x007D0DD067C2B84B8C725A35B8465A7A020000005AF457470D837CAF55B8AC877706BF2CF2029D0AB81A13485A32A7297123B740
--1003			0x007D0DD067C2B84B8C725A35B8465A7A02000000FFA1DB9529EFA35280BD9B9DD1C1183E3736B23C28CAC99A8200675101FFD20D
--1004			0x007D0DD067C2B84B8C725A35B8465A7A02000000F53213980D1800941826A116343788B53FEC911F7C1D06D3BE6E7401CE3FBB18
-- and it is ready
CLOSE ALL SYMMETRIC KEYS;
GO
-- RETURN TO DBO user!!!
REVERT;
GO

-- =================================================
--   WE WANT TO DECRYPT nserie_secured AFTERWARDS 
-- =================================================
-- DBO ATTEMPT
SELECT USER;
GO
-- we are dbo again
-- I AM NOW dbo! I MUST TRY TO OPEN THE KEY AGAIN TO USE IT
OPEN SYMMETRIC KEY Management_Luis_Key DECRYPTION BY PASSWORD='ppdabcd1234.'
GO

SELECT id_contenedor as ID,nserie as 'old_nserie', 
	CONVERT(VARCHAR, DECRYPTBYKEY(nserie_secured)) as 'nserie decrypted' FROM containers_to_encrypt_ppd;

GO

-- DBO with the password can decrypt the values
--ID	old_nserie	nserie decrypted
--1000				347965
--1001				367905
--1002				245605
--1003				367905
--1004				135905
CLOSE ALL SYMMETRIC KEYS;
GO

-- ATTEMPT AS Luis
EXECUTE AS USER='EncargadoLuis';
GO
OPEN SYMMETRIC KEY Management_Luis_Key DECRYPTION BY PASSWORD='ppdabcd1234.'
GO
SELECT id_contenedor as ID, 
	CONVERT(VARCHAR, DECRYPTBYKEY(nserie_secured)) as 'nserie decrypted by luis' FROM containers_to_encrypt_ppd;

GO

--ID	nserie decrypted by luis
--1000	347965
--1001	367905
--1002	245605
--1003	367905
--1004	135905

CLOSE ALL SYMMETRIC KEYS;
GO

SELECT id_contenedor as ID, 
	CONVERT(VARCHAR, DECRYPTBYKEY(nserie_secured)) as 'nserie with closed key by luis' FROM containers_to_encrypt_ppd;

GO

-- after close the keys we can't get any original value
--ID	nserie with closed key by luis
--1000	NULL
--1001	NULL
--1002	NULL
--1003	NULL
--1004	NULL

REVERT;
GO


-- WE are DBO again
-- =========================================================
--		COLUMN ENCRYPTION with certificate (more portection)
-- =========================================================

USE master;
GO


SELECT name KeyName,
	symmetric_key_id KeyId,
	key_length,
	algorithm_desc KeyDesc
FROM sys.symmetric_keys;
GO

-- create test table to apply this test
USE [containers_ppd_test];
GO
-- this master key should be created on the database to use...
CREATE MASTER KEY ENCRYPTION BY PASSWORD='Abcd1234.';
GO


--Check data in teh original table
SELECT TOP 5 * FROM [Mgmt].[contenedor_ppd];
--id_contenedor	nserie	digitoctrl	modelo_cont_ppd_id_modelo	estado_cont_ppd_id_estado
--1000			347965	0			1000						1
--1001			367905	1			1001						2
--1002			245605	0			1006						3
--1003			367905	1			1001						4
--1004			135905	1			1001						5

DROP TABLE IF EXISTS containers_to_encrypt_cert_ppd
GO

-- create a new table for this example
SELECT TOP 5 * INTO containers_to_encrypt_cert_ppd 
FROM [Mgmt].[contenedor_ppd];
GO

--(5 rows affected)
SELECT count(*) as rows FROM containers_to_encrypt_cert_ppd 
-- rows 
-- 5

-- now we create a certificate and it's symmetric key
CREATE CERTIFICATE ppd_containers_nserie_cert
	WITH SUBJECT = 'Container Serial Number';
GO

-- create symmetric key for the certificate
CREATE SYMMETRIC KEY ppd_containers_nserie_sk
	WITH ALGORITHM=AES_256
	ENCRYPTION BY CERTIFICATE ppd_containers_nserie_cert;
GO

ALTER TABLE containers_to_encrypt_cert_ppd 
	ADD Nserie_Encrypted varbinary(128);
GO

SELECT TOP 3 id_contenedor as 'Id', nserie,Nserie_Encrypted 
	FROM containers_to_encrypt_cert_ppd
GO

--Id	nserie	Nserie_Encrypted
--1000	347965	NULL
--1001	367905	NULL
--1002	245605	NULL

OPEN SYMMETRIC KEY ppd_containers_nserie_sk DECRYPTION  BY CERTIFICATE ppd_containers_nserie_cert;
GO

UPDATE containers_to_encrypt_cert_ppd
	 SET Nserie_Encrypted = ENCRYPTBYKEY( KEY_GUID('ppd_containers_nserie_sk'),nserie, 1 ,
	HASHBYTES('SHA2_256', CONVERT(varbinary, id_contenedor)));
GO

-- (5 rows affected)

SELECT TOP 3 id_contenedor as 'Id', nserie, Nserie_Encrypted 
	FROM containers_to_encrypt_cert_ppd
GO
-- NOW WE HAVE THE ENCRYPTED COLUMN Nserie_Encrypted
--Id	nserie	Nserie_Encrypted
--1000	347965	0x00722BE4B70802499466B365AE10824302000000B8717AB5C2A8D732F52315DE9611520D2378B5FB28BF4DFAAC2CC81646C3BAA23A78CAAEBD810268F513E7F16D7EE1FAEA7A440ADE6A4C4CC4EA784788C895F5
--1001	367905	0x00722BE4B70802499466B365AE10824302000000D07CD912501FF531385607AF6DE98C2B62955973DA0959A131B170FA0C7D1DD65C74FF5B34859CB2A500E9C6135288A3642B75A515F9C2E223CBD4A91A48BBC5
--1002	245605	0x00722BE4B70802499466B365AE10824302000000E0D28A138D7E949DEB4E5C992A82C5C564F3C1ED28B68FFD71FD5EB0A890463E105244493F18DA45B519A75BC12B9D3F33AE093ACEA378CCCB02EFEA4807F082