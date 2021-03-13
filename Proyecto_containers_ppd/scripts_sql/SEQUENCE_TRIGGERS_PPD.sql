/* OWNER PEREZ PONTE DIEGO*/

/*********************************************************************************************/
/************************************  trg_models_insert    **********************************/
/*********************************************************************************************/
/* 
	WE WILL CHECK WHEN INSERT A NEW CONTAINER and ASSING DIMENSIONS 
	ACCORDING THE MODEL OF THE CONTAINER INSERTED
*/

/* THIS TRIGGER EXECUTES DIFFERENT INSERT SENTENCES DEPENDIGN ON WHAT WE INSERT*/
USE [containers_ppd_test_TR];
GO

DROP TABLE IF EXISTS Models;
GO

SELECT [modelo],[tara] INTO Models
	FROM [dbo].[modelo_cont_ppd]
GO 

SELECT * FROM Models;
GO

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

/* We need to have the model name of the container starting with a number*/
 DROP TRIGGER IF EXISTS trg_models_insert;
 GO
 CREATE OR ALTER TRIGGER trg_models_insert
 ON Models
 INSTEAD OF INSERT
 AS
 BEGIN
	IF EXISTS (
		SELECT [modelo] from INSERTED
		WHERE LEFT([modelo],6) = 'VEINTE' OR LEFT([modelo],8) = 'CUARENTA'
		)
		BEGIN
			PRINT 'Modificamos modelo para insertar!';
			SELECT * FROM INSERTED;
			INSERT INTO Models
				([modelo],[tara] )
			 
					SELECT REPLACE(REPLACE([modelo],'CUARENTA','40'),'VEINTE','20'),[tara]
					FROM INSERTED;
		END
	ELSE
		BEGIN
			PRINT 'Insertamos sin mas el modelo de contenedor!'
			SELECT * FROM INSERTED;
			INSERT INTO Models
				([modelo],[tara])
			 
					SELECT [modelo],[tara]
					FROM INSERTED;
		END
 END 


USE [containers_ppd_test_TR]
GO

INSERT INTO [dbo].[Models]
           ([modelo]
           ,[tara])
     VALUES
           ('20 FEET TOP OPEN MODEL NEW',2000)
GO

-- prints from inserted
--modelo	tara
--20 FEET TOP OPEN MODEL NEW	2000
--messages
--Insertamos sin mas el modelo de contenedor!

--(1 row affected)

--(1 row affected)

--(1 row affected)


-- try to insert following the patern

INSERT INTO [dbo].[Models]
           ([modelo]
           ,[tara])
     VALUES
           ('VEINTE FEET TOP OPEN MODEL NEW',2800)
GO

-- print from inserted
--modelo	tara
--VEINTE FEET TOP OPEN MODEL NEW	2800
-- messages
--Modificamos modelo para insertar!

--(1 row affected)

--(1 row affected)

--(1 row affected)

/* RESULT IN THE TABLE*/

SELECT * FROM Models WHERE modelo LIKE '%NEW%'
GO
/* both was inserted with 20 in number to follow the model pattern on the containers*/
--modelo	tara
--20 FEET TOP OPEN MODEL NEW	2000
--20 FEET TOP OPEN MODEL NEW	2800

-- try with CUARENTA



INSERT INTO [dbo].[Models]
           ([modelo]
           ,[tara])
     VALUES
           ('CUARENTA FEET TOP OPEN MODEL 2021',2800)
GO


SELECT * FROM Models WHERE modelo LIKE '%2021%'
GO

-- result inserted find by 2021 was replaced
--modelo	tara
--40 FEET TOP OPEN MODEL 2021	2800

INSERT INTO [dbo].[Models]
           ([modelo]
           ,[tara])
     VALUES
           ('cuarenta FEET TOP OPEN MODEL NEW 2021',2800)
GO

/* IT works both UPPER and LOWER CASE strings*/

--Modificamos modelo para insertar!

--(1 row affected)

--(1 row affected)

--(1 row affected)

--(2 rows affected)

SELECT * FROM Models WHERE modelo LIKE '%2021%'
GO
--40 FEET TOP OPEN MODEL 2021	2800
--40 FEET TOP OPEN MODEL NEW 2021	2800

/*********************************************************************************************/
/************************************trg_increase_stock_on_order*******************************/
/*********************************************************************************************/

/* WE WILL INCREASE THE STOCK OF CONTAINERS WE HAVE IN STOCK
 EACH TIME A NEW CONTAINER COMES TO OFFICE AND IS INSERTED*/

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

USE [containers_ppd_test_TR];
GO

DROP TABLE IF EXISTS [containers_ppd_test_TR].[dbo].Containers_stock_tmp;
GO


SELECT * INTO [containers_ppd_test_TR].[dbo].Containers_stock_tmp
	FROM [containers_ppd_test].[Mgmt].[stock_ppd]
GO 


USE [containers_ppd_test_TR];
GO

SELECT *  FROM Containers_stock_tmp;
GO
/* stcck we have now */
--id_stock	cantidad	modelo_cont_ppd_id_modelo
--1006		12			1002
--1007		3			1004
--1008		24			1006


SELECT DB_NAME();
GO

/* We select the stock id to increase or insert a new one*/
DROP TRIGGER IF EXISTS trg_increase_stock_on_order;
GO
IF OBJECT_ID ('trg_increase_stock_on_order', 'TR') IS NOT NULL
  DROP TRIGGER trg_increase_stock_on_order
GO
CREATE OR ALTER TRIGGER trg_increase_stock_on_order
ON [Mgmt].[contenedor_ppd]
FOR INSERT
AS
BEGIN
	DECLARE @result VARCHAR(200);
	DECLARE @stockID INT;
	DECLARE @stockQt INT;
	SELECT @stockID = S.id_stock, @stockQt = S.cantidad from Containers_stock_tmp as S INNER JOIN 
			[modelo_cont_ppd] as M ON M.id_modelo = S.modelo_cont_ppd_id_modelo 
			WHERE S.modelo_cont_ppd_id_modelo = (SELECT  [modelo_cont_ppd_id_modelo] FROM INSERTED)
	PRINT @stockID ;
	PRINT @stockQt ;
	IF @stockID > 0
		BEGIN
			PRINT 'Modificamos stock del modelo insertado!';
			SELECT  @result = CONCAT('Para el modelo ',modelo_cont_ppd_id_modelo, ' el actual Stock es ', cantidad) from Containers_stock_tmp 
				WHERE id_stock = @stockID;
			PRINT @result;
			-- update the stock
			UPDATE Containers_stock_tmp SET cantidad = cantidad + 1
				WHERE id_stock = @stockID
			-- show new stock
			SELECT @result = CONCAT('Para el modelo ',modelo_cont_ppd_id_modelo, ' el nuevo Stock es ', cantidad) from Containers_stock_tmp
				WHERE id_stock = @stockID;
			PRINT @result;
			--ROLLBACK TRAN
		END
	ELSE
		BEGIN
			PRINT 'Insertamos 1 unidad de stock del nuevo modelo de contenedor insertado!'
			INSERT INTO Containers_stock_tmp ([cantidad],[modelo_cont_ppd_id_modelo])
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

SELECT S.* from Containers_stock_tmp as S INNER JOIN [modelo_cont_ppd] as M ON M.id_modelo = S.modelo_cont_ppd_id_modelo 
GO
-- insertamos un contenedor del modelo que ya hay stock
INSERT INTO [Mgmt].[contenedor_ppd]
           ([nserie]
           ,[digitoctrl]
           ,[modelo_cont_ppd_id_modelo]
		   ,[estado_cont_ppd_id_estado])
     VALUES
           ('33564'
           ,2
           ,1006, 8)
GO
/* RESULTADO
1002
25
Modificamos stock del modelo insertado!
Para el modelo 1006 el actual Stock es 24

(1 row affected)
Para el modelo 1006 el nuevo Stock es 25

(1 row affected)
*/


-- insertamos un contenedor del modelo que NO hay stock
INSERT INTO [Mgmt].[contenedor_ppd]
           ([nserie]
           ,[digitoctrl]
           ,[modelo_cont_ppd_id_modelo]
		   ,[estado_cont_ppd_id_estado])
     VALUES
           ('124457'
           ,1
           ,1005, 8)
GO
/* RESULTADO

Insertamos 1 unidad de stock del nuevo modelo de contenedor insertado!

(1 row affected)
Para el modelo 1005 tenemos ahora 1 disponible en stock

(1 row affected)
*/

-- resultado
SELECT S.* from Containers_stock_tmp as S INNER JOIN [modelo_cont_ppd] as M ON M.id_modelo = S.modelo_cont_ppd_id_modelo 
GO


/******** CHECK in TABLE STOCK *******/

SELECT S.* from Containers_stock_tmp as S INNER JOIN [modelo_cont_ppd] as M ON M.id_modelo = S.modelo_cont_ppd_id_modelo 
GO

-- CONCLUSIONES
-- TABLA STOCK DE CONTENEDORES
/******** CHECK in TABLE Containers_stock_tmp *******/
-- una unidad mas en el ID 1002
-- nuevo stock con ID 1003
/*
id_stock	cantidad	modelo_cont_ppd_id_modelo
1000		12			1002
1001		3			1004
1002		25			1006
1003		1			1005
*/

-- TABLA CONTENEDORES
/******** CHECK in TABLE [Mgmt].[contenedor_ppd] *******/

SELECT * FROM [Mgmt].[contenedor_ppd];
GO
/* nuevo contenedores 1012 y 1013 */
--id_contenedor	nserie	digitoctrl	modelo_cont_ppd_id_modelo	estado_cont_ppd_id_estado
--1008			33564	2			1006						8
--1009			33564	2			1006						8
--1010			124457	1			1005						8
--1011			33564	2			1006						8
--1012			124457	1			1005						8
--1013			33564	2			1006						8
