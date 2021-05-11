/* OWNER PEREZ PONTE DIEGO*/

/*********************************************************************************************/
/**************************  Dynamic Data Masking        *************************************/
/**************  Hide data on specific fields with custom masks content **********************/
/****************  TEST USING ANOTHER USER WITHOUT UNMASK PERMISSION  ************************/
/*********************************************************************************************/

USE [containers_ppd_test];
GO

/* TABLE TO USE D.D. MASKING : IS [Sales].[transportista_ppd] to hide CIF and it´s adress */

SELECT * FROM [Sales].[transportista_ppd];
GO

--id_trans	nombre				CIF			modelo						direccion_ppd_id_direccion
--1002		Envíos Ruiz			22248900P	Tamaño de 20 y de 40 FEET	1000
--1003		Transportes Rayo	12000678Y	Tamaño de 40 FEET			1001


/******* CUSTOM PROCEDURE TO VIEW MASKIN STATUS ON OUR TABLES *********/

CREATE OR ALTER PROC ppdCheckCurrentMasking
AS
BEGIN
		SET NOCOUNT ON 
		SELECT c.name, tbl.name as table_name, c.is_masked, c.masking_function  
		FROM sys.masked_columns AS c  
		JOIN sys.tables AS tbl   
			ON c.[object_id] = tbl.[object_id]  
		WHERE is_masked = 1;
END
GO
EXEC ppdCheckCurrentMasking
/* none masked yet*/
--name	table_name	is_masked	masking_function


-- /********* Default Data Mask  *******/


ALTER TABLE [Sales].[transportista_ppd]
ALTER COLUMN [CIF] varchar(200) MASKED WITH (FUNCTION = 'default()');
GO

EXEC ppdCheckCurrentMasking
GO

--name	table_name	is_masked	masking_function
--CIF	transportista_ppd	1	default()

/* TRY TO SELECT AS NOTHER USER*/
EXEC AS USER = 'VendedorAngel';
GO
PRINT USER
GO
-- VendedorAngel
SELECT * FROM [Sales].[transportista_ppd];
GO

--id_trans	nombre				CIF		modelo						direccion_ppd_id_direccion
--1002		Envíos Ruiz			xxxx	Tamaño de 20 y de 40 FEET	1000
--1003		Transportes Rayo	xxxx	Tamaño de 40 FEET			1001

REVERT;
GO

PRINT USER
GO
-- dbo
SELECT * FROM [Sales].[transportista_ppd];
GO
--id_trans	nombre	CIF	modelo	direccion_ppd_id_direccion
--1002	Envíos Ruiz	22248900P	Tamaño de 20 y de 40 FEET	1000
--1003	Transportes Rayo	12000678Y	Tamaño de 40 FEET	1001


-- /********* Partial Data Mask  *******/
-- Left some content visible in column "matricula" in medio transporte veahicle

SELECT * FROM [Sales].[medio_transporte_ppd];
GO

--id_mediot	matricula	tipo	modelo_cont_ppd_id_modelo	transportista_ppd_id_trans	tarifa_ppd_id_tarifa
--1000	2323 DBR	Camion 4 ejes doble rueda	1002	1002	1001
--1001	1290 JKR	Camion trailer 2 ejes traseros doble rueda	1004	1003	1002
--1002	3423 FYZ	Camion trailer 3 ejes traseros doble rueda	1006	1003	1003
--1003	2323 DBR	Camion 4 ejes doble rueda	1002	1002	1001
--1004	1290 JKR	Camion trailer 2 ejes traseros doble rueda	1004	1003	1002
--1005	3423 FYZ	Camion trailer 3 ejes traseros doble rueda	1006	1003	1003
--1006	2323 DBR	Camion 4 ejes doble rueda	1002	1002	1001
--1007	1290 JKR	Camion trailer 2 ejes traseros doble rueda	1004	1003	1002
--1008	3423 FYZ	Camion trailer 3 ejes traseros doble rueda	1006	1003	1003


ALTER TABLE [Sales].[medio_transporte_ppd]
ALTER COLUMN [matricula] ADD MASKED WITH (FUNCTION = 'partial(0,"XXXX",4)')
GO
EXEC ppdCheckCurrentMasking
GO

-- current masks applyed
--name		table_name				is_masked	masking_function
--matricula	medio_transporte_ppd	1			partial(0, "XXXX", 4)
--CIF		transportista_ppd		1			default()

/* TRY TO SELECT AS NOTHER USER*/
EXEC AS USER = 'VendedorAngel';
GO
PRINT USER
GO
-- VendedorAngel
SELECT top 5  id_mediot,	matricula,	tipo FROM [Sales].[medio_transporte_ppd];
GO
--id_mediot	matricula	tipo
--1000		XXXX DBR	Camion 4 ejes doble rueda
--1001		XXXX JKR	Camion trailer 2 ejes traseros doble rueda
--1002		XXXX FYZ	Camion trailer 3 ejes traseros doble rueda
--1003		XXXX DBR	Camion 4 ejes doble rueda
--1004		XXXX JKR	Camion trailer 2 ejes traseros doble rueda

-- RETURN TO DBO 
REVERT;
GO

-- /********* Random Data Mask  *******/

-- Masks teh serial number to avoid sales VendedorAngel to see it

ALTER TABLE [Mgmt].[contenedor_ppd]
ALTER COLUMN nserie decimal(10,0) MASKED WITH (FUNCTION = 'random(12861, 85621)')
GO

EXEC ppdCheckCurrentMasking 
GO
-- revert 
GRANT SELECT ON [Mgmt].[contenedor_ppd] TO VendedorAngel;
GO

-- current masks
--name		table_name				is_masked	masking_function
--nserie	contenedor_ppd			1			random(12861, 85621)
--matricula	medio_transporte_ppd	1			partial(0, "XXXX", 4)
--CIF		transportista_ppd		1			default()

/* TRY TO SELECT AS ANOTHER USER*/
EXEC AS USER = 'VendedorAngel';
GO
PRINT USER
GO
-- VendedorAngel
SELECT top 5  id_contenedor as id, nserie FROM [Mgmt].[contenedor_ppd];
GO

--id	nserie
--1000	80123
--1001	70569
--1002	57487
--1003	31790
--1004	81958

-- real are: 
REVERT;
GO
SELECT top 5  id_contenedor as id, nserie as 'real nserie' FROM [Mgmt].[contenedor_ppd];
GO
--id	real nserie
--1000	347965
--1001	367905
--1002	245605
--1003	367905
--1004	135905


-- /********* Custom String Data Mask  *******/

-- We setup a message string dynamic data masking of to 
--  nombre Column of [Sales].[transportista_ppd] to hide company name

SELECT * FROM [Sales].[transportista_ppd];
GO

--id_trans	nombre	CIF	modelo	direccion_ppd_id_direccion
--1002	Envíos Ruiz	22248900P	Tamaño de 20 y de 40 FEET	1000
--1003	Transportes Rayo	12000678Y	Tamaño de 40 FEET	1001

ALTER TABLE [Sales].[transportista_ppd]
ALTER COLUMN nombre ADD MASKED WITH (FUNCTION = 'partial(0,"Forbidden",0)')
GO

EXEC ppdCheckCurrentMasking
GO

-- current masks in [containers_ppd_test] database
--name			table_name				is_masked		masking_function
--nserie		contenedor_ppd			1				random(12861, 85621)
--matricula		medio_transporte_ppd	1				partial(0, "XXXX", 4)
--nombre		transportista_ppd		1				partial(0, "Forbidden", 0)
--CIF			transportista_ppd		1				default()


-- LET EncargadoLuis select in another schema
GRANT SELECT ON [Sales].[transportista_ppd] TO EncargadoLuis;

/* TRY TO SELECT AS EncargadoLuis*/
EXEC AS USER = 'EncargadoLuis';
GO
PRINT USER
GO
--EncargadoLuis

SELECT * FROM [Sales].[transportista_ppd];
GO

-- according current masks EncargadoLuis is not able to see CIF and nombre
--id_trans	nombre		CIF		modelo						direccion_ppd_id_direccion
--1002		Forbidden	xxxx	Tamaño de 20 y de 40 FEET	1000
--1003		Forbidden	xxxx	Tamaño de 40 FEET			1001
REVERT;
GO



SELECT USER;
GO
-- dbo

-- GRANT unmask to  role Sales
GRANT UNMASK TO [Personal]
GO

-- test with an user inside personal role
EXEC AS USER = 'VendedorAngel';
GO
PRINT USER
GO
-- VendedorAngel
SELECT top 5  * FROM [Sales].[transportista_ppd];
GO

REVERT
GO

EXEC AS USER = 'EncargadoLuis';
GO
PRINT USER
GO
-- VendedorAngel
SELECT top 5  * FROM [Sales].[transportista_ppd];
GO

REVERT
GO




-- revoke select permissions
-- EncargadoLuis select in another schema
REVOKE SELECT ON [Sales].[transportista_ppd] TO EncargadoLuis;