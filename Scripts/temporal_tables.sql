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
Values (1,'Incluye recogida, carga, transporte entrega, descarga y retorno del vehículo','Transporte container 12 metros',288.99,'Transporte container 12 metros'), 
      (2,'Incluye recogida, carga, transporte entrega, descarga y retorno del vehículo',219.99,'Transporte container 6 metros'),
  	(3,'Incluye recogida, carga, trasnporte entrega, descarga y retorno del vehículo',419.99,'Transporte container 12 metros refigerado')
Go
