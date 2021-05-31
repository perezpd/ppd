

-- Row Level Security with SQL Server 2016: Part 1 – Allow Access to Only a Subset of Rows Using Row Level Securi

-- https://www.databasejournal.com/features/mssql/row-level-security-with-sql-server-2016.html

USE master;
GO
DROP DATABASE IF EXISTS RLS_DEMO
GO
CREATE DATABASE RLS_DEMO;
GO
USE RLS_DEMO;
GO
CREATE USER Jane WITHOUT LOGIN;
CREATE USER Dick WITHOUT LOGIN;
CREATE USER Sally WITHOUT LOGIN;
GO
 
CREATE TABLE Customer(
       CustomerName varchar(100) NULL,
       CustomerEmail varchar(100) NULL,
       SalesPersonUserName varchar(20) NULL
);  
GO
GRANT SELECT ON dbo.Customer TO Jane;
GRANT SELECT ON dbo.Customer TO Dick;
GRANT SELECT ON dbo.Customer TO Sally;
GO
 
INSERT INTO Customer VALUES 
   ('ABC Company','Manger@ABC.COM','Jane'),
   ('Info Services','info@AInfaSerice.COM','Jane'),
   ('Washing-R-Us','HeadWasher@washrus.COM','Dick'),
   ('Blue Water Utilities','marketing@bluewater.COM','Dick'),
   ('Star Brite','steve@starbright.COM','Jane'),
   ('Rainy Day Fund','Tom@rainydayfund','Sally');
GO

SELECT * FROM Customer
GO

CREATE OR ALTER FUNCTION fn_RowLevelSecurity (@FilterColumnName sysname)
RETURNS TABLE
WITH SCHEMABINDING
as
RETURN SELECT 1 as fn_SecureCustomerData
-- filter out records based on database user name 
where @FilterColumnName = user_name();
GO

CREATE SECURITY POLICY FilterCustomer
ADD FILTER PREDICATE dbo.fn_RowLevelSecurity(SalesPersonUserName)
ON dbo.Customer
WITH (STATE = ON); 
GO


EXECUTE AS USER = 'Jane';
PRINT 'Jane''s Customers';
SELECT CustomerName, CustomerEmail, SalesPersonUserName
FROM Customer;
REVERT;
 
EXECUTE AS USER = 'Dick';
PRINT 'Dick''s Customers';
SELECT CustomerName, CustomerEmail, SalesPersonUserName
FROM Customer;
REVERT;
 
EXECUTE AS USER = 'Sally';
PRINT 'Sally''s Customers';
SELECT CustomerName, CustomerEmail, SalesPersonUserName
FROM Customer;
REVERT;

--Reusing the Predicate Function for other Security Policies
--If you review the predicate function dbo.fn_RowLevelSecurity that I created above you would see that that function didn’t reference my dbo.Customer.  This function was able to restricted rows on the dbo.Customer table, because the security policy FilterCustomer referenced that predicate function when I created this policy.   

-- Since my predicate filter logic didn’t filter on a specific table I can reuse that filter to restrict row level access from other tables, provided they require the same filter logic.   To demonstrate this let me create and populate a new table then associate my new table with same dbo.fn_RowLevelSecurity filter predicate function using the following code:

CREATE TABLE Supplier(
       SupplierName varchar(100) NULL,
       SupplierEmail varchar(100) NULL,
       SalesPersonUserName varchar(20) NULL
);  
GO
GRANT SELECT ON dbo.Supplier TO Jane;
GRANT SELECT ON dbo.Supplier TO Dick;
GRANT SELECT ON dbo.Supplier TO Sally;
GO
INSERT INTO Supplier VALUES 
   ('ABC Parts','Maanger@ABC_Parts.COM','Jane'), 
   ('Cool Tech','info@CoolTech.COM','Jane'),
   ('US Printing','info@USPrinting.COM','Dick'),                                         
   ('Widget NW','marketing@WidgetNW.COM','Sally');
GO
CREATE SECURITY POLICY FilterSupplier
ADD FILTER PREDICATE dbo.fn_RowLevelSecurity(SalesPersonUserName)
ON dbo.Supplier
WITH (STATE = ON);
-- Now that I created this new security policy named FilterSupplier let me verify that my Supplier table will be filtering rows using the same predict function that I used to filter the dbo.Customer table by running the following code.  Run this code yourself to verify that my new security policy FilterSupplier does in fact filter out rows correctly when each database user tries to select rows from the dbo.Supplier table:

EXECUTE AS USER = 'Jane';
PRINT 'Jane''s Suppliers';
SELECT * FROM dbo.Supplier;
REVERT;
 
EXECUTE AS USER = 'Dick';
PRINT 'Dick''s Suppliers';
SELECT * FROM dbo.Supplier;
REVERT;
 
EXECUTE AS USER = 'Sally';
PRINT 'Sally''s Suppliers';
SELECT * FROM dbo.Supplier;
REVERT;
GO

-- Row Level Security with SQL Server 2016: Part 2 - Blocking Updates at the Row Level
-- https://www.databasejournal.com/features/mssql/row-level-security-with-sql-server-2016-part-2-blocking-updates-at-the-row-level.html


USE master;
GO
 DROP DATABASE IF EXISTS RLS_DEMO
 GO
CREATE DATABASE RLS_DEMO;
GO
USE RLS_DEMO;
GO
CREATE USER Jane WITHOUT LOGIN;
CREATE USER Dick WITHOUT LOGIN;
CREATE USER Sally WITHOUT LOGIN;
GO
DROP TABLE IF EXISTS RLS_DEMO
GO
CREATE TABLE Customer(
       CustomerName varchar(100) NULL,
       CustomerEmail varchar(100) NULL,
       SalesPersonUserName varchar(20) NULL
);  
GO
GRANT SELECT ON dbo.Customer TO Jane;
GRANT SELECT ON dbo.Customer TO Dick;
GRANT SELECT ON dbo.Customer TO Sally;
GO
 
INSERT INTO Customer VALUES 
   ('ABC Company','Manager@ABC.COM','Jane'),
   ('Info Services','info@AInfaSerice.COM','Jane'),
   ('Washing-R-Us','HeadWasher@washrus.COM','Dick'),
   ('Blue Water Utilities','marketing@bluewater.COM','Dick'),
   ('Star Brite','steve@starbright.COM','Jane'),
   ('Rainy Day Fund','Tom@rainydayfund','Sally');
GO
SELECT * FROM Customer
GO

--CustomerName	CustomerEmail	SalesPersonUserName
--ABC Company	Manager@ABC.COM	Jane
--Info Services	info@AInfaSerice.COM	Jane
--Washing-R-Us	HeadWasher@washrus.COM	Dick
--Blue Water Utilities	marketing@bluewater.COM	Dick
--Star Brite	steve@starbright.COM	Jane
--Rainy Day Fund	Tom@rainydayfund	Sally


-- FUNCTION RLS IN-LINE TABLE
CREATE OR ALTER FUNCTION fn_RowLevelSecurity (@FilterColumnName sysname)
RETURNS TABLE
WITH SCHEMABINDING
as
	RETURN SELECT 1 as fn_SecureCustomerData
	-- filter out records based on database user name 
	where @FilterColumnName = user_name();
GO

-- SECURITY POLICY FILTER PREDICATE. NOT ALLOW READ

CREATE SECURITY POLICY FilterCustomer
ADD FILTER PREDICATE dbo.fn_RowLevelSecurity(SalesPersonUserName)
ON dbo.Customer
WITH (STATE = ON); 
GO 
-- Granting UPDATE and INSERT access
GRANT UPDATE, INSERT ON dbo.Customer TO Jane;
GRANT UPDATE, INSERT ON dbo.Customer TO Dick;
GRANT UPDATE, INSERT ON dbo.Customer TO Sally;
GO

--Demonstrate How a Sales Person can Update Records
--To show you how a sales person can use an UPDATE or INSERT statement to cause rows to no longer be viewable after it was inserted or updated I will run the following code snippet:

PRINT USER
GO
-- dbo

SELECT * 
FROM Customer
--WHERE CustomerName = 'ABC Company'
GO
-- (0 rows affected)

-- UPDATE customer record
EXECUTE AS USER = 'Jane';
GO
SELECT * FROM Customer
GO

--CustomerName		CustomerEmail	SalesPersonUserName
--ABC Company			Manager@ABC.COM			Jane
--Info Services		info@AInfaSerice.COM	Jane
--Star Brite			steve@starbright.COM	Jane

-- PUEDE ACTUALIZAR FILAS QUE NO SON SUYAS
UPDATE Customer 
SET CustomerEmail = 'Jack@ABC.COM', 
    SalesPersonUserName = 'Dick' 
WHERE CustomerName = 'ABC Company';
GO
-- (1 row affected)

-- SIN EMBARGO, NO PUEDE VER LA FILA QUE ACTUALIZO

SELECT * FROM Customer
GO

--CustomerName	CustomerEmail	SalesPersonUserName
--Info Services	info@AInfaSerice.COM	Jane
--Star Brite	steve@starbright.COM	Jane

-- PUEDE INSERT FILAS QUE NO SON SUYAS
PRINT USER
GO
-- Jane

-- INSERT new customer
INSERT INTO Customer VALUES 
   ('Rock The Dock','Rocky@RockTheDock.COM','Sally');
GO

-- (1 row affected)


-- NO VE LO QUE INSERTO PERO PUDO INSERTAR

PRINT 'Jane''s Customers after UPDATE and INSERT';
GO
SELECT CustomerName, CustomerEmail, SalesPersonUserName
FROM Customer;
GO

--CustomerName	CustomerEmail	SalesPersonUserName
--Info Services	info@AInfaSerice.COM	Jane
--Star Brite	steve@starbright.COM	Jane

REVERT;
GO

-- BLOCK PREDICATES

--Blocking Updates and Inserts at the Row Level
--In order to keep Jane from updating or inserting records that she can’t see after the insert or update statement is executed, I will need to create a block predicate that keeps her from inserting our updating records that don’t have her user name in the SalesPersonUserName.

-- To implement the business logic requirements I’m going to alter my existing security profile by adding a couple of blocking predicates.  Here is the code to do that:

ALTER SECURITY POLICY FilterCustomer
ADD BLOCK PREDICATE dbo.fn_RowLevelSecurity(SalesPersonUserName)
ON dbo.Customer AFTER UPDATE, 
ADD BLOCK PREDICATE dbo.fn_RowLevelSecurity(SalesPersonUserName)
ON dbo.Customer AFTER INSERT;
GO 
--The first “ADD BLOCK PREDICATE” clause with the “AFTER UPDATE” clause, 
--blocks updates to rows that don’t pass the filter predicate.  
--The second “ADD BLOCK PREDICATE” clause, with the “AFTER INSERT” clause, 
--blocks inserts of rows that don’t pass the filter predicate.  

--To verify these two new block predicates work I first run the code in the “Setting up some Test Data” section, and then I will run the following code:

-- UPDATE customer record
EXECUTE AS USER = 'Jane';
GO

-- ESTO ES LO QUE JANE VE CON FILTER PREDICATE

SELECT CustomerName, CustomerEmail, SalesPersonUserName
FROM Customer;
GO

--CustomerName	CustomerEmail	SalesPersonUserName
--Info Services	info@AInfaSerice.COM	Jane
--Star Brite	steve@starbright.COM	Jane

-- JANE CON BLOCK PREDICATE
-- SalesPersonUserName = 'Dick'

UPDATE Customer 
SET CustomerEmail = 'bloquear@ABC.COM', 
    SalesPersonUserName = 'Dick' 
WHERE CustomerName = 'ABC Company';
GO

-- (0 rows affected)

-- INSERT new customer
INSERT INTO Customer VALUES 
   ('Rock The Dock','Rocky@RockTheDock.COM','Sally');
go

-- Msg 33504, Level 16, State 1, Line 307
-- The attempted operation failed because the target object 
--'RLS_DEMO.dbo.Customer' has a block predicate that conflicts with 
--this operation. If the operation is performed on a view, 
--the block predicate might be enforced on the underlying table. 
--Modify the operation to target only the rows that are allowed by the 
--block predicate.


PRINT 'Jane''s Customers after UPDATE and INSERT';
SELECT CustomerName, CustomerEmail, SalesPersonUserName
FROM Customer;
GO

--CustomerName		CustomerEmail		SalesPersonUserName
--Info Services		info@AInfaSerice.COM	Jane
--Star Brite		steve@starbright.COM	Jane
REVERT;
GO 

SELECT CustomerName, CustomerEmail, SalesPersonUserName
FROM Customer;
GO

-- (0 rows affected)
EXECUTE AS USER = 'Dick';
GO
print user
go
-- Dick

SELECT CustomerName, CustomerEmail, SalesPersonUserName
FROM Customer;
GO

--CustomerName	CustomerEmail			SalesPersonUserName
--ABC Company	Jack@ABC.COM					Dick
--Washing-R-Us	HeadWasher@washrus.COM			Dick
--Blue Water Utilities	marketing@bluewater.COM	Dick