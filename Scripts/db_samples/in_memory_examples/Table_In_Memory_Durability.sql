-- https://mostafaelmasry.com/2015/03/25/durable-vs-non-durable-tables-in-memory-oltp/


USE master
GO
DROP DATABASE IF EXISTS sql2017_WorkShop
go
CREATE DATABASE [sql2017_WorkShop]
 CONTAINMENT = NONE
 ON PRIMARY
( NAME = N'sql2017_WorkShop', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\sql2017_WorkShop.mdf' , SIZE = 4288KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ),
 FILEGROUP [sql2017_WorkShop_mod] CONTAINS MEMORY_OPTIMIZED_DATA DEFAULT
( NAME = N'sql2017_WorkShop_mod', FILENAME = N'c:\sql2017_WorkShop_mod' , MAXSIZE = UNLIMITED)
 LOG ON
( NAME = N'sql2017_WorkShop_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\sql2017_WorkShop_log.ldf' , SIZE = 1072KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

USE [sql2017_WorkShop]
go
DROP TABLE IF EXISTS Customer
GO
Create Table Customer
(
Customer_ID INT NOT NULL Primary key nonclustered Hash WITH (bucket_Count = 1000000),
FirstName Nvarchar(200) NOT NULL,
lastname Nvarchar(200)NOT NULL
)
With(Memory_optimized=on,Durability=SCHEMA_And_DATA)
GO


DROP TABLE IF EXISTS Non_Durable_Customer
go
Create Table Non_Durable_Customer
(
Customer_ID INT NOT NULL Primary key nonclustered Hash WITH (bucket_Count = 1000000),
FirstName Nvarchar(200) NOT NULL,
lastname Nvarchar(200)NOT NULL
)
With(Memory_optimized=on,Durability=SCHEMA_ONLY)
GO

-- CUSTOMER
set nocount on
go
DECLARE @counter INT
SET @counter = 1
WHILE @counter <= 100000
 BEGIN
 INSERT INTO dbo.Customer
 VALUES (@counter, 'mustafa','Elmasry'),
 (@counter+1, 'Amro','Silem'),
 (@counter+2, 'Shehab','Elnagar')

SET @counter = @counter + 3
 END
GO

SELECT * FROM Customer
GO
-- NO DURABLE

set nocount on
go
DECLARE @counter INT
SET @counter = 1
WHILE @counter <= 100000
 BEGIN
 INSERT INTO dbo.Non_Durable_Customer
 VALUES (@counter, 'mustafa','Elmasry'),
 (@counter+1, 'Amro','Silem'),
 (@counter+2, 'Shehab','Elnagar')

SET @counter = @counter + 3
 END
GO

--FASTER

SELECT * FROM Non_Durable_Customer
GO

Use Master
go
ALTER DATABASE sql2017_WorkShop SET OFFLINE WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE sql2017_WorkShop SET ONLINE
GO

-- Check now the Count of data in both tables you will found No Data in Non-Durable in memory table

USE [sql2017_WorkShop]
GO
SELECT * FROM Customer
GO
SELECT * FROM Non_Durable_Customer
GO
Select Count(1) AS CONTADORNODURABLE from Non_Durable_Customer 
GO
Select Count(1) AS CONTADORDURABLE from Customer
GO
--So at the End take care from Durable table and non-Durable table in memory Optimized table you should know when you need to use this or this if you don’t care about the data loss you can use non-Durable table in memory
--table.


