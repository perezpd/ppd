


-- http://sqlhints.com/2016/01/23/row-level-security-in-sql-server-2016/
-- https://msdn.microsoft.com/es-es/library/dn765131.aspx
-- http://www.sqlshack.com/filter-block-data-access-using-sql-server-2016-row-level-security/
-- http://www.databasejournal.com/features/mssql/row-level-security-with-sql-server-2016.html
-- http://stephanefrechette.com/sql-server-2016-row-level-security/#.WIjEG1PhB1s


-- How to filter and block the data access using SQL Server 2016 Row-Level Security

-- Users - permissions - Functions - Schemas
/*

SQL Server 2016 came with many new features and enhancements for existing ones, that concentrate on the aspect of SQL Server security. One of the new security features introduced in SQL Server 2016 is Row-Level Security. This feature allows us to control access deeply into the rows level in the database table, based on the user executing the query. This is done within the database layer, in complete transparency to the application process, without the need to manage it with complex coding at the application layer.

Row-Level Security (RLS) provides us with a way to restrict users to allow them to work only with the data they have access to. For example, each courier in a shipping company can access only the data related to the shipments he is requested to deliver, without being able to access other courier’s data. Each time data access is performed from any tier, data access will be restricted by the SQL Server Engine, reducing the security system surface area.

There are two types of security predicates that are supported in Row-Level Security; the Filter predicate that filters row silently for read operations. The Silent filter predicate means that the application will not be made aware that the data is filtered, null values will be returned if all rows are filtered, without raising an error message. The Block predicate prevents any write operation that violates any defined predicate with an error message returned as a result of the block. This policy can be turned ON and OFF with four main blocking types; AFTER INSERT and AFTER UPDATE blocking will prevent the users from updating the rows to values that will violate the predicate. BEFORE UPDATE will prevent the users from updating the rows that are violating the predicate currently. BEFORE DELETE will prevent the users from deleting the rows. Trying to add a predicate on a table that already has a predicate defined will result with error.

Data access restriction using Row-Level Security is accomplished by defining a Security predicate as an inline-table-valued function that will restrict the rows based on filtering logic, which is invoked and enforced by a Security Policy created using the CREATE SECURITY POLICY T-SQL statement and working as predicates container. SQL Server allows you to define multiple active security policies but without overlapping predicates. Altering a table with a schema bound security policy defined on it will fail with error.

*/

--------------------------
REVERT

-- http://sqlhints.com/2016/01/23/row-level-security-in-sql-server-2016/

USE master
GO
DROP DATABASE IF EXISTS CRICKET
go
CREATE DATABASE CRICKET
GO
USE CRICKET
GO
DROP TABLE IF EXISTS dbo.Players
go
CREATE TABLE dbo.Players
(
    PlayerId INT IDENTITY(1,1),
    Name    NVARCHAR(100),
    Country NVARCHAR(50),
    UserName sysname  -- CAMPO A CONTROLAR
)
GO
-- EQUIPOS DE INDIA - AUSTRALIA

INSERT INTO dbo.Players (Name, Country, UserName)
Values('Sachin Tendulkar', 'India', 'BCCI_USER'),
      ('Rahul Dravid', 'India', 'BCCI_USER'),
      ('Anil Kumble','India', 'BCCI_USER'),
      ('Ricky Ponting','Australia', 'CA_USER'),
      ('Shane Warne','Australia', 'CA_USER')
GO

SELECT * FROM dbo.Players
GO

-- CREATE USERS

--Indian cricket board user
CREATE USER BCCI_USER WITHOUT LOGIN
GO
-- Australian cricket board user 
CREATE USER CA_USER WITHOUT LOGIN 
GO   
--Admin user (International Cricket Council user) 
CREATE USER ICC_USER WITHOUT LOGIN 
GO


GRANT SELECT ON Players TO BCCI_USER
GRANT SELECT ON Players TO CA_USER
GRANT SELECT ON Players TO ICC_USER  --Admin user
GO

--Players predicate function

DROP FUNCTION IF EXISTS dbo.PlayersPredicateFunction
GO
CREATE FUNCTION dbo.PlayersPredicateFunction
			( @UserName AS SYSNAME )
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN  SELECT 1 AS AccessRight
    WHERE @UserName = USER_NAME() 
		OR USER_NAME() = 'ICC_USER'
GO

--Security policy
CREATE SECURITY POLICY PlayersSecurityPolicy
--Security Predicate FILTER 
ADD FILTER PREDICATE dbo.PlayersPredicateFunction(UserName) 
	ON dbo.Players
WITH (STATE = ON)
GO

PRINT USER
GO
--dbo

SELECT * FROM dbo.Players
GO

-- PlayerId	Name	Country	UserName


-- From the result it is clear that the filter predicate is filtering out all the rows as the SA user with which 
-- I am executing the query doesn’t have the access to any rows as per the predicate function definition. And below is the execution plan of this query:

-- NOTA : OTRA VERSIÓN PARA IMPERSONATE

-- EXECUTE (SELECT * FROM dbo.Players) AS USER = 'BCCI_USER'


-- function  .... WHERE @UserName = USER_NAME() OR USER_NAME() = 'ICC_USER'

EXECUTE AS USER = 'BCCI_USER'
GO
SELECT * FROM dbo.Players
GO

--PlayerId	Name	Country	UserName
--1	Sachin Tendulkar	India	BCCI_USER
--2	Rahul Dravid	India	BCCI_USER
--3	Anil Kumble	India	BCCI_USER


REVERT
GO

EXECUTE AS USER = 'CA_USER'
GO
SELECT * FROM dbo.Players
GO

--PlayerId	Name	Country	UserName
--4	Ricky Ponting	Australia	CA_USER
--5	Shane Warne	Australia	CA_USER

REVERT
GO


EXECUTE AS USER = 'ICC_USER'
GO
SELECT * FROM dbo.Players
GO

--PlayerId					Name			Country			UserName
--1						Sachin Tendulkar	India		BCCI_USER
--2						Rahul Dravid		India		BCCI_USER
--3						Anil Kumble			India		BCCI_USER
--4						Ricky Ponting		Australia	CA_USER
--5						Shane Warne			Australia	CA_USER

REVERT
GO

-- GRANT
GRANT INSERT, UPDATE, DELETE ON Players TO BCCI_USER
GRANT INSERT, UPDATE, DELETE ON Players TO CA_USER
GRANT INSERT, UPDATE, DELETE ON Players TO ICC_USER
GO
REVERT
-- India
-- Can Insert IN AUSTRALIA TEAM  
EXECUTE AS USER  = 'BCCI_USER'
GO
SELECT * FROM dbo.Players
GO

--PlayerId	Name	Country	UserName
--1	Sachin Tendulkar	India	BCCI_USER
--2	Rahul Dravid	India	BCCI_USER
--3	Anil Kumble	India	BCCI_USER


INSERT INTO dbo.Players (Name, Country, UserName)
  Values('Glenn McGrath', 'Australia', 'CA_USER')
go

-- (1 row affected)

SELECT * FROM dbo.Players
GO

--PlayerId	Name	Country	UserName
--1	Sachin Tendulkar	India	BCCI_USER
--2	Rahul Dravid	India	BCCI_USER
--3	Anil Kumble	India	BCCI_USER

-- SIN EMBARGO, NO PUEDE BORRAR NI ACTUALIZAR
-- 5						Shane Warne			Australia	CA_USER
DELETE dbo.Players
WHERE NAME = 'Shane Warne'
GO

-- (0 rows affected)

UPDATE dbo.Players
SET Country = 'USA'
WHERE NAME = 'Shane Warne'
GO
SELECT * FROM dbo.Players
GO

--PlayerId	Name	Country	UserName
--1	Sachin Tendulkar	India	BCCI_USER
--2	Rahul Dravid	India	BCCI_USER
--3	Anil Kumble	India	BCCI_USER

REVERT
GO
EXECUTE AS USER = 'CA_USER'
GO
SELECT * FROM dbo.Players
GO


--PlayerId	Name	Country	UserName
--4	Ricky Ponting	Australia	CA_USER
--5	Shane Warne	Australia	CA_USER
--6	Glenn McGrath	Australia	CA_USER				-- INSERTADO POR INDIA

REVERT
GO
EXECUTE AS USER  = 'BCCI_USER'
GO

DELETE dbo.Players
GO

-- (3 rows affected)

PRINT USER
GO

-- BCCI_USER

SELECT * FROM dbo.Players
go
SELECT COUNT(*) FROM dbo.Players
go


-- PUDO BORRAR LAS FILAS SUYAS
-- 0
REVERT

-- RECREAR TABLA


-- PRIMERO BORRAR LA FUNCION
-- Msg 3729, Level 16, State 1, Line 38
-- Cannot DROP TABLE 'dbo.Players' because it is being referenced by object 'PlayersSecurityPolicy'.

-- There is already an object named 'PlayersPredicateFunction' in the database.

-- (1 row(s) affected)

DROP FUNCTION PlayersPredicateFunction
GO

--Msg 3729, Level 16, State 1, Line 266
--Cannot DROP FUNCTION 'PlayersPredicateFunction' because it is being referenced by object 'PlayersSecurityPolicy'.


-- VER GUI

-- PROGRAMMABILITY
-- FUNCTIONS [dbo].[PlayersPredicateFunction]

-- SECURITY
-- SECURITY POLICIES  [dbo].[PlayersSecurityPolicy]

DROP SECURITY POLICY [dbo].[PlayersSecurityPolicy]
GO


-- ESTO NO HACE FALTA


EXECUTE AS USER  = 'BCCI_USER'
GO
SELECT * FROM dbo.Players
GO
REVERT

-- SIN EMBARGO, NO LA VE
--PlayerId	Name	Country	UserName
--1	Sachin Tendulkar	India	BCCI_USER
--2	Rahul Dravid	India	BCCI_USER
--3	Anil Kumble	India	BCCI_USER

-- From the result it is clear that BCCI_USER doesn’t have the access to the record Australian player record which he has inserted

-- Let us see whether the CA_USER can see the Australian player record which the BCCI_USER has inserted
revert
EXECUTE AS USER  = 'CA_USER'
GO
SELECT * FROM dbo.Players
GO
REVERT
GO

--PlayerId	Name	Country	UserName
--4	Ricky Ponting	Australia	CA_USER
--5	Shane Warne	Australia	CA_USER
--6	Glenn McGrath	Australia	CA_USER

REVERT
GO
-- From the result we can see that the CA_USER has access to the Australian Player record which BCCI_USER has inserted.

-- So from the above example we can see that a FILTER predicate is not blocking the user from INSERTING a record which after insert is filtered by it for that user for any operation.

-- Don’t worry to avoid such behavior, we have Block predicate at our disposal. Let us now understand the Block predicate with examples:

--Security policy
CREATE SECURITY POLICY PlayersSecurityPolicy
--Security Predicate FILTER 
ADD FILTER PREDICATE dbo.PlayersPredicateFunction(UserName) 
	ON dbo.Players
WITH (STATE = ON)
GO


-- RECREATE TABLE


-- BLOCK PREDICATE
REVERT
GO
PRINT USER
GO
-- Let’s add the AFTER INSERT BLOCK predicate on the Players table to block user from inserting a record which after insert user doesn’t have access to it.

-- Execute the below statement to alter the above Security policy to add the AFTER INSERT BLOCK predicate.

ALTER SECURITY POLICY PlayersSecurityPolicy
 ADD BLOCK PREDICATE dbo.PlayersPredicateFunction(UserName)
     ON dbo.Players AFTER INSERT
GO




-- Here for the AFTER INSERT BLOCK PREDICATE we are using the same predicate function which we have used to filter the records by the FILTER PREDICATE.

-- Basically, the AFTER INSERT BLOCK Predicate blocks user from inserting a record which after insert doesn’t satisfy predicate function. In other words from this example perspective the AFTER INSERT BLOCK predicate blocks the user from inserting a record which after insert user doesn’t have access to it.

-- Let us execute the following statement to see whether the user BCCI_USER who doesn’t have access to the Australian players rows can insert an Australian Player

EXECUTE AS USER  = 'BCCI_USER'
GO
INSERT INTO dbo.Players (Name, Country, UserName)
Values('Adam Gilchrist', 'Australia', 'CA_USER')
GO

--Msg 33504, Level 16, State 1, Line 454
--The attempted operation failed because the target object 'CRICKET.dbo.Players' has a block predicate that conflicts with this operation. If the operation is performed on a view, the block predicate might be enforced on the underlying table. Modify the operation to target only the rows that are allowed by the block predicate.
--The statement has been terminated.

-- From the result we can see that BLOCK Predicate is blocking a BCCI_USER user from inserting a record which after insert user doesn’t have access to it.

-- New Catalog Views/DMVs for the Row level security

INSERT INTO dbo.Players (Name, Country, UserName)
  Values('Glenn McGrath', 'Australia', 'CA_USER')
go
PRINT USER
GO
REVERT
GO
sp_help 'sys.security_policies'
GO

SELECT * FROM sys.security_policies
GO


SELECT Name, object_id, type, type_desc,is_ms_shipped,is_enabled,is_schema_bound
FROM sys.security_policies
GO

--Name	object_id	type	type_desc	is_ms_shipped	is_enabled	is_schema_bound
--PlayersSecurityPolicy	613577224	SP	SECURITY_POLICY	0	1	1


SELECT * 
FROM sys.security_predicates
GO

--object_id	security_predicate_id	target_object_id	predicate_definition	predicate_type	predicate_type_desc	operation	operation_desc
--613577224	1	565577053	([dbo].[PlayersPredicateFunction]([UserName]))	0	FILTER	NULL	NULL
--613577224	2	565577053	([dbo].[PlayersPredicateFunction]([UserName]))	1	BLOCK	1	AFTER INSERT


DROP DATABASE  CRICKET
GO

------------------
-- Another Example

-- 
CREATE DATABASE RLS
GO
USE RLS
GO

CREATE TABLE [dbo].[Courier_Shipments](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Courier_Name] [varchar](10) NULL,
	[NumOfShipmentsInPackage] [int] NULL,
	[Package_Date] [datetime] NULL,
	[Package_Cost] [int] NULL,
	[Package_City] [varchar](10) NULL,
 CONSTRAINT [PK_Courier_Shipments] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)) ON [PRIMARY]
 
GO

INSERT INTO [dbo].[Courier_Shipments]
           ([Courier_Name]
           ,[NumOfShipmentsInPackage]
           ,[Package_Date]
           ,[Package_Cost]
           ,[Package_City])
     VALUES
           ('John',5,'2016-09-22 01:35:00:000',580,'LON'),
		   ('Ghezil',3,'2016-09-22 03:45:00:000',470,'LAX'),
		   ('Mark',2,'2016-09-22 04:32:00:000',118,'JFK'),
		   ('Ghezil',5,'2016-09-22 02:38:00:000',358,'LAX'),
		   ('Mark',4,'2016-09-22 06:12:00:000',774,'JFK'),
		   ('John',7,'2016-09-22 08:07:00:000',941,'LON')
GO


--Also we will create a three users, one for each courier who will retrieve his shipments data:
-- 

CREATE USER John WITHOUT LOGIN;  
CREATE USER Ghezil WITHOUT LOGIN;  
CREATE USER Mark WITHOUT LOGIN;   
GO
--  Without Scema

GRANT SELECT ON [Courier_Shipments] TO John;  
GRANT SELECT ON [Courier_Shipments] TO Ghezil;  
GRANT SELECT ON [Courier_Shipments] TO Mark;
GO


CREATE SCHEMA RLS;  
GO

ALTER SCHEMA RLS TRANSFER dbo.[Courier_Shipments]  
GO
REVERT
GRANT SELECT ON SCHEMA::RLS TO John,Ghezil,Mark;
GO

-- First we will create the Filter Predicate function that depends on the logged in user name to filter the users and check their access on the data as follows:

CREATE FUNCTION RLS.fn_SecureCourierData(@CourierName AS sysname)  
    RETURNS TABLE  
WITH SCHEMABINDING  
AS  
    RETURN SELECT 1 AS 'SecureCourierShipments'   
WHERE @CourierName = USER_NAME(); 
GO

-- And create the Security Policy on the Courier_Shipments table using the previously created predicate function, then turn it on:

CREATE SECURITY POLICY CourierShipments  
ADD FILTER PREDICATE RLS.fn_SecureCourierData(Courier_Name)   
ON RLS.Courier_Shipments  
WITH (STATE = ON);  
GO

-- Now, Row-Level Security is fully configured and ready to start filtering any new data access on the Courier_Shipments table. Expanding the Security node of the SQLShackDemo database, the newly created Security Policy can be found as in the following image using the SQL Server Management Studio:

-- If we try to run the below query using John user:


EXECUTE AS USER = 'John'
GO  
SELECT * FROM RLS.Courier_Shipments; 
GO  

-- Only see
/*
ID	Courier_Name	NumOfShipmentsInPackage	Package_Date	Package_Cost	Package_City
1	John	5	2016-09-22 01:35:00.000	580	LON
6	John	7	2016-09-22 08:07:00.000	941	LON
*/

REVERT;
GO

EXECUTE AS USER = 'Ghezil'
GO  
SELECT * FROM RLS.Courier_Shipments; 
GO  

/*

ID	Courier_Name	NumOfShipmentsInPackage	Package_Date	Package_Cost	Package_City
2	Ghezil	3	2016-09-22 03:45:00.000	470	LAX
4	Ghezil	5	2016-09-22 02:38:00.000	358	LAX

*/

REVERT;
GO

EXECUTE AS USER = 'Mark'
GO  
SELECT * FROM RLS.Courier_Shipments; 
GO  

/*
ID	Courier_Name	NumOfShipmentsInPackage	Package_Date	Package_Cost	Package_City
3	Mark	2	2016-09-22 04:32:00.000	118	JFK
5	Mark	4	2016-09-22 06:12:00.000	774	JFK
*/

/*
It is clear from the previous results that the Row-Level Security feature can be used to filter the data that each user can see depending on the filtering criteria defined in the predicate function.

If you manage to stop using the Row-Level Security feature that we configured, you need to disable the Security Policy using the ALTER SECURITY POLICY statement below:
*/
REVERT
GO
Alter Security Policy CourierShipments  with (State = off)
GO

Drop Security Policy CourierShipments
GO
Drop Function RLS.fn_SecureCourierData
GO

-- Now the Row-Level Security is removed completely from the Courier_Shipments table.

-- there is another type of predicates that can be used in the Row-level Security feature which is the Block Predicate.

--  Let’s have a second demo to know how the block predicate can be configured and work.

-- Again, we will create a predicate function that will filter the data access depends on the users connecting to that table as follows:


CREATE FUNCTION RLS.fn_SecureCourierData (@Courier_Name sysname)
	RETURNS TABLE
	WITH SCHEMABINDING
AS
	RETURN SELECT 1 AS fn_SecureCourierData_result
	WHERE @Courier_Name= user_name()
GO

-- Also we will create the security policy, but this time it will contain an AFTER INSERT block predicate condition in addition to the filter predicate

CREATE SECURITY POLICY fn_Courier_Shipments
	ADD FILTER PREDICATE RLS.fn_SecureCourierData(Courier_Name)  ON  RLS.Courier_Shipments,
	ADD BLOCK PREDICATE RLS.fn_SecureCourierData(Courier_Name)  ON  RLS.Courier_Shipments AFTER INSERT 
GO

-- And enable the Security policy as follows:


Alter Security Policy fn_Courier_Shipments  with (State = ON)
GO

-- As the blocking will be on the INSERT operation, we will grant Mark user access to do so:


GRANT SELECT, INSERT, UPDATE, DELETE ON RLS.Courier_Shipments TO Mark;
GO

--If Mark tries to apply the below SELECT statement with his user:


EXECUTE AS USER = 'Mark'; 
GO 
SELECT * FROM RLS.Courier_Shipments; 
GO  

/*
ID	Courier_Name	NumOfShipmentsInPackage	Package_Date	Package_Cost	Package_City
3	Mark	2	2016-09-22 04:32:00.000	118	JFK
5	Mark	4	2016-09-22 06:12:00.000	774	JFK
*/

-- Mark sees the outcome

REVERT
GO

-- But if he tries to insert a new record with his user, but with the courier name different from his name, let’s say John:

EXECUTE AS USER = 'Mark';
GO  
INSERT INTO [RLS].[Courier_Shipments]
           ([Courier_Name]
           ,[NumOfShipmentsInPackage]
           ,[Package_Date]
           ,[Package_Cost]
           ,[Package_City])
     VALUES
           ('John',5,'2016-09-22 01:35:00:000',580,'LON')
GO

--Msg 33504, Level 16, State 1, Line 217
--The attempted operation failed because the target object 'RLS.RLS.Courier_Shipments' has a block predicate that conflicts with this operation. If the operation is performed on a view, the block predicate might be enforced on the underlying table. Modify the operation to target only the rows that are allowed by the block predicate.
--The statement has been terminated.



SELECT * FROM RLS.Courier_Shipments; 
GO 
-- Works


-- NO ejecutar
DELETE RLS.Courier_Shipments; 
GO
-- (2 row(s) affected)

SELECT * FROM RLS.Courier_Shipments; 
GO 

-- (0 row(s) affected)

--Again, if the previous insert statement is modified by replacing John name with Mark name and execute it with Mark’s user:

EXECUTE AS USER = 'Mark'; 
GO 
INSERT INTO [RLS].[Courier_Shipments]
           ([Courier_Name]
           ,[NumOfShipmentsInPackage]
           ,[Package_Date]
           ,[Package_Cost]
           ,[Package_City])
     VALUES
           ('Mark',5,'2016-09-22 01:35:00:000',580,'LON')
GO


-- (1 row(s) affected)


-- Which is clear from running the SELECT statement with his user, showing the below result:

-- As you can conclude from the previous result, the Row-level Security feature can be also used to block the user from applying specific operations on the rows that he has no access on it.

-- New system objects have also been introduced in SQL Server 2016 to query the Row-Level Security feature’s information. The sys.security_policies can be used to retrieve all information about the defined security policy on your database as below:


SELECT name,type_desc ,create_date ,modify_date,is_enabled,is_schema_bound  FROM sys.security_policies
GO

SELECT * FROM sys.security_predicates
GO

/*

A common question that you may ask or may be asked, is if there any performance impact or side effect when using the Row-Level Security feature? The suitable answer here is that it depends. Yes, it depends on the complexity of the predicate logic you define, as it will be checked for each data access in your table. If you define a simple direct predicate filter, you will not notice any overhead or performance degradation in your database.

*/



DROP DATABASE RLS
GO

-