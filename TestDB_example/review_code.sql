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

CREATE SCHEMA HR
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
