
-- ORDEN PARA REALIZAR AUDITORIAS

-- SECURITY						(TANTO PARA SERVIDOR COMO PARA BD)
--			AUDIT
--				SERVER AUDIT SPECIFICATIONS

-- Creacion de las auditorias (a nivel de servidor)

--	Application.log (La captura va al visor de sucesos Aplications)
--	Security.log	(La captura va a  al visor de sucesos Security)
--	File			(La captura va a un fichero)

--Creación de application log

use master
go
create server audit [AppLog_Audits]
	to application_log
with
( queue_delay = 1000,
  on_failure = fail_operation
)
go

-- VER RESULTADO EN GUI SECURITY -> AUDIT

-- Enable GUI or SCRIPT

-- Creación de security log
-- podemos tambien crearla desde el entorno grafico.
-- por ejemplo, en lugar de ejecutar el siguiente script, lo haremos desde el entorno grafico

use master
go
create server audit [Securitylog_audits]
	to security_log
with
( queue_delay = 1000,
  on_failure = continue
)
go

-- Enable GUI

-- Creación de FILE
-- HINT : FOLDER  c:\auditoria\

use master
go
create server audit [Filelog_audits]
to file 
(   filepath = 'c:\auditoria\'
	,maxsize = 0 mb
	,max_rollover_files = 2147483647
	,reserve_disk_space = off
)
with
( queue_delay = 1000,
  on_failure = continue
)
go

-- VER GUI
--		AUDITS
--			3 TIPOS

-- HABILITAR ENABLE ON

ALTER SERVER AUDIT Filelog_audits WITH (STATE = ON) 
GO

-- Or Enable from GUI

-- Creación de especificación de auditoría de SERVIDOR para: Filelog_Audits
-- GUI SERVER AUDIT SPECIFICATIONS

use master
go
create server audit specification [InstanceAuditsFile]
for server audit [FileLog_Audits]
	add (server_state_change_group),
	add(backup_restore_group),
	add (dbcc_group)
with (state = on)
go
-- GUI -> server audit specification -> [InstanceAuditsFile] -> PROPERTIES -> AUDIT ACTION TYPE

-- Comprobamos que esten habilitadas las Auditorias y las Especificaciones
-- Provocamos uno de los eventos indicados en la especificación de auditoría del servidor.


-- Try It Out

-- Por ejemplo el del Backup de la base de datos: Pubs (AUDIT ACTION TYPE)

use master
go
backup database pubs
	to disk = 'c:\auditoria\Pubs.bak'
	with init;
go

-- Check the current database (AUDIT ACTION TYPE)    
DBCC CHECKDB;    
GO    
-- Check the AdventureWorks2017 database without nonclustered indexes (AUDIT ACTION TYPE)    
DBCC CHECKDB (AdventureWorks2017, NOINDEX);    
GO    

--Para ver los registros de una auditoría con salida a un archivo:
SELECT *
	FROM sys.fn_get_audit_file ('C:\Auditoria\*',default,default);
GO

-- Por ejemplo el del Backup de mi base de datos: AdventureWorks2014
use master
go
backup database AdventureWorks2017
	to disk = 'c:\Auditoria\AdventureWorks2017.bak'
	with init;
go


--Para ver los registros de una auditoría con salida a un archivo:
SELECT *
	FROM sys.fn_get_audit_file ('C:\Auditoria\*',default,default);
GO

-- EN GUI VER Audit [Filelog_audits] ...............View Audit Logs


------------------------------------------------------------------------------
-- Creacion de especificacion a nivel de bases de datos

USE AdventureWorks2017
GO
DROP TABLE IF EXIsTS [HumanResources].[Departamento]
GO
SELECT * 
INTO [HumanResources].[Departamento]
FROM [HumanResources].[Department]
GO

SELECT * FROM [HumanResources].[DepartamentO]
go


-- EN GUI

-- [AdventureWorks2017] -> SECURITY -> DATABASE AUDIT SPECIFICATIONS

-- Database Audit Spacifications

CREATE DATABASE AUDIT SPECIFICATION [Auditoria Department de AdventureWorks2017]
FOR SERVER AUDIT [Filelog_audits]
ADD (SELECT ON OBJECT::[HumanResources].[Department] BY [dbo]),
ADD (INSERT ON OBJECT::[HumanResources].[Department] BY [dbo]),
ADD (UPDATE ON OBJECT::[HumanResources].[Department] BY [dbo]),
ADD (DELETE ON OBJECT::[HumanResources].[Departamento] BY [dbo])
GO


ALTER DATABASE AUDIT SPECIFICATION [Auditoria Department de AdventureWorks2017]
WITH (STATE = ON) 
GO
--  GUI
-- [Auditoria Department de AdventureWorks2017]-> PROPERTIES

-- PROBANDO :
-- Realizamos una consulta

USE AdventureWorks2017
GO

SELECT * FROM [HumanResources].[Department]
GO

-- Realizamos un borrado

DELETE [HumanResources].[Departamento]
WHERE Name LIKE 'P%'
GO
--(3 rows affected)

--Para ver los registros de una auditoría con salida a un archivo:

SELECT *
	FROM sys.fn_get_audit_file ('C:\Auditoria\*.sqlaudit',default,default);
GO

-- ver acciones desde GUI
-- SECURITY -> AUDITS -> FILELOG_AUDITS

ALTER DATABASE AUDIT SPECIFICATION [Auditoria Department de AdventureWorks2017]
WITH (STATE = OFF) 
GO

DROP DATABASE AUDIT SPECIFICATION [Auditoria Department de AdventureWorks2017]
GO
------------------------------------------



-- Lo mismo pero con otra Audit

-- From [AdventureWorks2017]
--Msg 33074, Level 16, State 1, Line 168
--Cannot create a server audit from a user database. This operation must be performed in the master database.

Use master
Go
create server audit [Filelog_audits_database]
to file 
(   filepath = 'c:\auditoriadatabase\'
	,maxsize = 0 mb
	,max_rollover_files = 2147483647
	,reserve_disk_space = off
)
with
( queue_delay = 1000,
  on_failure = continue
)
go

ALTER SERVER AUDIT [Filelog_audits_database] WITH (STATE = ON) 
GO

USE AdventureWorks2017
GO
DROP TABLE IF EXIsTS [HumanResources].[Departamento]
GO
SELECT * 
INTO [HumanResources].[Departamento]
FROM [HumanResources].[Department]
gO

SELECT * FROM [HumanResources].[DepartamentO]
go
-- database audit spacifications

CREATE DATABASE AUDIT SPECIFICATION [Auditoria Department de AdventureWorks2017 otra]
FOR SERVER AUDIT [Filelog_audits_database]
ADD (SELECT ON OBJECT::[HumanResources].[Department] BY [dbo]),
ADD (INSERT ON OBJECT::[HumanResources].[Department] BY [dbo]),
ADD (UPDATE ON OBJECT::[HumanResources].[Departamento] BY [dbo]),
ADD (DELETE ON OBJECT::[HumanResources].[Departamento] BY [dbo])
GO


ALTER DATABASE AUDIT SPECIFICATION [Auditoria Department de AdventureWorks2017 otra]
WITH (STATE = ON) 
go
USE AdventureWorks2017
GO

SELECT * FROM [HumanResources].[Department]
GO
DELETE [HumanResources].[Departamento]
WHERE Name LIKE 'E%'
GO

-- (2 rows affected)


UPDATE [HumanResources].[Departamento]
set NAME = 'administrador asib'
WHERE NAME LIKE 'F%'
go

-- (2 rows affected)


--Para ver los registros de una auditoría con salida a un archivo:

SELECT *
	FROM sys.fn_get_audit_file ('C:\Auditoriadatabase\*.sqlaudit',default,default);
GO

USE MASTER
go

ALTER DATABASE AUDIT SPECIFICATION [Auditoria Department de AdventureWorks2017 otra]
WITH (STATE = OFF) 
GO

DROP DATABASE AUDIT SPECIFICATION [Auditoria Department de AdventureWorks2017 otra]
GO

ALTER SERVER AUDIT Filelog_audits WITH (STATE = OFF) 
GO

ALTER SERVER AUDIT [Filelog_audits_database] WITH (STATE = OFF) 
GO


DROP SERVER AUDIT Filelog_audits
go

DROP SERVER AUDIT Filelog_audits_database
go





----------------------------------------




-- https://www.mssqltips.com/sqlservertip/4330/sql-server-2016-auditing-improvements/


USE [master]
GO

CREATE SERVER AUDIT [Audit_User_Defined_Test]
TO FILE 
( FILEPATH = 'C:\Audit'
 ,MAXSIZE = 100 MB
 ,MAX_ROLLOVER_FILES = 2147483647
 ,RESERVE_DISK_SPACE = OFF
)
WITH
( QUEUE_DELAY = 1000
 ,ON_FAILURE = CONTINUE
)
GO

Alter Server Audit [Audit_User_Defined_Test] with(State=ON)
GO


Use AdventureWorks2017
GO

Create Database Audit Specification Test_database_audit
for server audit [Audit_User_Defined_Test]
ADD (User_Defined_Audit_Group)
With(State=ON)
GO

-- We can see that the Audit action type is set to User_Defined_Audit_Group which basically tracks events raised by the sp_audit_write stored procedure.

-- Trigger to write an audit record using sp_audit_write
-- Suppose we want to audit the Adventureworks database table [Production].[ProductListPriceHistory] which is used to store the price of all the products and their history records. Sales people previously modify the price of the products based on the requirements however we want to audit if anyone has reduced the price by more than 20%.


-- Now we will write a trigger to check this condition and write the data to audit files.

Create Trigger [Production].[ProductListPrice] 
on [Production].[ProductListPriceHistory]
After Update
As
declare @OldListPrice money
,@NewListPrice money,
@productId int,
@msg nvarchar(2500)
select @OldListPrice=d.ListPrice
from deleted d
select @NewListPrice= i.ListPrice , @productId=i.ProductId
from inserted i

If (@OldListPrice*0.80 >@NewListPrice)  -- implement logic condition
begin
 Set @msg='Product '+ Cast (@productid as varchar(50))+' ListPrice is decreased by more than 20%' --print message to be logged
 Exec sp_audit_write @user_defined_event_id=27,
 @succeeded =1, 
 @user_defined_information = @msg;
End
GO

-- Now we will update the price of the product and see if this is logged into the events

SELECT TOP 3 * FROM [Production].[ProductListPriceHistory]
GO

SELECT  * 
FROM [Production].[ProductListPriceHistory]
WHERE  [ProductID] = 741
GO

--ProductID	StartDate	EndDate			ListPrice		ModifiedDate
--741	2011-05-31 	   2012-05-29 		1364.50			2012-05-29 

UPDATE [Production].[ProductListPriceHistory]
SET ListPrice = 1333
WHERE  [ProductID] = 741
GO
-- (1 row(s) affected)


-- Trigger Launched 20%

UPDATE [Production].[ProductListPriceHistory]
SET ListPrice = 1000
WHERE  [ProductID] = 741
GO


-- (1 row(s) affected)

-- Now if we go to View audit logs in SQL Server Management Studio under 
-- Security->Audit->Audit_User_Defined_Test, we can see the price changed meet our trigger condition and it is recorded in Audit logs.

-- funciona este
SELECT * FROM sys.fn_get_audit_file('C:\Audit\*', NULL, NULL);
GO

--Para ver los registros de una auditoría con salida a un archivo:
SELECT *
	FROM sys.fn_get_audit_file ('C:\Audit\*.sqlaudit',default,default);
GO

SELECT *
	FROM sys.fn_get_audit_file ('C:\Audito\*.sqlaudit',default,default);
GO


SELECT TOP 10
        action_id ,
        name
FROM    sys.dm_audit_actions;
GO