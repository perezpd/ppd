/* OWNER PEREZ PONTE DIEGO*/

/*********************************************************************************************/
/*************************      ALWAYS ENCRYPTED        **************************************/
/*****************          ENCRYPTS THE DATA ALWAYS!!!          *****************************/
/*********************************************************************************************/

-- In the project database we have a table where we store employee data
-- We will perform data always encrypted on a new table called customer_secure_ppd

USE  [containers_ppd_test];
GO

DROP TABLE IF EXISTS [Mgmt].[customer_secure_ppd];
GO
-- createa new table customer_secure_ppd
SELECT *  INTO [Mgmt].[customer_secure_ppd]
FROM [Mgmt].[cliente_ppd];
GO


--  THE 'iban' (bank account number) and 'nif' willlbe  encrypted

-- INTODUCE INTO TABLE THE COLLATION for iban column
ALTER TABLE [Mgmt].[customer_secure_ppd] 
	ALTER COLUMN iban varchar(34) COLLATE Latin1_General_BIN2
GO
-- INTODUCE INTO TABLE  THE COLLATION for nif column
ALTER TABLE [Mgmt].[customer_secure_ppd] 
	ALTER COLUMN cif VARCHAR (10)  COLLATE Latin1_General_BIN2
GO

SELECT * FROM [Mgmt].[customer_secure_ppd]
--id_cliente	nombre	direccion_ppd_id_direccion	cif	iban
--1001	Estructuras NOROESTE	1005	1111111A	ES36 2222 5555 2222 1111 8888
--1002	Prefabricados PFR	1004	2222222B	ES31 3333 5555 4563 1231 9674
--1003	Estructuras NOROESTE	1003	3333333C	ES32 4444 1234 4432 6784 2452






/*****  HERE WE PERFORM IN SSMS GUI THE ENCRYPTION OF iban AND cif COLUMNS *****/




-- After perform encryption of cif and iban let´s select table content

SELECT USER as 'current user', * FROM [Mgmt].[customer_secure_ppd]

--current user	id_cliente	nombre					direccion_ppd_id_direccion	cif	iban
--dbo			1001		Estructuras NOROESTE	1005						0x01D8F58247865E92C19D64C0462D895100DB5A8DA2EDB2CEF257E8C8D9EC6183772B65E096DB77EC5092F30D6C02EE2AFE2A9D46260D7ABA6E44D8199C6B8C887D	0x01E6C2D1AC4CF77423748CB8808249B80863E0F8B423BF60B240159BCE9CBD0D09E8F58064704F25A3030A9F93488C7D69038450AC40C0101AF2AC612A3388F648A6B4F88F96BDA6B79A8034F2D90FDC5E
--dbo			1002		Prefabricados PFR	1004							0x010CBA740A6E4943A6DB9AE1285C34C2ED65CCEF501B9F5DFA0D0B118D54193837F8FABFEBAB9E8D2E8E4458D6980AECBE8FBFCFEBB4911076A313606ABD051C66	0x010B3DC6016FCDCABF388FF693E15E05D138A19AF873527521B2F69196AD1672A992184189E93A582E1012CDE136A030D644C5E23968E086097E30963F3781B1DA97976FEF9540BA9D0BA8FEDBA9121C0F
--dbo			1003		Estructuras NOROESTE	1003						0x0188816478E65CC78BE59EC0490A1A10CEA7800F8B7A1CA39F5627675CAD5924ED252A35A4FF87BF4886A529FFE29A201FB1D03B730A0404F765F2335B93580E73	0x01018EBAAC390CDB564B455F6C8BD64F97B3285FAC7894F69AC97FAE4F849AFD1EDDADB5D9A68DAA8331412584B7D0BA0461DA7337A623C733D00749FEDC7037B791A3FD9355DADB8B4C79293EB3C2484A



/*  Now we change the connection to the User "Containers_Admin" 
	who connects with parameter "“Column Encryption Setting = Enabled" */
USE [containers_ppd_test]
GO



SELECT USER as 'current_user',[id_cliente]
      ,[nombre]
      ,[direccion_ppd_id_direccion] as Dir
      ,[cif]
      ,[iban]
  FROM [Mgmt].[customer_secure_ppd]
GO

-- We can see perfect the data
--current_user		id_cliente	nombre					Dir		cif			iban
--Containers_Admin	1001		Estructuras NOROESTE	1005	1111111A	ES36 2222 5555 2222 1111 8888
--Containers_Admin	1002		Prefabricados PFR		1004	2222222B	ES31 3333 5555 4563 1231 9674
--Containers_Admin	1003		Estructuras NOROESTE	1003	3333333C	ES32 4444 1234 4432 6784 2452