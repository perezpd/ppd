
USE Pubs;
GO
IF OBJECT_ID('Autores','U') IS NOT NULL
    DROP TABLE Autores;
GO

DROP TABLE IF EXISTS Autores;
GO

SELECT * INTO Autores
FROM Authors;
GO
--Creamos el trigger (el FOR AFTER, no es necesario, llega con poner FOR)
--IF OBJECT_ID('trg_PreveniBorrado', 'TR') IS NOT NULL
--	DROP TRIGGER trg_PreveniBorrado
--GO

--DROP TRIGGER IF EXISTS trg_PreveniBorrado
--GO
IF OBJECT_ID ('trg_update_city', 'TR') IS NOT NULL
  DROP TRIGGER trg_update_city
GO
CREATE OR ALTER TRIGGER trg_update_city
ON Autores -- SERVER LEVEL
FOR UPDATE -- sentence to control
AS
    IF UPDATE (city)
		BEGIN
			RAISERROR ('No puedes cambiar la ciudad', 16,1) 
			ROLLBACK TRAN
		END
	ELSE
		PRINT 'Operacion correcta'
GO

SELECT * FROM Autores;
GO
--au_id	au_lname	au_fname	phone	address	city	state	zip	contract
--213-46-8915	Updated Lname	Marjorie	415 986-7020	309 63rd St. #411	Oakland	CA	94618	1
--238-95-7766	Carson	Cheryl	415 548-7723	589 Darwin Ln.	Berkeley	CA	94705	1
--267-41-2394	O'Leary	Michael	408 286-2428	22 Cleveland Av. #14	San Jose	CA	95128	1


sp_help trg_PreveniBorrado
GO

UPDATE Autores 
SET [au_lname] = 'Updated Lname Again'
WHERE [au_id] = '213-46-8915';
GO

/*
Tabla inserted

(1 row affected)
Tabla deleted

(1 row affected)
Operacion correcta

(1 row affected)
*/


UPDATE Autores 
SET city = 'Toronto'
WHERE [au_id] = '213-46-8915';
GO

/* Messages
Tabla inserted

(1 row affected)
Tabla deleted

(1 row affected)
Msg 50000, Level 16, State 1, Procedure trg_update_city, Line 7 [Batch Start Line 65]
No puedes cambiar la ciudad
Msg 3609, Level 16, State 1, Line 66
The transaction ended in the trigger. The batch has been aborted.
*/



  -- prevenir actualizar un campo con UPDATE
  USE [AdventureWorks2017]

  SELECT * INTO DEPARTAMENTO
  FROM [HumanResources].[Department]
  GO

    SELECT * FROM DEPARTAMENTO

/*
DepartmentID	Name	GroupName	ModifiedDate
1	Engineering	Research and Development	2008-04-30 00:00:00.000
2	Tool Design	Research and Development	2008-04-30 00:00:00.000
3	Sales	Sales and Marketing	2008-04-30 00:00:00.000
4	Marketing	Sales and Marketing	2008-04-30 00:00:00.000
5	Purchasing	Inventory Management	2008-04-30 00:00:00.000
6	Research and Development	Research and Development	2008-04-30 00:00:00.000
7	Production	Manufacturing	2008-04-30 00:00:00.000
8	Production Control	Manufacturing	2008-04-30 00:00:00.000
9	Human Resources	Executive General and Administration	2008-04-30 00:00:00.000
10	Finance	Executive General and Administration	2008-04-30 00:00:00.000
11	Information Services	Executive General and Administration	2008-04-30 00:00:00.000
12	Document Control	Quality Assurance	2008-04-30 00:00:00.000
13	Quality Assurance	Quality Assurance	2008-04-30 00:00:00.000
14	Facilities and Maintenance	Executive General and Administration	2008-04-30 00:00:00.000
15	Shipping and Receiving	Inventory Management	2008-04-30 00:00:00.000
16	Executive	Executive General and Administration	2008-04-30 00:00:00.000
*/


IF OBJECT_ID ('trg_dept_update_groupname', 'TR') IS NOT NULL
  DROP TRIGGER trg_dept_update_groupname
GO
CREATE OR ALTER TRIGGER trg_dept_update_groupname
ON DEPARTAMENTO -- TABLE LEVEL
FOR UPDATE -- sentence to control
AS
    IF UPDATE (GroupName)
		BEGIN
			RAISERROR ('No puedes cambiar el grupo', 16,1) 
			ROLLBACK TRAN
		END
	ELSE
		PRINT 'Operacion correcta cambio de grupo'
GO

SELECT * FROM DEPARTAMENTO;
GO


UPDATE DEPARTAMENTO 
SET GroupName = 'TorontoGRP'
WHERE DepartmentID = '1';
GO

--Msg 50000, Level 16, State 1, Procedure trg_dept_update_groupname, Line 7 [Batch Start Line 135]
--No puedes cambiar el grupo
--Msg 3609, Level 16, State 1, Line 136
--The transaction ended in the trigger. The batch has been aborted.


SELECT * FROM DEPARTAMENTO WHERE DepartmentID=1
GO
--DepartmentID	Name	GroupName	ModifiedDate
--1	Engineering	Research and Development	2008-04-30 00:00:00.000

UPDATE DEPARTAMENTO 
SET Name = 'Senior Engineering'
WHERE DepartmentID = '1';
GO

--Operacion correcta cambio de grupo

--(1 row affected)

SELECT * FROM DEPARTAMENTO WHERE DepartmentID=1
GO

--DepartmentID	Name	GroupName	ModifiedDate
--1	Senior Engineering	Research and Development	2008-04-30 00:00:00.000


/*  Prevenir que no me deje brrar mas de un registro*/
USE [Northwind];
GO

IF OBJECT_ID ('Empleados', 'U') IS NOT NULL
  DROP TABLE Empleados
GO

SELECT [EmployeeID],[LastName] INTO Empleados
FROM [dbo].[Employees]
GO

SELECT * FROM Empleados;
GO

--EmployeeID	LastName
--5	Buchanan
--8	Callahan
--1	Davolio
--9	Dodsworth
--2	Fuller
--7	King
--3	Leverling
--4	Peacock
--6	Suyama

IF OBJECT_ID ('trg_single_update_empleados', 'TR') IS NOT NULL
  DROP TRIGGER trg_single_update_empleados
GO


CREATE OR ALTER TRIGGER trg_single_update_empleados
ON Empleados -- TABLE LEVEL
FOR DELETE -- sentence to control
AS
	-- PRINT @@ROWCOUNT --
	DECLARE @rowsAffected INT;
	SET @rowsAffected = @@ROWCOUNT;
    IF (@rowsAffected >1)
		BEGIN
			PRINT 'estas intentando borrar '+ CAST(@rowsAffected AS NVARCHAR(100)) + ' Registros'
			RAISERROR ('No se puede borrar más de un registro, estás borrando %d !!!', 16,1,@rowsAffected) 
			ROLLBACK TRAN
		END
	ELSE
		PRINT CAST(@rowsAffected AS NVARCHAR(100)) + 'Un registro si se puede borrar'
GO



DELETE FROM [dbo].[Empleados]
      WHERE EmployeeID = '1'
GO

--Un registro si se puede borrar

--(1 row affected)

/* DELETe ALL*/ 

DELETE FROM [dbo].[Empleados]
GO

--estas intentando borrar 8 Registros
--Msg 50000, Level 16, State 1, Procedure trg_single_update_empleados, Line 11 [Batch Start Line 226]
--No se puede borrar más de un registro, estás borrando 8 !!!
--Msg 3609, Level 16, State 1, Line 228
--The transaction ended in the trigger. The batch has been aborted.

IF OBJECT_ID ('trg_single_delete_empleados', 'TR') IS NOT NULL
  DROP TRIGGER trg_single_delete_empleados
GO
CREATE OR ALTER TRIGGER trg_single_delete_empleados
ON Empleados -- TABLE LEVEL
FOR DELETE -- sentence to control
AS

    IF ( SELECT COUNT(*) FROM deleted) > 1
		BEGIN
			PRINT 'estas intentando borrar mas de un Registro'
			RAISERROR ('No se puede borrar más de un registro !!!', 16,1) 
			ROLLBACK
			RETURN
		END
	ELSE
		PRINT 'Un registro si se puede borrar'
GO

SELECT * FROM Empleados;
GO


DELETE FROM [dbo].[Empleados]
      WHERE EmployeeID = '6' OR EmployeeID = '7'
GO
/* si borro 2*/

--estas intentando borrar mas de un Registro
--Msg 50000, Level 16, State 1, Procedure trg_single_delete_empleados, Line 9 [Batch Start Line 259]
--No se puede borrar más de un registro !!!
--Msg 3609, Level 16, State 1, Line 260
--The transaction ended in the trigger. The batch has been aborted.


DELETE FROM [dbo].[Empleados]
      WHERE EmployeeID = '8'
GO

--Un registro si se puede borrar

--(1 row affected)

/* TRIGGER INSTEAD OF DELETE */

-- USO DE @@ROWCOUNT AND @@TRANCOUNT

-- Instead of delete some row in the DB it do the conde in the rpocedure instead

-- @@TRANCOUNT count the number of active transactions ongoing or pending to do

USE [AdventureWorks2017]
GO

  DROP TABLE IF EXISTS Empleados
GO

SELECT * INTO Empleados
FROM [HumanResources].[Employee]
GO


IF OBJECT_ID ('trg_avoid_delete_empleados_instead', 'TR') IS NOT NULL
  DROP TRIGGER trg_avoid_delete_empleados_instead
GO
CREATE OR ALTER TRIGGER trg_avoid_delete_empleados_instead
ON Empleados -- TABLE LEVEL
INSTEAD OF DELETE -- sentence to control
AS
	DECLARE @rowsAffected INT;
	SET @rowsAffected = @@ROWCOUNT;
    IF @rowsAffected = 0
		RETURN

	BEGIN
		PRINT 'estas intentando actuar sobre empleados y no puedes, solo se puede desactiva'
		RAISERROR ('No se puede actuar sobre más de un registro !!!', 16,1) 
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION
		END;
	END
GO

--toda la tabla
DELETE Empleados
GO

--estas intentando actuar sobre empleados y no puedes, solo se puede desactiva
--Msg 50000, Level 16, State 1, Procedure trg_avoid_delete_empleados_instead, Line 12 [Batch Start Line 320]
--No se puede actuar sobre más de un registro !!!
--Msg 3609, Level 16, State 1, Line 322
--The transaction ended in the trigger. The batch has been aborted.

SELECT * FROM Empleados;
GO

-- no action apply
DELETE FROM [dbo].[Empleados]
      WHERE BusinessEntityID = '388'
GO


--(0 rows affected)