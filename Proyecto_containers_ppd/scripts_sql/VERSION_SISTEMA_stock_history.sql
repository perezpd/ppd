/* OWNER PEREZ PONTE DIEGO*/

/*********************************************************************************************/
/********************************  SYSTEM VERSION TABLES    **********************************/
/******************** trg_increase_stock_on_order_for_history_table  *************************/
/*********************************************************************************************/
/*
Here we have a table where we will store the different
stocks of the containers along the time.
Each time a new container arrives to the company,
it will be updated here and saved in the history.
*/

USE [containers_ppd_test_TR]


/* WE WILL INCREASE THE STOCK OF CONTAINERS WE HAVE IN STOCK
 with the trigger 	at the time 
 EACH TIME A NEW CONTAINER COMES TO OFFICE AND IS INSERTED
	THE HISTORY TABLE WILL SAVE THE TIME OF THE STOCK IN EACH MOMENT 
*/

 /* ------ THOSE ARE OUR CONTAINER MODELS ------
id_modelo	modelo							tara
1000		20 FEET DRY VAN					2200
1001		20 FEET OPEN TOP				3120
1002		20 FEET PALLET WIDE				2490
1003		20 FEET PALLET WIDE HIGH CUBE	2490
1004		40 FEET DRY VAN					3850
1005		40 FEET DRY VAN HIGH CUBE		5130
1006		40 FEET PALLET WIDE				4150
1007		40 FEET PALLET WIDE HIGH CUBE	4150
*/
IF OBJECT_ID ('Current_stock_ppd', 'U') IS NOT NULL
	ALTER TABLE [dbo].[Current_stock_ppd] SET ( SYSTEM_VERSIONING = OFF  )
GO

DROP TABLE IF EXISTS Current_stock_ppd;
GO

DROP TABLE IF EXISTS dbo.historial_stock_ppd
GO
-- create Current_stock_ppd wit system versioning table historial_stock_ppd
CREATE TABLE Current_stock_ppd
    (
     id_stock INTEGER IDENTITY PRIMARY KEY,
     cantidad INT NOT NULL ,
     modelo_cont_ppd_id_modelo INT NOT null,
     SysStartTime datetime2 GENERATED ALWAYS AS ROW START NOT NULL,
     SysEndTime datetime2 GENERATED ALWAYS AS ROW END NOT NULL,
     PERIOD FOR SYSTEM_TIME (SysStartTime,SysEndTime)
   ) WITH (
     SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.historial_stock_ppd)
   )
GO




--USE [containers_ppd_test_TR]
--GO


INSERT INTO Current_stock_ppd
	( [cantidad], [modelo_cont_ppd_id_modelo])
	VALUES
           (12,1002), --20 FEET PALLET WIDE
           (3,1004), --40 FEET DRY VAN
           (24,1006) --40 FEET PALLET WIDE	  
GO



USE [containers_ppd_test_TR];
GO

SELECT *  FROM Current_stock_ppd;
GO
/* stock we have now */
--id_stock	cantidad	modelo_cont_ppd_id_modelo	SysStartTime				SysEndTime
--1			12			1002						2021-03-13 14:48:30.2702005	9999-12-31 23:59:59.9999999
--2			3			1004						2021-03-13 14:48:30.2702005	9999-12-31 23:59:59.9999999
--3			24			1006						2021-03-13 14:48:30.2702005	9999-12-31 23:59:59.9999999


/**************************************************************/
/*   NEW TRIGGER TO UPDATE STOCK IN HISTORIC TABLE  */
/* We select the stock id to increase or insert a new one*/

DROP TRIGGER IF EXISTS trg_increase_stock_on_order_for_history_table;
GO
IF OBJECT_ID ('trg_increase_stock_on_order_for_history_table', 'TR') IS NOT NULL
  DROP TRIGGER trg_increase_stock_on_order_for_history_table
GO
CREATE OR ALTER TRIGGER trg_increase_stock_on_order_for_history_table
ON [Mgmt].[contenedor_ppd]
FOR INSERT
AS
BEGIN
	DECLARE @result VARCHAR(200);
	DECLARE @stockID INT;
	DECLARE @stockQt INT;
	SELECT @stockID = S.id_stock, @stockQt = S.cantidad from Current_stock_ppd as S INNER JOIN 
			[modelo_cont_ppd] as M ON M.id_modelo = S.modelo_cont_ppd_id_modelo 
			WHERE S.modelo_cont_ppd_id_modelo = (SELECT  [modelo_cont_ppd_id_modelo] FROM INSERTED)
	PRINT @stockID ;
	PRINT @stockQt ;
	IF @stockID > 0
		BEGIN
			PRINT 'Modificamos stock del modelo insertado!';
			SELECT  @result = CONCAT('Para el modelo ',modelo_cont_ppd_id_modelo, ' el actual Stock es ', cantidad) from Current_stock_ppd 
				WHERE id_stock = @stockID;
			PRINT @result;
			-- update the stock
			UPDATE Current_stock_ppd SET cantidad = cantidad + 1
				WHERE id_stock = @stockID
			-- show new stock
			SELECT @result = CONCAT('Para el modelo ',modelo_cont_ppd_id_modelo, ' el nuevo Stock es ', cantidad) from Current_stock_ppd
				WHERE id_stock = @stockID;
			PRINT @result;
			--ROLLBACK TRAN
		END
	ELSE
		BEGIN
			PRINT 'Insertamos 1 unidad de stock del nuevo modelo de contenedor insertado!'
			INSERT INTO Current_stock_ppd ([cantidad],[modelo_cont_ppd_id_modelo])
				 VALUES
					   (1,(SELECT  [modelo_cont_ppd_id_modelo] FROM INSERTED));
			SELECT @result = CONCAT('Para el modelo ',(SELECT  [modelo_cont_ppd_id_modelo] FROM INSERTED), ' tenemos ahora ', 1, ' disponible en stock');
			PRINT @result;
			--ROLLBACK TRAN
		END
 END;
 GO
/**********************************************************/
 -------  PERFORM INSERTS TO DISPATCH THE TRIGGER ---------
/**********************************************************/

USE [containers_ppd_test_TR]
GO

SELECT S.* from Current_stock_ppd as S INNER JOIN [modelo_cont_ppd] as M ON M.id_modelo = S.modelo_cont_ppd_id_modelo 
GO

-- insertamos un contenedor del modelo que ya hay 3 en stock
INSERT INTO [Mgmt].[contenedor_ppd]
           ([nserie]
           ,[digitoctrl]
           ,[modelo_cont_ppd_id_modelo]
		   ,[estado_cont_ppd_id_estado])
     VALUES
           ('121212'
           ,0
           ,1004, 7)
GO
/* RESULTADO
Modificamos stock del modelo insertado!
Para el modelo 1004 el actual Stock es 3

(1 row affected)
Para el modelo 1004 el nuevo Stock es 4

(1 row affected)
*/
/*     CHECK HISTORY TABLE    */
SELECT * FROM dbo.historial_stock_ppd;
GO
--id_stock	cantidad	modelo_cont_ppd_id_modelo	SysStartTime	SysEndTime
--2			3			1004	2021-03-13 14:48:30.2702005	2021-03-13 14:51:29.8673014




-- insertamos un contenedor del modelo que NO hay stock
INSERT INTO [Mgmt].[contenedor_ppd]
           ([nserie]
           ,[digitoctrl]
           ,[modelo_cont_ppd_id_modelo]
		   ,[estado_cont_ppd_id_estado])
     VALUES
           ('3333675'
           ,1
           ,1005, 6)
GO
/* RESULTADO

Insertamos 1 unidad de stock del nuevo modelo de contenedor insertado!

(1 row affected)
Para el modelo 1005 tenemos ahora 1 disponible en stock

(1 row affected)
*/

-- resultado
SELECT S.* from Current_stock_ppd as S INNER JOIN [modelo_cont_ppd] as M ON M.id_modelo = S.modelo_cont_ppd_id_modelo 
GO

--id_stock	cantidad	modelo_cont_ppd_id_modelo	SysStartTime				SysEndTime
--1			12			1002						2021-03-13 14:48:30.2702005	9999-12-31 23:59:59.9999999
--2			4			1004						2021-03-13 14:51:29.8673014	9999-12-31 23:59:59.9999999     <-------- +1
--3			24			1006						2021-03-13 14:48:30.2702005	9999-12-31 23:59:59.9999999
--4			1			1005						2021-03-13 14:55:57.4578273	9999-12-31 23:59:59.9999999     <-------- New


/*     CHECK HISTORY TABLE    */
SELECT * FROM dbo.historial_stock_ppd;
GO
--id_stock	cantidad	modelo_cont_ppd_id_modelo	SysStartTime	SysEndTime
--2	3	1004	2021-03-13 14:48:30.2702005	2021-03-13 14:51:29.8673014

-- ********** CONCLUSION HERE ***********
--> Only rows that already have data are stored in SYSTEM VERSION TABLE <--



/******** CHECK in TABLE STOCK *******/

SELECT S.* from Containers_stock_tmp as S INNER JOIN [modelo_cont_ppd] as M ON M.id_modelo = S.modelo_cont_ppd_id_modelo 
GO

/****************************************************************************************/
/**************************************3 horas despues***********************************/
/****************************************************************************************/
USE [containers_ppd_test_TR]
GO
-- insertamos un contenedor del modelo que ya hay 4 en stock
INSERT INTO [Mgmt].[contenedor_ppd]
           ([nserie]
           ,[digitoctrl]
           ,[modelo_cont_ppd_id_modelo]
		   ,[estado_cont_ppd_id_estado])
     VALUES
           ('004665'
           ,1
           ,1004, 5)
GO
/*
Modificamos stock del modelo insertado!
Para el modelo 1004 el nuevo Stock es 5
*/

-- TABLAS AHORA
SELECT S.* from Current_stock_ppd as S INNER JOIN [modelo_cont_ppd] as M ON M.id_modelo = S.modelo_cont_ppd_id_modelo where M.id_modelo = 1004;
GO

--id_stock	cantidad	modelo_cont_ppd_id_modelo	SysStartTime				SysEndTime
--2			5			1004						2021-03-13 16:12:20.5875356	9999-12-31 23:59:59.9999999


/*     CHECK HISTORY TABLE (nueva fila)   */
SELECT * FROM dbo.historial_stock_ppd;
GO
--id_stock	cantidad	modelo_cont_ppd_id_modelo	SysStartTime	SysEndTime
--2			3			1004	2021-03-13 14:48:30.2702005	2021-03-13 14:51:29.8673014
--2			4			1004	2021-03-13 14:51:29.8673014	2021-03-13 16:12:20.5875356

/****************************************************************************************/
/**************************************6 horas despues***********************************/
/****************************************************************************************/
USE [containers_ppd_test_TR]
GO
-- insertamos un contenedor del modelo 1004 que ya hay 5 en stock
INSERT INTO [Mgmt].[contenedor_ppd]
           ([nserie]
           ,[digitoctrl]
           ,[modelo_cont_ppd_id_modelo]
		   ,[estado_cont_ppd_id_estado])
     VALUES
           ('100089'
           ,0
           ,1004, 6)
GO
/*
Modificamos stock del modelo insertado!
Para el modelo 1004 el actual Stock es 5

(1 row affected)
Para el modelo 1004 el nuevo Stock es 6
*/

-- TABLAS AHORA
SELECT S.* from Current_stock_ppd as S INNER JOIN [modelo_cont_ppd] as M ON M.id_modelo = S.modelo_cont_ppd_id_modelo where M.id_modelo = 1004;
GO

--id_stock	cantidad	modelo_cont_ppd_id_modelo	SysStartTime				SysEndTime
--2			6			1004						2021-03-13 21:17:43.7922100	9999-12-31 23:59:59.9999999


/*     CHECK HISTORY TABLE (nueva fila)   */
SELECT * FROM dbo.historial_stock_ppd;
GO
--id_stock	cantidad	modelo_cont_ppd_id_modelo	SysStartTime	SysEndTime
--2			3			1004						2021-03-13 14:48:30.2702005	2021-03-13 14:51:29.8673014
--2			4			1004						2021-03-13 14:51:29.8673014	2021-03-13 16:12:20.5875356
--2			5			1004						2021-03-13 16:12:20.5875356	2021-03-13 21:17:43.7922100


-- insertamos un contenedor del modelo 1006 que ya hay 24 en stock

-- TABLAS AHORA
SELECT S.* from Current_stock_ppd as S INNER JOIN [modelo_cont_ppd] as M ON M.id_modelo = S.modelo_cont_ppd_id_modelo where M.id_modelo = 1006;
GO
-- 24 unidades
--id_stock	cantidad	modelo_cont_ppd_id_modelo	SysStartTime				SysEndTime
--3			24			1006						2021-03-13 14:48:30.2702005	9999-12-31 23:59:59.9999999

INSERT INTO [Mgmt].[contenedor_ppd]
           ([nserie]
           ,[digitoctrl]
           ,[modelo_cont_ppd_id_modelo]
		   ,[estado_cont_ppd_id_estado])
     VALUES
           ('1006872'
           ,4
           ,1006, 9)
GO

--Modificamos stock del modelo insertado!
--Para el modelo 1006 el actual Stock es 24

--(1 row affected)
--Para el modelo 1006 el nuevo Stock es 25

--(1 row affected)

/*     CHECK HISTORY TABLE (nueva fila)   */
SELECT * FROM dbo.historial_stock_ppd;
GO
--id_stock	cantidad	modelo_cont_ppd_id_modelo	SysStartTime					SysEndTime
--2			3			1004						2021-03-13 14:48:30.2702005		2021-03-13 14:51:29.8673014
--2			4			1004						2021-03-13 14:51:29.8673014		2021-03-13 16:12:20.5875356
--2			5			1004						2021-03-13 16:12:20.5875356		2021-03-13 21:17:43.7922100
--3			24			1006						2021-03-13 14:48:30.2702005		2021-03-13 21:22:03.7557188

SELECT S.* from Current_stock_ppd as S INNER JOIN [modelo_cont_ppd] as M ON M.id_modelo = S.modelo_cont_ppd_id_modelo where M.id_modelo = 1006;
GO
-- 25 unidades y cambio de SysStartTime de 14:48:30 a 21:22
--id_stock	cantidad	modelo_cont_ppd_id_modelo	SysStartTime				SysEndTime
--3			25			1006						2021-03-13 21:22:03.7557188	9999-12-31 23:59:59.9999999



/**********************************************************************/
--------------- CONSULTAS SOBRE LA TABLA ------------------------------
/**********************************************************************/
-- CONSULTAR TODOS LOS VALORES DE LA TABLA EN EL TIEMPO
SELECT *
FROM Current_stock_ppd
FOR SYSTEM_TIME ALL
GO

--id_stock	cantidad	modelo_cont_ppd_id_modelo	SysStartTime					SysEndTime
--1			12			1002						2021-03-13 14:48:30.2702005		9999-12-31 23:59:59.9999999  <-- valor actual hasta 9999
--2			6			1004						2021-03-13 21:17:43.7922100		9999-12-31 23:59:59.9999999  <-- valor actual
--3			25			1006						2021-03-13 21:22:03.7557188		9999-12-31 23:59:59.9999999  <-- valor actual
--4			1			1005						2021-03-13 14:55:57.4578273		9999-12-31 23:59:59.9999999  <-- valor actual
--2			3			1004						2021-03-13 14:48:30.2702005		2021-03-13 14:51:29.8673014  <-- valor de  14:48 a 14:51
--2			4			1004						2021-03-13 14:51:29.8673014		2021-03-13 16:12:20.5875356  <-- valor de  14:51 a 16:12
--2			5			1004						2021-03-13 16:12:20.5875356		2021-03-13 21:17:43.7922100  <-- valor de  16:12 a 21:17
--3			24			1006						2021-03-13 14:48:30.2702005		2021-03-13 21:22:03.7557188  <-- valor de  14:48 a 21:22


SELECT *
FROM historial_stock_ppd
FOR SYSTEM_TIME ALL
GO
-- Temporal historic tables cannot be queried with the past values
--Msg 13544, Level 16, State 2, Line 365
--Temporal FOR SYSTEM_TIME clause can only be used with system-versioned tables. 'containers_ppd_test_TR.dbo.historial_stock_ppd' is not a system-versioned table.


-- Con “for system_time as of” vemos el estado del stock en un determinado punto en el tiempo.

SELECT id_stock,	cantidad,modelo_cont_ppd_id_modelo as modelo,SysStartTime,SysEndTime
FROM Current_stock_ppd
FOR SYSTEM_TIME AS OF '2021-03-13 22:48:30'
GO

--id_stock	cantidad	modelo	SysStartTime				SysEndTime
--1			12			1002	2021-03-13 14:48:30.2702005	9999-12-31 23:59:59.9999999 
--4			1			1005	2021-03-13 14:55:57.4578273	9999-12-31 23:59:59.9999999
--2			5			1004	2021-03-13 16:12:20.5875356	2021-03-13 21:17:43.7922100 <-- habia 5 y ahora despues de 21:17 hay 6
--3			24			1006	2021-03-13 14:48:30.2702005	2021-03-13 21:22:03.7557188 <-- habia 24 y ahora despues de 21:22 hay 25

-- Con [FOR SYSTEM_TIME FROM 'fecha' TO 'fecha'] vemos los cambios del stock en un determinado intervalo de tiempo
SELECT *
FROM Current_stock_ppd
FOR SYSTEM_TIME FROM '2021-03-13 14:48:30' TO '2021-03-13 18:48:30'
GO

--id_stock	cantidad	modelo	SysStartTime				SysEndTime
--1			12			1002	2021-03-13 14:48:30.2702005	9999-12-31 23:59:59.9999999
--4			1			1005	2021-03-13 14:55:57.4578273	9999-12-31 23:59:59.9999999
--2			3			1004	2021-03-13 14:48:30.2702005	2021-03-13 14:51:29.8673014
--2			4			1004	2021-03-13 14:51:29.8673014	2021-03-13 16:12:20.5875356
--2			5			1004	2021-03-13 16:12:20.5875356	2021-03-13 21:17:43.7922100
--3			24			1006	2021-03-13 14:48:30.2702005	2021-03-13 21:22:03.7557188