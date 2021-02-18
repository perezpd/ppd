--STORED PROCEDURE FUNCTION TRIGGER
-- Something that creates a reaction in the database
-- It is a stored procedure that is executed after some actions
-- like:
-- UPDATE, INSERT, DROP TABLE
-- ACTIONS :
--  * ENABLE / DISABLE
-- Trigger Levels Clasification:
--  * Server
--  * Database
--  * Table or view:
--      # AFTER
--      # INSTEAD OF
--Triggers

USE MASTER;
GO

IF (OBJECT_ID('TRG_AvoidLoginCreation') IS NOT NULL)
DISABLE TRIGGER TRG_AvoidLoginCreation ON ALL SERVER
GO

IF (OBJECT_ID('TRG_AvoidLoginCreation') IS NOT NULL)
DROP TRIGGER TRG_AvoidLoginCreation ON ALL SERVER  ;
GO

-- disable new logins creation on te SQL instance
CREATE OR ALTER TRIGGER TRG_AvoidLoginCreation
ON ALL SERVER -- SERVER LEVEL
FOR CREATE_LOGIN -- sentence to control
AS
	PRINT 'Login creation FORBIDDEN, please contact the DBA'
	ROLLBACK TRAN;
GO

ENABLE TRIGGER TRG_AvoidLoginCreation ON ALL SERVER
GO

CREATE LOGIN Josuah WITH PASSWORD='Adfg2398';
GO

------Login creation FORBIDDEN, please contact the DBA
------Msg 3609, Level 16, State 2, Line 31
------The transaction ended in the trigger. The batch has been aborted.

-- where in object explorer
-- INSTANCE > Server Objects > Triggers

-- TRIGGER ON DB LEVEL ---
-- CONTROL TABLE CREATION FOR DROP
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

-- check Autores
SELECT * FROM Autores;


IF (OBJECT_ID('TRG_AvoidTableDrop','TR') IS NOT NULL)
	DISABLE TRIGGER TRG_AvoidTableDrop ON DATABASE
GO

-- this does not work on transact-SQL
IF (OBJECT_ID('TRG_AvoidTableDrop','TR') IS NOT NULL)
	DROP TRIGGER TRG_AvoidTableDrop ON DATABASE;
GO

-- disable DROP table on DATABASE
CREATE OR ALTER TRIGGER TRG_AvoidTableDrop
ON DATABASE -- DATABASE LEVEL
FOR DROP_TABLE, ALTER_TABLE -- sentence to control
AS
	RAISERROR( 'DROP Table FORBIDDEN, please contact the DBA!',16,8)
	ROLLBACK TRAN;
GO

-- check drop table action
IF (OBJECT_ID('TRG_AvoidTableDrop','TR') IS NOT NULL)
	ENABLE TRIGGER TRG_AvoidTableDrop ON DATABASE
GO
IF OBJECT_ID('Autores','U') IS NOT NULL
    DROP TABLE Autores;
GO

----Msg 50000, Level 16, State 8, Procedure TRG_AvoidTableDrop, Line 5 [Batch Start Line 88]
----DROP Table FORBIDDEN, please contact the DBA!
----Msg 3609, Level 16, State 2, Line 90
----The transaction ended in the trigger. The batch has been aborted.


-- TRIGGER ON TABLE LEVEL ---
-- CONTROL TABLE INSERT OR UPDATE
USE Pubs;
GO

DROP TABLE IF EXISTS Autores;
GO

SELECT [au_id],[au_lname],[phone],[address] INTO Autores
	FROM Authors;
GO

---- check Autores
SELECT * FROM Autores;

-- disable DROP table on DATABASE
CREATE OR ALTER TRIGGER TRG_TableModifyNOtification
ON Autores -- TAble LEVEL
	AFTER INSERT , UPDATE -- sentences to control
AS
	RAISERROR( 'INSERT or UPDATE TABLE in Table Autores Was DONE!',16,8)
	EXEC sp_helpdb pubs;
GO


INSERT INTO [dbo].[Autores]
			([au_id],[au_lname],[phone],[address])
     VALUES
           ('111111111','Johnny'
           ,'1236459871'
           ,'Calle Paciencia, 45')
GO

----Msg 50000, Level 16, State 8, Procedure TRG_TableModifyNOtification, Line 5 [Batch Start Line 124]
----INSERT or UPDATE TABLE in Table Autores Was DONE!
 

----(1 row affected)
USE [pubs]
GO

UPDATE [dbo].[Autores]
   SET 
      [phone] = '999666999'
 WHERE [au_id] = '111111111'
GO


----Msg 50000, Level 16, State 8, Procedure TRG_TableModifyNOtification, Line 5 [Batch Start Line 139]
----INSERT or UPDATE TABLE in Table Autores Was DONE!
 
----(1 row affected)
-- cHECK
SELECT * FROM Autores WHERE [au_id] = '111111111';
GO
----au_id	au_lname	phone	address
----111111111	Johnny	999666999   	Calle Paciencia, 45

-- table level 

CREATE OR ALTER TRIGGER TRG_ModificationFeedback
ON Autores -- TAble LEVEL
	FOR DELETE , UPDATE -- sentences to control
AS
	RAISERROR( ' %d INSERT or UPDATE TABLE in Table Autores Was DONE!',16,1, @@rowcount)
	EXEC sp_helpdb pubs;
GO

-- cHECK
SELECT * FROM Autores WHERE [au_id] = '111111111';
GO
--111111111	Johnny	999666999   	Calle Paciencia, 45

UPDATE [dbo].[Autores]
   SET 
      [phone] = '33333333'
 WHERE [au_id] = '111111111'
GO

----Msg 50000, Level 16, State 8, Procedure TRG_TableModifyNOtification, Line 5 [Batch Start Line 172]
----INSERT or UPDATE TABLE in Table Autores Was DONE!
 
----Msg 50000, Level 16, State 1, Procedure TRG_ModificationFeedback, Line 5 [Batch Start Line 172]
---- 1 INSERT or UPDATE TABLE in Table Autores Was DONE!
 
----(1 row affected)
-- cHECK
SELECT * FROM Autores WHERE [au_id] = '111111111';
GO
-- 111111111	Johnny	33333333    	Calle Paciencia, 45



