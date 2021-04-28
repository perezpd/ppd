/* insert some data to set presupuestos for management */
USE [containers_ppd_test]
GO

INSERT INTO [Mgmt].[direccion_ppd]
           ([via]
           ,[calle]
           ,[calle2]
           ,[CP]
           ,[ciudad]
           ,[provincia]
           ,[pais])
     VALUES
           ('Calle','Bandera, 200',null,'15022','A coruña','A coruña','España'),--1006
           (null,'Polígono de Pocomaco Nave 60',null,'15012','A coruña','A coruña','España'), --1007
           ('Avenida','Salamanca, 12',null,'25874','O Ceao','Lugo','España') --1008
GO

SELECT * FROM [Mgmt].[direccion_ppd];
--id_direccion	via	calle	calle2	CP	ciudad	provincia	pais
--1000			Avenida de 	La Concordia, 200	NULL	15022	A coruña	A coruña	España
--1001			NULL	Polígono de Pocomaco Nave 43	NULL	15012	A coruña	A coruña	España
--1002			Terminal de 	Gran Canaria, 22	NULL	25874	Tenerife	Gran Canaria	España
--1003			Avenida de 	La Concordia, 200	NULL	15022	A coruña	A coruña	España
--1004			NULL	Polígono de Pocomaco Nave 43	NULL	15012	A coruña	A coruña	España
--1005			Terminal de 	Gran Canaria, 22	NULL	25874	Tenerife	Gran Canaria	España
--1006			Calle	Bandera, 200	NULL	15022	A coruña	A coruña	España
--1007			NULL	Polígono de Pocomaco Nave 60	NULL	15012	A coruña	A coruña	España
--1008			Avenida	Salamanca, 12	NULL	25874	O Ceao	Lugo	España



INSERT INTO [Mgmt].[cliente_ppd]
	([nombre]
      ,[direccion_ppd_id_direccion])
     VALUES
           ('Construcciones Hermida',1006), --1000
           ('Desarrolla S.A',1007),			  --1001
           ('Inmobiliaria Salamanca',1008) --1002
GO

SELECT * FROM [Mgmt].[cliente_ppd]
--id_cliente	nombre					direccion_ppd_id_direccion
--1000			Construcciones Hermida	1006
--1001			Desarrolla S.A			1007
--1002			Inmobiliaria Salamanca	1008


-- creating an user with no login to avoid errors
DROP USER IF EXISTS VendedorVeronica
GO
CREATE USER VendedorVeronica WITHOUT LOGIN;
GO
-- adding user EncargadoLuis to ROLE OfficeMgmt
ALTER ROLE Personal
	ADD MEMBER VendedorVeronica;
GO


/* UPDATE PERMISSION ON TABLE presupuestos TO Personal*/
GRANT SELECT, INSERT, UPDATE  ON [Mgmt].[presupuesto_ppd] TO Personal ;  
GO


