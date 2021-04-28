/* OWNER PEREZ PONTE DIEGO*/

/*********************************************************************************************/
/*******************************     ENCRYPTION        ***************************************/
/********** Encrypt data bys different users using certificate and master key ****************/
/*******************    TEST SELECTING THE TABLES by another user    **************************/
/*********************************************************************************************/
use [containers_ppd_test]
go
-- 28/04/2021
-- ======== TEST WITH SIMMETRIC KEY ==========================
-- SECURE the column Nserie from containers db with 
-- encryption for user EncargadoLuis
-- ============================================================


--  create an extra table presupuesto for test with all references
-- notes and client associated will be encrypted
DROP TABLE IF EXISTS ppd_presupuesto_encrypted;
GO
CREATE TABLE ppd_presupuesto_encrypted(
	[id_presupuesto] [int] IDENTITY(1000,1) NOT NULL,
	[fecha] [date] NULL,
	[notas] VARBINARY(2000) NULL,
	[cliente] VARBINARY(200) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_presupuesto] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] 
GO

ALTER TABLE ppd_presupuesto_encrypted  WITH CHECK ADD  CONSTRAINT [presupuesto_cliente_FK] FOREIGN KEY([cliente])
REFERENCES [Mgmt].[cliente_ppd] ([id_cliente])
GO

ALTER TABLE ppd_presupuesto_encrypted CHECK CONSTRAINT [presupuesto_cliente_FK]
GO


-- grant permission for the users in the table
GRANT SELECT, INSERT ON ppd_presupuesto_encrypted TO [VendedorAngel],[VendedorVeronica];
GO

SELECT 
	name Keyname, symmetric_key_id KeyID, key_length KeyLength, algorithm_desc KeyAlgorithm
 FROM sys.symmetric_keys;
GO

-- create a master key in db if not already done
CREATE MASTER KEY ENCRYPTION BY PASSWORD='Abcd1234.';
GO

-- create a self certificate for each Personal Role User
CREATE CERTIFICATE Angels_cert AUTHORIZATION [VendedorAngel]
	WITH SUBJECT = 'Abcd1234.', start_date = '04/20/2021';
GO
CREATE CERTIFICATE Veros_cert AUTHORIZATION [VendedorVeronica]
	WITH SUBJECT = 'Abcd1234.', start_date = '04/20/2021';
GO

SELECT * FROM sys.certificates;
GO

--name			certificate_id	principal_id	pvt_key_encryption_type	pvt_key_encryption_type_desc	is_active_for_begin_dialog	issuer_name	cert_serial_number	sid	string_sid	subject	expiry_date	start_date	thumbprint	attested_by	pvt_key_last_backup_date	key_length
--Angels_cert	257				8	MK	ENCRYPTED_BY_MASTER_KEY	1	Abcd1234.	13 8d a5 66 ec d5 a9 95 46 97 f3 f0 76 58 39 f2	0x01060000000000090100000007435D23DA76D0E6E922962EE4D0D07D46A85B1A	S-1-9-1-593314567-3872421594-781591273-2110836964-442214470	Abcd1234.	2022-04-20 00:00:00.000	2021-04-20 00:00:00.000	0x07435D23DA76D0E6E922962EE4D0D07D46A85B1A	NULL	NULL	2048
--Veros_cert	258				9	MK	ENCRYPTED_BY_MASTER_KEY	1	Abcd1234.	1d f8 a5 77 6f b3 f8 93 4f 99 fa d4 aa 73 aa 1f	0x010600000000000901000000275144989E46C264D2F1E4F350FF693F96660830	S-1-9-1-2554614055-1690453662-4091867602-1063911248-805856918	Abcd1234.	2022-04-20 00:00:00.000	2021-04-20 00:00:00.000	0x275144989E46C264D2F1E4F350FF693F96660830	NULL	NULL	2048


-- Create a single individual simmetric key to each Personal role User certificate
CREATE SYMMETRIC KEY Angels_key
	WITH ALGORITHM=AES_256
	ENCRYPTION BY CERTIFICATE Angels_cert;
GO

CREATE SYMMETRIC KEY Veros_key
	WITH ALGORITHM=AES_256
	ENCRYPTION BY CERTIFICATE Veros_cert;
GO

SELECT * FROM SYS.symmetric_keys;
GO
--name			principal_id	symmetric_key_id	key_length	key_algorithm	algorithm_desc	create_date	modify_date	key_guid	key_thumbprint	provider_type	cryptographic_provider_guid	cryptographic_provider_algid
--Angels_key	1				262	256	A3	AES_256	2021-04-28 19:02:29.060	2021-04-28 19:02:29.060	E0F35000-A227-41B6-8B2D-5282A0376590	NULL	NULL	NULL	NULL
--Veros_key		1				263	256	A3	AES_256	2021-04-28 19:02:30.217	2021-04-28 19:02:30.217	089E8B00-B682-40F5-898F-6E5F637E054B	NULL	NULL	NULL	NULL

-- =======IMPORTANT: view only for the user who owns the certificate and the key ========
-- Grant access to their certificates only ot each owner of teh data encrypted with it
GRANT VIEW DEFINITION ON CERTIFICATE::Angels_cert TO [VendedorAngel]
GO
--Cannot grant, deny, or revoke permissions to sa, dbo, entity owner, information_schema, sys, or yourself.
GRANT VIEW DEFINITION ON SYMMETRIC KEY::Angels_key TO [VendedorAngel]
GO

GRANT VIEW DEFINITION ON CERTIFICATE::Veros_cert TO [VendedorVeronica]
GO
GRANT VIEW DEFINITION ON SYMMETRIC KEY::Veros_key TO [VendedorVeronica]
GO

-- ANGEL starts inserting budget
EXECUTE AS USER = 'VendedorAngel';
PRINT USER
GO

-- OPEN Angel's key 
OPEN SYMMETRIC KEY Angels_key
	DECRYPTION BY CERTIFICATE Angels_cert
GO

-- insert first data into presupuesto
INSERT INTO ppd_presupuesto_encrypted
           ([fecha] ,[notas] ,[cliente])
     VALUES
           ('04/15/2021'
           ,ENCRYPTBYKEY(KEY_GUID('Angels_key'),'Contenedor de referencia 32791 con un precio de 1895 euros con fecha de entrega 15 Junio 2021')
           ,1000)
GO
INSERT INTO ppd_presupuesto_encrypted
           ([fecha],[notas],[cliente])
     VALUES
	(GETDATE(),ENCRYPTBYKEY(KEY_GUID('Angels_key'),'Contenedor de num. 279854, precio 2300 euros con fecha de entrega 30 Mayo de 2021'),1001)
GO
-- Check new data
SELECT * FROM ppd_presupuesto_encrypted;
GO
--id_presupuesto	fecha	notas	cliente
--1000	2021-04-15	0x0050F3E027A2B6418B2D5282A03765900200000056586699B48A690C5A2C61188E1158AC69F2192C65621A884C38ADF99735797B3048961EC1345298372E782C1E96929EFEBAA1B9197F9662467832D5CFFC1F53DFE7AAAA5EF2A0277B55B8F905180B4B893D86D3958E65B1BF054208485A8D5161F0DC79F08610CFF3A567BC270CB33C327F08C9A2A9DDB89D353A05A98DDC86	1000
--1001	2021-04-28	0x0050F3E027A2B6418B2D5282A037659002000000962230FC7F0847B6233BEA478A1A28A9C02F76D65469B36B110042186F25570D80BF74DF317B521CACB7AA43030E1AF7F6338FEBFE7C036554FE8CAE842C0EEABE43A3A7925B2BA334B4E8FEC977E1CEE48F4D5D0AF26D88361F09DA609BAC8FF7BB77C9BB3FE7BCDEBA175C0DBCC89B	1001


CLOSE ALL SYMMETRIC KEYS;
GO


REVERT;
GO


-- VERONICA starts inserting her budget
EXECUTE AS USER = 'VendedorVeronica';
PRINT USER
GO

-- OPEN Vero's key 
OPEN SYMMETRIC KEY Veros_key
	DECRYPTION BY CERTIFICATE Veros_cert
GO

-- insert first data into presupuesto
INSERT INTO ppd_presupuesto_encrypted
           ([fecha] ,[notas] ,[cliente])
     VALUES
           ('03/30/2021'
           ,ENCRYPTBYKEY(KEY_GUID('Veros_key'),'Contenedor num 298236 con un precio de 1900€, entrega 20/07/2021')
           ,1000)
GO
INSERT INTO ppd_presupuesto_encrypted
           ([fecha],[notas],[cliente])
     VALUES
	(GETDATE(),ENCRYPTBYKEY(KEY_GUID('Veros_key'),'Contenedor de num. 458255, precio 3100 euros, pendiente de plazo'),1002)
GO
-- Check new data
SELECT * FROM ppd_presupuesto_encrypted;
GO
--id_presupuesto	fecha	notas	cliente
--1000	2021-04-15	0x0050F3E027A2B6418B2D5282A03765900200000056586699B48A690C5A2C61188E1158AC69F2192C65621A884C38ADF99735797B3048961EC1345298372E782C1E96929EFEBAA1B9197F9662467832D5CFFC1F53DFE7AAAA5EF2A0277B55B8F905180B4B893D86D3958E65B1BF054208485A8D5161F0DC79F08610CFF3A567BC270CB33C327F08C9A2A9DDB89D353A05A98DDC86	1000
--1001	2021-04-28	0x0050F3E027A2B6418B2D5282A037659002000000962230FC7F0847B6233BEA478A1A28A9C02F76D65469B36B110042186F25570D80BF74DF317B521CACB7AA43030E1AF7F6338FEBFE7C036554FE8CAE842C0EEABE43A3A7925B2BA334B4E8FEC977E1CEE48F4D5D0AF26D88361F09DA609BAC8FF7BB77C9BB3FE7BCDEBA175C0DBCC89B	1001
--1002	2021-03-30	0x008B9E0882B6F540898F6E5F637E054B02000000BC544D3453E875A23D6A355D267F9E0AEB7043018FDA030D8CB2657333C03430BCA7EF1C11507E22C465EF5B96161F82A21289D7E1137414E6290BC83A2F53779096F6BBEE402DBB4F1EA1AB371E3A4C1C2CCA8F0D2B84B3A8F5187A3D1B50B3	1000
--1004	2021-04-28	0x008B9E0882B6F540898F6E5F637E054B0200000038D751A3527F47418D52959910D1A343FA2D83806DB167AE6E3964BD049C3949EA255A06C4AE6ACB24262C78E6638CEBF27384E56822B32B44A5279D11C4B6B797566034693CA340B34FC294A6615ABA164215418F10704394BC723EBF6D15F5	1002

-- RECOVER ALL presupuestos DATA
-- Use DecryptByKey function to decrypt the data related to the budget
SELECT id_presupuesto as 'id'
      ,fecha
      ,CONVERT(VARCHAR(250), DecryptByKey(notas)) as Detalles
      ,cliente as id_cliente
  FROM ppd_presupuesto_encrypted
GO

-- VEronica can only see her budgets, not the ones Angel Inserts
--id	fecha		Detalles															id_cliente
--1000	2021-04-15	NULL																1000
--1001	2021-04-28	NULL																1001
--1002	2021-03-30	Contenedor num 298236 con un precio de 1900€, entrega 20/07/2021	1000
--1004	2021-04-28	Contenedor de num. 458255, precio 3100 euros, pendiente de plazo	1002


CLOSE ALL SYMMETRIC KEYS;
GO
REVERT;
GO

-- ANGEL now try to figure out the Veronica´s budget details
EXECUTE AS USER = 'VendedorAngel';
PRINT USER
GO

-- OPEN Angel's key 
OPEN SYMMETRIC KEY Angels_key
	DECRYPTION BY CERTIFICATE Angels_cert
GO

SELECT id_presupuesto as 'id'
      ,fecha
      ,CONVERT(VARCHAR(250), DecryptByKey(notas)) as Detalles
      ,cliente as id_cliente
  FROM ppd_presupuesto_encrypted
GO

-- He isn´t able to know the budget offered to the client
--id	fecha		Detalles																						id_cliente
--1000	2021-04-15	Contenedor de referencia 32791 con un precio de 1895 euros con fecha de entrega 15 Junio 2021	1000
--1001	2021-04-28	Contenedor de num. 279854, precio 2300 euros con fecha de entrega 30 Mayo de 2021				1001
--1002	2021-03-30	NULL																							1000
--1004	2021-04-28	NULL																							1002

CLOSE ALL SYMMETRIC KEYS;
GO
REVERT;
GO

-- CONCLUSION
-- Angel and veronica are not able to see the details of the budget they offered to clients
