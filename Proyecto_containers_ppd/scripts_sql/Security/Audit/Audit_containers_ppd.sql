  /* OWNER PEREZ PONTE DIEGO*/

/*********************************************************************************************/
/***************	SERVER AUDIT and DATABASE AUDIT SPECIFICATION       **********************/
/*******************               (Transact-SQL)                 ****************************/
/***************   Audit Objects on Schema Mgmt for Role OfficeMgmt    ***********************/
/*********************************************************************************************/

-- CREATE SERVER and DATABASE AUDIT SPECIFICATION (Transact-SQL)

-- Audit any Data Modification Language (DML) only.
-- 'Personal' Role can´t CREATE, ALTER or DROP (DDL) in this database [containers_ppd_test]

-- we will record actions on critical tables 
-- [Mgmt].[stock_ppd]			--> changing stcoks
-- [Mgmt].[contenedor_ppd]		--> changing phisical status description of the container
-- [Mgmt].[estado_cont_ppd]     --> changing description of an status of a container

/* Steps :
  1. Create server audit to a file called 'PPD_Office_Management_Team_file_audit'
  2. Create server audit to a application log called 'PPD_Office_Management_Team_audit_app_log'
  3. Create server audit to a security log called 'PPD_Office_Management_Team_audit_security_log'
  4. Create database audit specification 'PPD_audit_DML_on_Mgmt_Schema' on server audit file for DML performad by Role OfficeMgmt
  5. Create database audit specification 'PPD_audit_app_DML_on_Mgmt_Schema' on server audit application_log for DML performad by Role OfficeMgmt
*/

USE master ;  
GO  
-- Start Audit process for all DML (INSERT, UPDATE or DELETE) on all objects in the [Mgmt] schema 

-- create server audit to file
CREATE SERVER AUDIT PPD_Office_Management_Team_audit  
    TO FILE ( FILEPATH =  'C:\auditoria\PPD_containers_audit' )
	WITH ( QUEUE_DELAY = 1000 ,ON_FAILURE = CONTINUE )
GO  
-- Enable the created server audit.  
ALTER SERVER AUDIT PPD_Office_Management_Team_audit   
	WITH (STATE = ON) ;  
GO 
 
-- create server audit to application log
CREATE SERVER AUDIT PPD_Office_Management_Team_audit_app_log  
    TO APPLICATION_LOG
	WITH ( QUEUE_DELAY = 1000 ,ON_FAILURE = CONTINUE )
GO  
-- Enable it  
ALTER SERVER AUDIT PPD_Office_Management_Team_audit_app_log   
	WITH (STATE = ON) ;  
GO  

-- create server audit to security log
CREATE SERVER AUDIT PPD_Office_Management_Team_audit_security_log  
    TO SECURITY_LOG
	WITH ( QUEUE_DELAY = 1000 ,ON_FAILURE = CONTINUE )
GO  
-- Enable it  
ALTER SERVER AUDIT PPD_Office_Management_Team_audit_security_log   
	WITH (STATE = ON) ;  
GO
/*
we got an error here to write on system security log
Msg 33222, Level 16, State 1, Line 56
Audit 'PPD_Office_Management_Team_audit_security_log' failed to start . For more information, see the SQL Server error log. You can also query sys.dm_os_ring_buffers where ring_buffer_type = 'RING_BUFFER_XE_LOG'.
The origin of the error is regitered on the Event Viewer in Application log
SQL Server Audit failed to access the security log. 
Make sure that the SQL service account has the required permissions to access the security log.
*/


-- IMPORTANT: From here must Proceed only with file and application_log audits


-- Start Doing actions against the Containers database.  
USE containers_ppd_test ;  
GO  

-- Alter Role OfficeMgmt to secure acces to do actions
GRANT SELECT,INSERT, UPDATE, DELETE ON  SCHEMA::Mgmt TO OfficeMgmt;
GO
-- create new tables to test audit before set up on mian database
SELECT *
INTO [Mgmt].[stock_audited_ppd]
FROM [Mgmt].[stock_ppd]
go
--(3 rows affected)
SELECT *
INTO [Mgmt].[container_audited_ppd]
FROM [Mgmt].[contenedor_ppd]
go
--(10 rows affected)

SELECT *
INTO [Mgmt].[container_status_audited_ppd]
FROM [Mgmt].[estado_cont_ppd]
go
--(10 rows affected)

/* *********   DATABASE AUDIT ESPECIFICATION in [containers_ppd_test]  ******/

-- Create the database audit specification associated with server audit to file.  
CREATE DATABASE AUDIT SPECIFICATION PPD_audit_DML_on_Mgmt_Schema  
FOR SERVER AUDIT PPD_Office_Management_Team_audit  
ADD ( INSERT, UPDATE, DELETE  
     ON Schema::Mgmt BY OfficeMgmt )  
WITH (STATE = ON) ;    
GO  
-- Create the database audit specification associated with server audit to application_log.  
CREATE DATABASE AUDIT SPECIFICATION PPD_audit_app_DML_on_Mgmt_Schema  
FOR SERVER AUDIT PPD_Office_Management_Team_audit_app_log  
ADD ( INSERT, UPDATE, DELETE  
     ON Schema::Mgmt BY OfficeMgmt )  
WITH (STATE = ON) ;    
GO  



-- Perform action DELETE as member of Role OfficeMgmt -> EncargadoLuis
EXECUTE ('DELETE Mgmt.container_status_audited_ppd') as user='EncargadoLuis'
GO
-- (10 rows affected)


--To view audit logs output to a file:
SELECT *
	FROM sys.fn_get_audit_file ('C:\auditoria\PPD_containers_audit\*.sqlaudit',default,default);
GO

SELECT event_time,action_id,database_name,database_principal_name,schema_name,statement
	FROM sys.fn_get_audit_file ('C:\auditoria\PPD_containers_audit\*.sqlaudit',default,default);
GO

--event_time					action_id	database_name	database_principal_name	schema_name	statement
--2021-05-30 21:38:36.8933616	AUSC				
--2021-05-30 21:45:51.7534989	AUSC					
--2021-05-30 21:45:51.7549693	AUSC				
--2021-05-30 21:47:32.1783514	AUSC				
--2021-05-30 21:55:07.0934795	AUSC				
--2021-05-30 21:55:07.0947801	AUSC				
--2021-05-30 22:04:51.3182244	AUSC				
--2021-05-30 22:50:53.0215693	DL  	containers_ppd_test	EncargadoLuis			Mgmt		DELETE Mgmt.container_status_audited_ppd


-- Perform actions SELECT and INSERT as member of Role OfficeMgmt -> EncargadoLuis
-- check current stock with a select statement
EXECUTE ('SELECT * FROM Mgmt.stock_audited_ppd') as user='EncargadoLuis'
GO
--id_stock	cantidad	modelo_cont_ppd_id_modelo
--1000		12			1002
--1001		3			1004
--1002		24			1006
-- update current stock after sell 2 containers by Luis with a update statement
EXECUTE ('UPDATE Mgmt.stock_audited_ppd set cantidad=10 where id_stock=1000') as user='EncargadoLuis'
GO

--(1 row affected)

-- check current stock after selling 2 1002 model with a select statement
EXECUTE ('SELECT * FROM Mgmt.stock_audited_ppd') as user='EncargadoLuis'
GO
--	id_stock	cantidad	modelo_cont_ppd_id_modelo
--  1000		>>10<<		1002
--	1001		3			1004
--	1002		24			1006

-- Check log again
SELECT top 5 event_time,action_id,database_name,database_principal_name,schema_name,statement
	FROM sys.fn_get_audit_file ('C:\auditoria\PPD_containers_audit\*.sqlaudit',default,default) 
	ORDER BY event_time DESC;
GO


-- only UPDATE ACTION IS AUDITED 
--event_time	action_id	database_name	database_principal_name	schema_name	statement
--2021-05-30 23:11:22.3806115	UP  	containers_ppd_test	EncargadoLuis	Mgmt	UPDATE Mgmt.stock_audited_ppd set cantidad=10 where id_stock=1000
--2021-05-30 22:50:53.0215693	DL  	containers_ppd_test	EncargadoLuis	Mgmt	DELETE Mgmt.container_status_audited_ppd
--2021-05-30 22:04:51.3182244	AUSC				
--2021-05-30 21:55:07.0947801	AUSC				
--2021-05-30 21:55:07.0934795	AUSC	

/*  PERFORM ACTION BY A ROLE THAT DOES NOT FITS THE AUDIT SPECIFICATIONS */
-- A 'Personal' Role user sells a container
GRANT SELECT, UPDATE ON  SCHEMA::Mgmt TO Personal;
GO
-- update current stock after sell 1 container by VendedorAngel with a update statement
EXECUTE ('UPDATE Mgmt.stock_audited_ppd set cantidad=9 where id_stock=1000') as user='VendedorAngel'
GO

--(1 row affected)
-- Check log again it is the same, because action was performed by another role
SELECT top 5 event_time,action_id,database_name,database_principal_name,schema_name,statement
	FROM sys.fn_get_audit_file ('C:\auditoria\PPD_containers_audit\*.sqlaudit',default,default) 
	ORDER BY event_time DESC;
GO

--event_time	action_id	database_name	database_principal_name	schema_name	statement
--2021-05-30 23:11:22.3806115	UP  	containers_ppd_test	EncargadoLuis	Mgmt	UPDATE Mgmt.stock_audited_ppd set cantidad=10 where id_stock=1000
--2021-05-30 22:50:53.0215693	DL  	containers_ppd_test	EncargadoLuis	Mgmt	DELETE Mgmt.container_status_audited_ppd
--2021-05-30 22:04:51.3182244	AUSC				
--2021-05-30 21:55:07.0947801	AUSC				
--2021-05-30 21:55:07.0934795	AUSC				

/*  PERFORM INSERT ACTION  */	
-- SET UP A NEW STATUS after 1 container gets hit by another by EncargadoLuis with a INSERT statement
-- SET UP A NEW STATUS after 1 container was emptyed at harbour by EncargadoLuis with a INSERT statement
EXECUTE as user='EncargadoLuis'
GO	
Select USer	
INSERT INTO [Mgmt].[container_status_audited_ppd]
           ([peso_neto]
           ,[desc_estado])
     VALUES
       (3456,'Seminuevo con abolladura en lateral exterior izquierdo por impacto'),
		   (2450,'Empty of charge material, clean and ready to trasnport')
		   
--(2 rows affected)
REVERT

-- check audit logs
SELECT top 5 event_time,action_id,database_name,database_principal_name,schema_name,statement
	FROM sys.fn_get_audit_file ('C:\auditoria\PPD_containers_audit\*.sqlaudit',default,default) 
	ORDER BY event_time DESC;
GO

-- new insert was performed and logged to audit
--event_time	action_id	database_name	database_principal_name	schema_name	statement
--2021-05-30 23:30:24.8456258	IN  	containers_ppd_test	EncargadoLuis	Mgmt	INSERT INTO [Mgmt].[container_status_audited_ppd]             ([peso_neto]             ,[desc_estado])       VALUES         (3456,'Seminuevo con abolladura en lateral exterior izquierdo por impacto'),       (2450,'Empty of charge material, clean and ready to trasnport')
--2021-05-30 23:11:22.3806115	UP  	containers_ppd_test	EncargadoLuis	Mgmt	UPDATE Mgmt.stock_audited_ppd set cantidad=10 where id_stock=1000
--2021-05-30 22:50:53.0215693	DL  	containers_ppd_test	EncargadoLuis	Mgmt	DELETE Mgmt.container_status_audited_ppd
--2021-05-30 22:04:51.3182244	AUSC				
--2021-05-30 21:55:07.0947801	AUSC		

-- log a wrong sentence	
REVOKE UPDATE ON  SCHEMA::Mgmt TO OfficeMgmt;
GO
EXECUTE ('UPDATE Mgmt.stock_audited_ppd set cantidad=1 where id_stock=1010') as user='EncargadoLuis'
GO
--Msg 229, Level 14, State 5, Line 235
--The UPDATE permission was denied on the object 'stock_audited_ppd', database 'containers_ppd_test', schema 'Mgmt'.

--Check the audit log after this unsuccessful statement
SELECT top 10 event_time,action_id,database_name,database_principal_name,schema_name,statement
	FROM sys.fn_get_audit_file ('C:\auditoria\PPD_containers_audit\*.sqlaudit',default,default) 
	ORDER BY event_time DESC;
GO
--event_time	action_id	database_name	database_principal_name	schema_name	statement
--2021-05-30 23:41:22.8492990	UP  	containers_ppd_test	EncargadoLuis	Mgmt	UPDATE Mgmt.stock_audited_ppd set cantidad=1 where id_stock=1010
--2021-05-30 23:41:22.8492990	UNDO	containers_ppd_test	EncargadoLuis		UPDATE Mgmt.stock_audited_ppd set cantidad=1 where id_stock=1010
--2021-05-30 23:40:52.6373581	UP  	containers_ppd_test	EncargadoLuis	Mgmt	UPDATE Mgmt.stock_audited_ppd set cantidad=1 where id_stock=1010
--2021-05-30 23:40:52.6373581	UNDO	containers_ppd_test	EncargadoLuis		UPDATE Mgmt.stock_audited_ppd set cantidad=1 where id_stock=1010
--2021-05-30 23:40:39.2027703	UP  	containers_ppd_test	EncargadoLuis	Mgmt	UPDATE Mgmt.stock_audited_ppd set cantidad=1 where id_stock=1010
--2021-05-30 23:38:25.7839738	UP  	containers_ppd_test	EncargadoLuis	Mgmt	UPDATE Mgmt.stock_audited_ppd set cantidad=1 where id_stock=1010
--2021-05-30 23:30:24.8456258	IN  	containers_ppd_test	EncargadoLuis	Mgmt	INSERT INTO [Mgmt].[container_status_audited_ppd]             ([peso_neto]             ,[desc_estado])       VALUES         (3456,'Seminuevo con abolladura en lateral exterior izquierdo por impacto'),       (2450,'Empty of charge material, clean and ready to trasnport')
--2021-05-30 23:11:22.3806115	UP  	containers_ppd_test	EncargadoLuis	Mgmt	UPDATE Mgmt.stock_audited_ppd set cantidad=10 where id_stock=1000
--2021-05-30 22:50:53.0215693	DL  	containers_ppd_test	EncargadoLuis	Mgmt	DELETE Mgmt.container_status_audited_ppd
--2021-05-30 22:04:51.3182244	AUSC				