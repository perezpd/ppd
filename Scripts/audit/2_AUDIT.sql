-- CREATE DATABASE AUDIT SPECIFICATION (Transact-SQL)

-- Audit any DML

USE master ;  
GO  
-- Create the server audit.

--Audit any DML (INSERT, UPDATE or DELETE) on all objects in the sales schema for a specific database role

--The following example creates a server audit called 
-- DataModification_Security_Audit and then a database audit specification 
-- called Audit_Data_Modification_On_All_Sales_Tables that audits 
-- INSERT, UPDATE and DELETE statements by users in a new database role SalesUK,
-- for all objects in the Sales schema in the AdventureWorks2017 database.


-- Change the path to a path that the SQLServer Service has access to. 
CREATE SERVER AUDIT DataModification_Security_Audit  
    TO FILE ( FILEPATH = 
'c:\SQLAudit\' ) ;  -- make sure this path exists
GO  
-- Enable the server audit.  
ALTER SERVER AUDIT DataModification_Security_Audit   
WITH (STATE = ON) ;  
GO  
-- Move to the target database.  
USE AdventureWorks2017 ;  
GO  
DROP ROLE IF EXISTS SalesUK
GO
CREATE ROLE SalesUK
GO
GRANT INSERT, UPDATE, DELETE ON SCHEMA::Sales TO SalesUK
GO
DROP USER IF EXISTS COMERCIAL
GO
CREATE USER COMERCIAL WITHOUT LOGIN
GO
ALTER ROLE SalesUK ADD MEMBER COMERCIAL
GO
DROP TABLE IF EXISTS Sales.Tienda
GO
SELECT *
INTO Sales.Tienda
FROM [Sales].[Store]
go
-- Create the database audit specification.  
CREATE DATABASE AUDIT SPECIFICATION Audit_Data_Modification_On_All_Sales_Tables  
FOR SERVER AUDIT DataModification_Security_Audit  
ADD ( INSERT, UPDATE, DELETE  
     ON Schema::Sales BY SalesUK )  
WITH (STATE = ON) ;    
GO  

EXECUTE AS USER ='COMERCIAL'
GO 
DELETE Sales.Tienda
GO
-- (701 rows affected)

REVERT 
GO

--Para ver los registros de una auditoría con salida a un archivo:
SELECT *
	FROM sys.fn_get_audit_file ('c:\SQLAudit\*.sqlaudit',default,default);
GO

SELECT event_time,action_id,database_name,database_principal_name,schema_name,statement
	FROM sys.fn_get_audit_file ('c:\SQLAudit\*.sqlaudit',default,default);
GO

--event_time					action_id	database_name		database_principal_name	schema_name			statement
--2021-04-27 15:21:55.5295419	AUSC				
--2021-04-27 15:30:58.8554724	DL  		AdventureWorks2017	COMERCIAL					Sales	DELETE Sales.Tienda

--------------------------------

-- Audit SELECT and INSERT on a table for any database principal

-- The following example creates a server audit called Payrole_Security_Audit 
-- and then a database audit specification called Payrole_Security_Audit 
-- that audits SELECT and INSERT statements by any member of the public database role,
-- for the HumanResources.EmployeePayHistory table in the AdventureWorks2017 database.
-- This has the effect that every user is audited as every user is always member of the public role.

USE master ;  
GO  
-- Create the server audit.  
CREATE SERVER AUDIT Payrole_Security_Audit  
    TO FILE ( FILEPATH =   
'C:\SQLAudit\' ) ;  -- make sure this path exists
GO  
-- Enable the server audit.  
ALTER SERVER AUDIT Payrole_Security_Audit   
WITH (STATE = ON) ;  
GO  
-- Move to the target database.  
USE AdventureWorks2017 ;  
GO  
-- Create the database audit specification.  
CREATE DATABASE AUDIT SPECIFICATION Audit_Pay_Tables  
FOR SERVER AUDIT Payrole_Security_Audit  
ADD (SELECT , INSERT  
     ON HumanResources.EmployeePayHistory BY public )  
WITH (STATE = ON) ;  
GO  