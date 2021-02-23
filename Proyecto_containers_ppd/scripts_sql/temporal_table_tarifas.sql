USE master;
GO

/*
Here we have a table where we will store the different
cost rates of the services from the transports along the time.
Each time a new rate is given to the company,
it will be updated here.

We create this at new database just to don´t have to erase
the main database of the project on the serveral tests

*/
USE master;
GO

DROP DATABASE IF EXISTS tarifas
GO
CREATE DATABASE tarifas
GO

USE tarifas;
GO

DROP TABLE IF EXISTS tarifa_ppd
GO

DROP TABLE IF EXISTS dbo.historial_tarifa_ppd
GO
CREATE TABLE tarifa_ppd
    (
     id_tarifa INTEGER IDENTITY PRIMARY KEY,
     desc_tarifa VARCHAR (80) NOT NULL ,
     precio_dia FLOAT ,
     nombre_tarifa VARCHAR (80) NOT NULL,
     SysStartTime datetime2 GENERATED ALWAYS AS ROW START NOT NULL,
     SysEndTime datetime2 GENERATED ALWAYS AS ROW END NOT NULL,
     PERIOD FOR SYSTEM_TIME (SysStartTime,SysEndTime)
   ) WITH (
     SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.historial_tarifa_ppd)
   )
GO


INSERT INTO tarifa_ppd
			([desc_tarifa]
           ,[precio_dia]
           ,[nombre_tarifa])
Values ('Incluye recogida, carga, transporte entrega, descarga y retorno del vehículo',288.99,'Transporte container 12 metros'),
      ('Incluye recogida, carga, transporte entrega, descarga y retorno del vehículo',219.99,'Transporte container 6 metros'),
  	('Incluye recogida, carga, trasnporte entrega, descarga y retorno del vehículo',419.99,'Transporte container 12 metros refigerado')
GO

--(3 rows affected)

USE [tarifas]
GO

SELECT *
  FROM [dbo].[tarifa_ppd]
GO
--id_tarifa	desc_tarifa	precio_dia	nombre_tarifa	SysStartTime	SysEndTime
--1	Incluye recogida, carga, transporte entrega, descarga y retorno del vehículo	288.99	Transporte container 12 metros	2021-02-23 20:22:55.0774714	9999-12-31 23:59:59.9999999
--2	Incluye recogida, carga, transporte entrega, descarga y retorno del vehículo	219.99	Transporte container 6 metros	2021-02-23 20:22:55.0774714	9999-12-31 23:59:59.9999999
--3	Incluye recogida, carga, trasnporte entrega, descarga y retorno del vehículo	419.99	Transporte container 12 metros refigerado	2021-02-23 20:22:55.0774714	9999-12-31 23:59:59.9999999


SELECT * FROM [dbo].[historial_tarifa_ppd]
GO


INSERT INTO tarifa_ppd
			([desc_tarifa]
           ,[precio_dia]
           ,[nombre_tarifa])
Values ('Incluye recogida, carga, transporte entrega, descarga y retorno del vehículo',1200.99,'Transporte internacional container 12 metros')
      --('Incluye recogida, carga, transporte entrega, descarga y retorno del vehículo',1400.99,'Transporte container 6 metros'),
  	--('Incluye recogida, carga, trasnporte entrega, descarga y retorno del vehículo',1419.99,'Transporte container 12 metros refigerado')
GO
