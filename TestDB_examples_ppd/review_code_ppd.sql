-- OWNERSHIP CHAINING


DROP DATABASE IF EXISTS TestDB
GO

CREATE DATABASE TestDB
GO

USE TestDB
GO

-- now TestDB is active

-- we are going to create an SCHEMA
-- default schema is dbo (BataBase Owner)
-- create SCHEMA after check existence
DROP SCHEMA IF EXISTS HR
GO

CREATE SCHEMA HR;
GO

-- create TABLE after check existence in SCHEMA HR
DROP TABLE IF EXISTS HR.Employee
GO

CREATE TABLE HR.Employee (
  EployeeId INT,
  GivenNAme VARCHAR(50),
  Surname VARCHAR(50),
  SSN CHAR(9) -- we dont want the Interns to see this value
);
GO

-- we dont use any constraints in the table

SELECT * FROM [HR].[Employee];
GO


-- result
--EployeeId	GivenNAme	Surname	SSN
--1			luis		arias	11
--2			Ana			Perez	22
--2			Pepe		Gomez	333

DROP VIEW IF EXISTS HR.LookingEmployee
GO
CREATE VIEW HR.LookingEmployee
AS
	SELECT Eployeeid,GivenName, Surname
	FROM HR.Employee
GO

--SELECT * FROM LookingEmployee;
--GO

-- ERROR
--Msg 208, Level 16, State 1, Line 55
--Invalid object name 'LookingEmployee'.

-- MANAGING ROLES
-- SERVER ROLES and USER ROLES
-- we add users to role and then user inherit the permissions and access
DROP ROLE IF EXISTS HumanResourcesAnalyst
GO
CREATE ROLE HumanResourcesAnalyst;
GO

-- three actions GRANT (conceder), DENY (denegar), REVOKE (retirar) same as ORACLE and MySQL

GRANT SELECT ON HR.LookingEmployee TO HumanResourcesAnalyst;
GO

-- creating an user with no login to avoid errors
DROP USER IF EXISTS JaneDoe
GO
CREATE USER JaneDoe WITHOUT LOGIN;
GO

-- adding user JaneDoe to ROLE
ALTER ROLE HumanResourcesAnalyst
	ADD MEMBER JaneDoe;
GO

-- pending to check
-- (3/12/2020)

-- we will try to import a file inside the table employees
-- we will create a file called employee.txt and
--		we will import it to TestDB on table employee

-- Empty table [HR].[Employee]
/****** Object:  Table [HR].[Employee]    Script Date: 03/12/2020 21:09:08 ******/
DROP TABLE [HR].[Employee]
GO


-- create it again
-- create TABLE after check existence in SCHEMA HR
DROP TABLE IF EXISTS HR.Employee
GO

CREATE TABLE HR.Employee (
  EployeeID INT,
  GivenNAme VARCHAR(50),
  Surname VARCHAR(50),
  SSN CHAR(9)
);
GO

SELECT * FROM [HR].[Employee];
GO

--EployeeID	GivenNAme	Surname	SSN
--1	luis	arias	11
--2	Ana	Perez	22
--3	Pepe	Gomez	333

-- (15/12/2020)
-- what we need to secure in our system???
-- principals
-- windows accounts, windows user groups, the logins, SQL server credentials & database credentials
-- securables
-- objects inside the system as database schemas

USE [TestDB];
GO

SELECT * FROM [HR].[Employee];
GO

-- select from view
SELECT * FROM [HR].[LookingEmployee];
GO

PRINT USER;
GO

-- impersonation as JaneDoe: take personality of JaneDoe
EXECUTE AS USER = 'JaneDoe';
GO
PRINT USER;
GO

SELECT * FROM [HR].[Employee];
GO
--result: error when select into the main table
--Msg 229, Level 14, State 5, Line 147
--The SELECT permission was denied on the object 'Employee', database 'TestDB', schema 'HR'.

-- select from view
SELECT * FROM [HR].[LookingEmployee];
GO
--Eployeeid	GivenName	Surname
--1			luis		arias
--2			Ana			Perez
--3			Pepe		Gomez

REVERT;
GO


-- create procedure into TestDB
CREATE OR ALTER PROC HR.InsertNewEmployee
-- INPUT PARAMETERS
-- here we put the parameters separated by comma if we have more than one
-- we set the type of the parameters and optional the default value with equal sign
  @EmployeeID INT,
  @GivenNAme VARCHAR(50),
  @Surname VARCHAR(50),
  @SSN CHAR(9)
AS
BEGIN -- start of the code inside the procedure
  INSERT INTO HR.Employee
    (Eployeeid,	GivenName,	Surname, SSN)
  VALUES
    (@EmployeeID, @GivenNAme, @Surname, @SSN);
END -- end of the code inside the procedure
GO

--create  a role to insert through the procedure, but WITHOUT INSERT PERMISION INTO THE TABLE ITSELF
CREATE ROLE HumanResourcesRecruiter;
GO

GRANT EXECUTE ON SCHEMA::[HR] TO HumanResourcesRecruiter;
GO

CREATE USER JohnSmith WITHOUT LOGIN;
GO

-- adding user JohnSmith to ROLE HumanResourcesRecruiter
ALTER ROLE HumanResourcesRecruiter
	ADD MEMBER JohnSmith;
GO

-- START TESTING; JohnSmith cannot insert directly into table HR.Employee
EXECUTE AS USER = 'JohnSmith';
GO
PRINT USER;
GO

-- JohnSmith
INSERT INTO HR.Employee
  (Eployeeid,	GivenName,	Surname, SSN)
VALUES
  (4, 'Mauro', 'Silva','123123000');
GO
--Msg 229, Level 14, State 5, Line 205
--The INSERT permission was denied on the object 'Employee', database 'TestDB', schema 'HR'.


-- but now we try to use the procedure, 
-- we can use EXEC or EXECUTE as well
-- we can set the parameter value names as equal on the procedurte call
--EXEC HR.InsertNewEmployee
  --@EmployeeID = 4,
  --@GivenNAme = 'Mauro',
  --@Surname = 'Silva',
  --@SSN = '123123000'
--GO


EXEC HR.InsertNewEmployee 4, 'Mauro', 'Silva','123123000';
GO

-- we need to GO back to dbo user to check table content with select
REVERT;
GO
SELECT * FROM [HR].[Employee];
GO

--EployeeID	GivenNAme	Surname	SSN
--1			luis		arias	11       
--2			Ana			Perez	22       
--3			Pepe		Gomez	333      
--4			Mauro		Silva	123123000

