/* OWNER PEREZ PONTE DIEGO*/
/* THIS PROCEDURE WAS CREATED TO CHECK SINTAXIS WHEN INSERT
	SOME MODEL OF CONTAINERS AUTOMATICALLY TO FOLLOW THE STANDARDS
*/


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