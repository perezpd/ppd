
-- EJEMPLO INSERT - IDENTITY ON / OFF


USE [AdventureWorksLT2017]
GO

-- schemas

SELECT * FROM sys.schemas
GO


-- name		schema_id	principal_id
-- SalesLT		5			1

DROP TABLE IF EXISTS SalesLT.CallLog
GO

-- Create a table for the demo
CREATE TABLE SalesLT.CallLog
(
	CallID int IDENTITY PRIMARY KEY NOT NULL,
	CallTime datetime NOT NULL DEFAULT GETDATE(),
	SalesPerson nvarchar(256) NOT NULL,
	CustomerID int NOT NULL REFERENCES SalesLT.Customer(CustomerID),
	PhoneNumber nvarchar(25) NOT NULL,
	Notes nvarchar(max) NULL
);
GO
SP_HELP [SalesLT.CallLog]
GO

SELECT * FROM SalesLT.CallLog;
GO

-- Insert a row
INSERT INTO SalesLT.CallLog
VALUES
('2015-01-01T12:30:00', 'adventure-works\pamela0', 1, '245-555-0173', 'Returning call re: enquiry about delivery');
GO
SELECT * FROM SalesLT.CallLog;
GO
-- CallID int IDENTITY

--CallID	CallTime	SalesPerson	CustomerID	PhoneNumber	Notes
--1	2015-01-01 12:30:00.000	adventure-works\pamela0	1	245-555-0173	Returning call re: enquiry about delivery

-- Insert defaults and nulls
INSERT INTO SalesLT.CallLog
VALUES
(DEFAULT, 'adventure-works\david8', 2, '170-555-0127', NULL);
GO
SELECT * FROM SalesLT.CallLog;
GO

--CallID	CallTime	SalesPerson	CustomerID	PhoneNumber	Notes
--1	2015-01-01 12:30:00.000	adventure-works\pamela0	1	245-555-0173	Returning call re: enquiry about delivery
--2	2021-04-26 20:15:56.693	adventure-works\david8	2	170-555-0127	NULL

-- Insert a row with explicit columns
INSERT INTO SalesLT.CallLog (SalesPerson, CustomerID, PhoneNumber)
VALUES
('adventure-works\jillian0', 3, '279-555-0130');
GO
SELECT * FROM SalesLT.CallLog;
GO

--CallID	CallTime	SalesPerson	CustomerID	PhoneNumber	Notes
--1	2015-01-01 12:30:00.000	adventure-works\pamela0	1	245-555-0173	Returning call re: enquiry about delivery
--2	2021-04-26 20:15:56.693	adventure-works\david8	2	170-555-0127	NULL
--3	2021-04-26 20:16:45.677	adventure-works\jillian0	3	279-555-0130	NULL


-- Insert multiple rows
INSERT INTO SalesLT.CallLog
VALUES
(DATEADD(mi,-2, GETDATE()), 'adventure-works\jillian0', 4, '710-555-0173', NULL),
(DEFAULT, 'adventure-works\shu0', 5, '828-555-0186', 'Called to arrange deliver of order 10987');
GO
SELECT * FROM SalesLT.CallLog;
GO

--CallID	CallTime	SalesPerson	CustomerID	PhoneNumber	Notes
--1	2015-01-01 12:30:00.000	adventure-works\pamela0	1	245-555-0173	Returning call re: enquiry about delivery
--2	2021-04-26 20:15:56.693	adventure-works\david8	2	170-555-0127	NULL
--3	2021-04-26 20:16:45.677	adventure-works\jillian0	3	279-555-0130	NULL
--4	2021-04-26 20:15:15.940	adventure-works\jillian0	4	710-555-0173	NULL
--5	2021-04-26 20:17:15.940	adventure-works\shu0	5	828-555-0186	Called to arrange deliver of order 10987


-- Insert the results of a query
INSERT INTO SalesLT.CallLog (SalesPerson, CustomerID, PhoneNumber, Notes)
	SELECT SalesPerson, CustomerID, Phone, 'Sales promotion call'
	FROM SalesLT.Customer
	WHERE CompanyName = 'Big-Time Bike Store';
GO
SELECT * FROM SalesLT.CallLog;
GO

--CallID	CallTime	SalesPerson	CustomerID	PhoneNumber	Notes
--1	2015-01-01 12:30:00.000	adventure-works\pamela0	1	245-555-0173	Returning call re: enquiry about delivery
--2	2021-04-26 20:15:56.693	adventure-works\david8	2	170-555-0127	NULL
--3	2021-04-26 20:16:45.677	adventure-works\jillian0	3	279-555-0130	NULL
--4	2021-04-26 20:15:15.940	adventure-works\jillian0	4	710-555-0173	NULL
--5	2021-04-26 20:17:15.940	adventure-works\shu0	5	828-555-0186	Called to arrange deliver of order 10987
--6	2021-04-26 20:18:19.903	adventure-works\shu0	529	669-555-0149	Sales promotion call
--7	2021-04-26 20:18:19.903	adventure-works\shu0	29784	669-555-0149	Sales promotion call


-- Retrieving inserted identity
INSERT INTO SalesLT.CallLog (SalesPerson, CustomerID, PhoneNumber)
VALUES
('adventure-works\josé1', 10, '150-555-0127');
GO
SELECT SCOPE_IDENTITY() AS AUTONUMERICO;
GO

--AUTONUMERICO
--8

SELECT * FROM SalesLT.CallLog;
GO
-- (8 rows affected)

--Overriding Identity. 
-- NOSOTROS CONTROLAMOS EL AUTONUMERICO

SET IDENTITY_INSERT SalesLT.CallLog ON;
GO
INSERT INTO SalesLT.CallLog (CallID, SalesPerson, CustomerID, PhoneNumber)
VALUES
(9, 'adventure-works\josé1', 11, '926-555-0159');
GO


SELECT * FROM SalesLT.CallLog;
GO

--CallID	CallTime	SalesPerson	CustomerID	PhoneNumber	Notes
--9	2021-04-26 20:20:54.840	adventure-works\josé1	11	926-555-0159	NULL

-- (9 rows affected)
SELECT SCOPE_IDENTITY() AS AUTONUMERICO;
GO

--AUTONUMERICO
--9


-- DEVUEVO CONTROL IDENTITY AL SISTEMA

SET IDENTITY_INSERT SalesLT.CallLog OFF;
GO


-- AL INSTENTAR INSERTA EL AUTONUMERICO 10 ERROR

INSERT INTO SalesLT.CallLog (CallID, SalesPerson, CustomerID, PhoneNumber)
VALUES
(10, 'adventure-works\ana', 12, '927-555-0159');
GO

-- Msg 544, Level 16, State 1, Line 74
-- Cannot insert explicit value for identity column in table 'CallLog' when IDENTITY_INSERT is set to OFF.


--Overriding Identity
SET IDENTITY_INSERT SalesLT.CallLog ON;
Go
INSERT INTO SalesLT.CallLog (CallID, SalesPerson, CustomerID, PhoneNumber)
VALUES
(10, 'adventure-works\ana', 12, '927-555-0159');
GO

-- (1 row affected)


SELECT * FROM SalesLT.CallLog;
GO
-- (10 rows affected)

--CallID	CallTime	SalesPerson	CustomerID	PhoneNumber	Notes
--10	2021-04-26 20:23:34.787	adventure-works\ana	12	927-555-0159	NULL

SELECT SCOPE_IDENTITY();
GO

-- 10

INSERT INTO SalesLT.CallLog (SalesPerson, CustomerID, PhoneNumber)
VALUES
('adventure-works\juan', 13, '927-556-0159');
GO

--Msg 545, Level 16, State 1, Line 102
--Explicit value must be specified for identity column in table 'CallLog' either when IDENTITY_INSERT is set to ON or when a replication user is inserting into a NOT FOR REPLICATION identity column.

--Overriding Identity
SET IDENTITY_INSERT SalesLT.CallLog OFF;
Go

INSERT INTO SalesLT.CallLog (SalesPerson, CustomerID, PhoneNumber)
VALUES
('adventure-works\juan', 13, '927-556-0159');
GO

-- PERO ......

--Msg 547, Level 16, State 0, Line 114
--The INSERT statement conflicted with the FOREIGN KEY constraint "FK__CallLog__Custome__0A9D95DB". The conflict occurred in database "AdventureWorksLT", table "SalesLT.Customer", column 'CustomerID'.
--The statement has been terminated.

SELECT * FROM SalesLT.CallLog;
GO
SELECT SCOPE_IDENTITY();
GO


SELECT * FROM SalesLT.Customer
GO

-- CUSTOMER_ID No tiene 13 14 15
-- PROBLEMA INTEGRIDAD REFERENCIAL

-- PERO SI QUE TIENE CUSTOMERID 16

--CustomerID	NameStyle	Title	FirstName	MiddleName	LastName	Suffix	CompanyName	SalesPerson	EmailAddress	Phone	PasswordHash	PasswordSalt	rowguid	ModifiedDate
--16	0	Mr.	Christopher	R.	Beck	Jr.	Bulk Discount Store	adventure-works\jae0	christopher1@adventure-works.com	1 (11) 500 555-0132	sKt9daCzEEKWAzivEGPOp8tmaM1R3I+aJfcBjzJRFLo=	8KfYx/4=	C9381589-D31C-4EFE-8978-8D3449EB1F0F	2006-09-01 00:00:00.000

INSERT INTO SalesLT.CallLog (SalesPerson, CustomerID, PhoneNumber)
VALUES
('adventure-works\juan', 16, '927-556-0159');
GO

-- (1 row affected)


SELECT * FROM SalesLT.CallLog;
GO

-- (11 rows affected)

-- SALTO 1 EL AUTONUMERICO CON EL ERROR

--CallID	CallTime	SalesPerson	CustomerID	PhoneNumber	Notes
--12	2021-04-26 20:26:58.653	adventure-works\juan	16	927-556-0159	NULL


-- INNER JOIN 

SELECT c.CallID,c.SalesPerson,c.CustomerID,c.PhoneNumber,cu.CustomerID,cu.CompanyName
FROM SalesLT.CallLog c JOIN SalesLT.Customer cu
ON c.CustomerID = cu.CustomerID
GO