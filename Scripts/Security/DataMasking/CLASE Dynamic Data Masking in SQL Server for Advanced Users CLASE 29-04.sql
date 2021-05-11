
-- DYNAMIC DATA MASKING (DDM)

-- Create sample database ITSalesV2
DROP DATABASE IF EXISTS ITSalesV2
GO
CREATE DATABASE ITSalesV2;
GO

USE [ITSalesV2]
GO

DROP TABLE IF EXISTS [MonthlySale]
GO

-- (2) Create MonthlySale table
CREATE TABLE [dbo].[MonthlySale](
	[SaleId] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[SellingDate] [datetime2](7) NULL,
	[Customer] [varchar](50) NULL,
	[Email] [varchar] (200) NULL,
	[Product] [varchar](150) NULL,
	[TotalPrice] [decimal](10, 2) NULL,
)
GO

-- (2) Populate monthly sale table
SET IDENTITY_INSERT [dbo].[MonthlySale] ON
INSERT INTO [dbo].[MonthlySale] ([SaleId], [SellingDate], [Customer],[Email], [Product], [TotalPrice]) VALUES (1, N'2019-05-01 00:00:00', N'Asif', N'Asif@companytest-0001.com', N'Dell Laptop', CAST(300.00 AS Decimal(10, 2)))
INSERT INTO [dbo].[MonthlySale] ([SaleId], [SellingDate], [Customer],[Email], [Product], [TotalPrice]) VALUES (2, N'2019-05-02 00:00:00', N'Mike',N'Mike@companytest-0002.com', N'Dell Laptop', CAST(300.00 AS Decimal(10, 2)))
INSERT INTO [dbo].[MonthlySale] ([SaleId], [SellingDate], [Customer],[Email], [Product], [TotalPrice]) VALUES (3, N'2019-05-02 00:00:00', N'Adil',N'Adil@companytest-0003.com',N'Lenovo Laptop', CAST(350.00 AS Decimal(10, 2)))
INSERT INTO [dbo].[MonthlySale] ([SaleId], [SellingDate], [Customer],[Email], [Product], [TotalPrice]) VALUES (4, N'2019-05-03 00:00:00', N'Sarah',N'Sarah@companytest-0004', N'HP Laptop', CAST(250.00 AS Decimal(10, 2)))
INSERT INTO [dbo].[MonthlySale] ([SaleId], [SellingDate], [Customer],[Email], [Product], [TotalPrice]) VALUES (5, N'2019-05-05 00:00:00', N'Asif', N'Asif@companytest-0001.com', N'Dell Desktop', CAST(200.00 AS Decimal(10, 2)))
INSERT INTO [dbo].[MonthlySale] ([SaleId], [SellingDate], [Customer],[Email], [Product], [TotalPrice]) VALUES (6, N'2019-05-10 00:00:00', N'Sam',N'Sam@companytest-0005', N'HP Desktop', CAST(300.00 AS Decimal(10, 2)))
INSERT INTO [dbo].[MonthlySale] ([SaleId], [SellingDate], [Customer],[Email], [Product], [TotalPrice]) VALUES (7, N'2019-05-12 00:00:00', N'Mike',N'Mike@companytest-0002.comcom', N'iPad', CAST(250.00 AS Decimal(10, 2)))
INSERT INTO [dbo].[MonthlySale] ([SaleId], [SellingDate], [Customer],[Email], [Product], [TotalPrice]) VALUES (8, N'2019-05-13 00:00:00', N'Mike',N'Mike@companytest-0002.comcom', N'iPad', CAST(250.00 AS Decimal(10, 2)))
INSERT INTO [dbo].[MonthlySale] ([SaleId], [SellingDate], [Customer],[Email], [Product], [TotalPrice]) VALUES (9, N'2019-05-20 00:00:00', N'Peter',N'Peter@companytest-0006', N'Dell Laptop', CAST(350.00 AS Decimal(10, 2)))
INSERT INTO [dbo].[MonthlySale] ([SaleId], [SellingDate], [Customer],[Email], [Product], [TotalPrice]) VALUES (10, N'2019-05-25 00:00:00', N'Peter',N'Peter@companytest-0006', N'Asus Laptop', CAST(400.00 AS Decimal(10, 2)))
SET IDENTITY_INSERT [dbo].[MonthlySale] OFF
GO
--- END POPULATE

SELECT * FROM [MonthlySale]
GO

-- View monthly sales data
SELECT
  s.SaleId
 ,s.SellingDate
 ,s.Customer
 ,s.Email
 ,s.Product
 ,s.TotalPrice
FROM dbo.MonthlySale s
GO

-- Create DataUser to have Select access to MonthlySale table
CREATE USER DataUser WITHOUT LOGIN; 
GO
GRANT SELECT ON MonthlySale TO DataUser;
GO

-- Stored procedure to check dynamic data masking status
CREATE OR ALTER PROC ShowMaskingStatus
AS
BEGIN
		SET NOCOUNT ON 
		SELECT c.name, tbl.name as table_name, c.is_masked, c.masking_function  
		FROM sys.masked_columns AS c  
		JOIN sys.tables AS tbl   
			ON c.[object_id] = tbl.[object_id]  
		WHERE is_masked = 1;
END
GO

EXEC ShowMaskingStatus
GO

-- Dynamic Data Masking (DDM) Types
-- There are four common types of Dynamic data masking in SQL Server:

--1. Default Data Mask(s)
--2. Partial Data Mask(s)
--3. Random Data Mask(s)
--4. Custom String Data Mask(s)

--We are now going to implement all the four common types of dynamic data masking.

--Default dynamic data masking of Email column 
ALTER TABLE MonthlySale
ALTER COLUMN Email varchar(200) MASKED WITH (FUNCTION = 'default()');
GO

EXEC ShowMaskingStatus
GO

--name	table_name	is_masked	masking_function
--Email	MonthlySale		1			default()

-- Execute SELECT as DataUser
EXECUTE AS USER = 'DataUser';  
GO
-- View monthly sales 
SELECT s.SaleId,s.SellingDate,s.Customer,s.Email,s.Product,s.Product 
from dbo.MonthlySale s
GO

--SaleId	SellingDate			Customer	  Email	Product	Product
--1	2019-05-01 00:00:00.0000000	Asif			xxxx	Dell Laptop	Dell Laptop
--2	2019-05-02 00:00:00.0000000	Mike			xxxx	Dell Laptop	Dell Laptop
--3	2019-05-02 00:00:00.0000000	Adil			xxxx	Lenovo Laptop	Lenovo Laptop
--4	2019-05-03 00:00:00.0000000	Sarah			xxxx	HP Laptop	HP Laptop
--5	2019-05-05 00:00:00.0000000	Asif			xxxx	Dell Desktop	Dell Desktop
--6	2019-05-10 00:00:00.0000000	Sam				xxxx	HP Desktop	HP Desktop
--7	2019-05-12 00:00:00.0000000	Mike			xxxx	iPad	iPad
--8	2019-05-13 00:00:00.0000000	Mike			xxxx	iPad	iPad
--9	2019-05-20 00:00:00.0000000	Peter			xxxx	Dell Laptop	Dell Laptop
--10	2019-05-25 00:00:00.0000000	Peter		xxxx	Asus Laptop	Asus Laptop

-- Revert the User back to what user it was before
REVERT;
GO

PRINT USER
GO
-- DBO

-- View monthly sales 
SELECT s.SaleId,s.SellingDate,s.Customer,s.Email,s.Product,s.Product 
from dbo.MonthlySale s
GO

--SaleId	SellingDate				Customer	Email						Product	Product
--1	2019-05-01 00:00:00.0000000	     Asif	Asif@companytest-0001.com	Dell Laptop	Dell Laptop

-- Partial data masking of Customer names

ALTER TABLE MonthlySale
ALTER COLUMN [Customer] ADD MASKED WITH (FUNCTION = 'partial(1,"XXXXXXX",0)')
GO
EXEC ShowMaskingStatus
GO

--name		table_name		is_masked	masking_function
--Customer	MonthlySale			1		partial(1, "XXXXXXX", 0)
--Email		MonthlySale			1		default()

-- Execute SELECT as DataUser
EXECUTE AS USER = 'DataUser';  

-- View monthly sales as DataUser
SELECT s.SaleId,s.SellingDate,s.Customer,s.Email,s.Product,s.Product 
from dbo.MonthlySale s
GO

--SaleId	SellingDate					Customer	Email	Product	Product
--1		2019-05-01 00:00:00.0000000		AXXXXXXX	xxxx	Dell Laptop	Dell Laptop

-- Revert the User back to what user it was before
REVERT;
GO
PRINT USER
GO
SELECT s.SaleId,s.Customer,s.Email 
from dbo.MonthlySale s
GO

--SaleId		Customer			Email
--1				Asif			Asif@companytest-0001.com


--Random dynamic data masking of TotalPrice column 

ALTER TABLE MonthlySale
ALTER COLUMN [TotalPrice] decimal(10,2) MASKED WITH (FUNCTION = 'random(1, 12)')
GO

EXEC ShowMaskingStatus
GO
-- SUMMARY OF PROCEDURES DONE
--name			table_name		is_masked		masking_function
--Customer		MonthlySale		1				partial(1, "XXXXXXX", 0)
--Email			MonthlySale		1				default()
--TotalPrice	MonthlySale		1				random(1.00, 12.00)

-- Execute SELECT as DataUser
EXECUTE AS USER = 'DataUser';  
GO
-- View monthly sales 
SELECT s.SaleId,s.SellingDate,s.Customer,s.Email,s.Product,s.TotalPrice 
from dbo.MonthlySale s
GO
SELECT s.SaleId,s.Product,s.TotalPrice 
from dbo.MonthlySale s
GO

--SaleId	Product				TotalPrice
--1			Dell Laptop				8.49

-- Revert the User back to what user it was before
REVERT;
GO
-- DBO
-- View monthly sales 
SELECT s.SaleId,s.SellingDate,s.Customer,s.Email,s.Product,s.TotalPrice 
from dbo.MonthlySale s
GO

--SaleId	SellingDate	Customer	Email	Product	TotalPrice
--1	2019-05-01 00:00:00.0000000	Asif	Asif@companytest-0001.com	Dell Laptop	300.00

SELECT s.SaleId,s.Product,s.TotalPrice 
from dbo.MonthlySale s
GO

--SaleId	Product				TotalPrice
--1			Dell Laptop				300.00


--Custom string dynamic data masking of Product column 

ALTER TABLE MonthlySale
ALTER COLUMN [Product] ADD MASKED WITH (FUNCTION = 'partial(1,"---",1)')
GO

EXEC ShowMaskingStatus
GO

--name			table_name		is_masked		masking_function
--Customer		MonthlySale		1			partial(1, "XXXXXXX", 0)
--Email			MonthlySale		1			default()
--Product		MonthlySale		1			partial(1, "---", 1)
--TotalPrice	MonthlySale		1			random(1.00, 12.00)

-- Execute SELECT as DataUser
EXECUTE AS USER = 'DataUser';  
GO
-- View monthly sales 
SELECT s.SaleId,s.SellingDate,s.Customer,s.Email,s.Product,s.TotalPrice 
from dbo.MonthlySale s
GO

--SaleId	SellingDate				Customer	Email	Product	TotalPrice
--1		2019-05-01 00:00:00.0000000	AXXXXXXX	xxxx	D---p	8.96

-- View monthly sales 
SELECT s.SaleId,s.Product 
from dbo.MonthlySale s
GO

--SaleId	Product
--1			D---p


-- Revert the User back to what user it was before
REVERT;
GO
PRINT USER
GO

-- dbo

-- View monthly sales 
SELECT s.SaleId,s.Product 
from dbo.MonthlySale s
GO

--SaleId	Product
--1			Dell Laptop


GRANT UNMASK TO DataUser
GO

-- Execute SELECT as DataUser
EXECUTE AS USER = 'DataUser';  
GO
-- View monthly sales 
SELECT s.SaleId,s.SellingDate,s.Customer,s.Email,s.Product,s.TotalPrice 
from dbo.MonthlySale s
GO

--SaleId	SellingDate			Customer	Email						Product			TotalPrice
--1	2019-05-01 00:00:00.0000000		Asif	Asif@companytest-0001.com	Dell Laptop			300.00


-- Revert the User back to what user it was before
REVERT;
GO

-- Dropping a Dynamic Data Mask

ALTER TABLE MonthlySale
ALTER COLUMN Email DROP MASKED;
GO

EXEC ShowMaskingStatus
GO

--name	table_name	is_masked	masking_function
--Customer	MonthlySale	1	partial(1, "XXXXXXX", 0)
--Product	MonthlySale	1	partial(1, "---", 1)
--TotalPrice	MonthlySale	1	random(1.00, 12.00)


REVOKE  UNMASK FROM  DataUser
GO

-- Execute SELECT as DataUser
EXECUTE AS USER = 'DataUser';  
GO
-- View monthly sales 
SELECT s.SaleId,s.SellingDate,s.Customer,s.Email,s.Product,s.TotalPrice 
from dbo.MonthlySale s
GO

-- 1	2019-05-01 00:00:00.0000000	AXXXXXXX	Asif@companytest-0001.com	D---p	3.91

-- View monthly sales 
SELECT S.Customer,s.Email,s.Product,s.TotalPrice 
from dbo.MonthlySale s
GO


--Customer	Email						Product	TotalPrice
--AXXXXXXX	Asif@companytest-0001.com	D---p	7.65


-- Revert the User back to what user it was before
REVERT;
GO
