USE master;
GO

-- procedure
CREATE OR ALTER PROCEDURE procedureTestPPD
AS
BEGIN
  PRINT ('MY FIRST CREATE OR ALTER PROCEDURE by PPD');
END;
GO
-- user function
CREATE OR ALTER FUNCTION FunctionTestPPD()
RETURNS VARCHAR(100)
AS
BEGIN
  RETURN('MY FIRST CREATE OR ALTER FUNCTION by PPD')
END;
GO

-- tests on master

EXECUTE procedureTestPPD;
GO

--MY FIRST CREATE OR ALTER PROCEDURE by PPD

SELECT dbo.FunctionTestPPD() as result;
GO

--result
--MY FIRST CREATE OR ALTER FUNCTION by PPD

-- views
CREATE OR ALTER VIEW ViewTestPPD
AS
  SELECT 'MY FIRST CREATE OR ALTER VIEW by PPD' AS COL;
GO

-- test
SELECT * FROM ViewTestPPD;
GO

--COL
--MY FIRST CREATE OR ALTER VIEW by PPD


-- to test with a trigger we create a table in tempdb
USE [tempdb];
GO

DROP TABLE IF EXISTS Products;
GO

CREATE TABLE Products(
	[id_prod] [char](8) NOT NULL,
	[nombre] [varchar](100) NOT NULL,
	[existencia] [int] NOT NULL);
GO


-- trigger
CREATE OR ALTER TRIGGER TriggerTestPPD
ON Products
AFTER INSERT, UPDATE
AS
RAISERROR ('MY FIRST CREATE OR ALTER TRIGGER by PPD', 1, 10);


INSERT INTO Products
	VALUES ('PPD001','Muestra',10);
GO

-- MY FIRST CREATE OR ALTER TRIGGER by PPD
--Msg 50000, Level 1, State 10

--(1 row affected)

SELECT * FROM Products;
GO

--id_prod		nombre		existencia
--PPD001  		Muestra		10
