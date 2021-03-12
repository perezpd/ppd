/*
BASED ON THIS DOCUMENTATION
-- https://docs.microsoft.com/en-us/sql/relational-databases/in-memory-oltp/the-memory-optimized-filegroup?view=sql-server-2017
BEFORE CREATING THE SPECIFIC FILE GROUP WE GOT THIS ERROR
-- Creating Memory Optimized Table Template 
Msg 41337, Level 16, State 100, Line 22
Cannot create memory optimized tables. To create memory optimized tables, 
the database must have a MEMORY_OPTIMIZED_FILEGROUP that is online and has at least one container.
*/
USE containers_ppd_v1
GO

-- We need to add M.O.D. filegroup and its special container
ALTER DATABASE containers_ppd_v1
ADD FILEGROUP containers_ppd_v1_mod CONTAINS MEMORY_OPTIMIZED_DATA;
go

-- folder must exists to set as the container file to the M.O.D.
ALTER DATABASE containers_ppd_v1
ADD FILE
	(name='containers_ppd_v1_mod1',
	filename='c:\data\containers_ppd_v1')
	TO FILEGROUP containers_ppd_v1_mod
go

-- ***************************************************************
-- ------------------ DB IS READY --------------------------------
-- ***************************************************************

SELECT d.compatibility_level
    FROM sys.databases as d
    WHERE d.name = Db_Name();
go

-- compatibility_level
-- 140

-- In case of we need to change LEVEL we do

-- ALTER DATABASE CURRENT
--     SET COMPATIBILITY_LEVEL = 130;
-- Go


ALTER DATABASE CURRENT
    SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON;
GO

sp_helpdb [containers_ppd_v1];
GO
/*
name					db_size		owner		dbid	created		status																																																			compatibility_level
containers_ppd_v1	    16.00 MB	WPPD-01\ppd	17		Jan 26 2021	Status=ONLINE, Updateability=READ_WRITE, UserAccess=MULTI_USER, Recovery=FULL, Version=869, Collation=Latin1_General_CI_AS, SQLSortOrder=0, IsAutoCreateStatistics, IsAutoUpdateStatistics, IsFullTextEnabled	140

name					fileid	filename																						filegroup	size	maxsize			growth		usage
containers_ppd_v1		1		C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\containers_ppd_v1.mdf		PRIMARY		8192 KB	Unlimited		65536 KB	data only
containers_ppd_v1_log	2		C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\containers_ppd_v1_log.ldf	NULL		8192 KB	2147483648 KB	65536 KB	log only

*/
-- THIS ERROR IS TO REMEMBER THAT SYSTEM DATABASES CANNOT BE "ALTERED" USING CURRENT KEYWORD 
--Msg 12104, Level 16, State 1, Line 17
--ALTER DATABASE CURRENT failed because 'master' is a system database. 
-- System databases cannot be altered by using the CURRENT keyword. 
-- Use the database name to alter a system database.


-- Create some memory-optimized tables
-- SCHEMA and DATA --> DURABLE DATABASE 

DROP TABLE IF EXISTS SalesOrder
go
CREATE TABLE SalesOrder
(
    SalesOrderId   integer        not null  IDENTITY
        PRIMARY KEY NONCLUSTERED Hash WITH (bucket_Count = 1000000),
    CustomerId     integer        not null,
    OrderDate      datetime       not null
)
    WITH
        (MEMORY_OPTIMIZED = ON,
        DURABILITY = SCHEMA_AND_DATA);
go

-- SCHEMA only ---> NON DURABLE DATABASE
--Drop table if it already exists.
IF OBJECT_ID('SalesOrder_SO','U') IS NOT NULL
    DROP TABLE SalesOrder_SO
GO

CREATE TABLE SalesOrder_SO
(
	SalesOrderSoId int NOT NULL,
	CustomerId integer NOT NULL,
	Qt decimal(10,2) NOT NULL INDEX index_SalesOrder_SO_Qt NONCLUSTERED (Qt),
   CONSTRAINT PK_SalesOrder_SO PRIMARY KEY NONCLUSTERED (SalesOrderSoId),
   -- See SQL Server Books Online for guidelines on determining appropriate bucket count for the index
   INDEX hash_index_SalesOrder_SO_CustomerId HASH (CustomerId) WITH (BUCKET_COUNT = 131072)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_ONLY )
GO




-- https://docs.microsoft.com/en-us/sql/relational-databases/in-memory-oltp/defining-durability-for-memory-optimized-objects?view=sql-server-2017

--SCHEMA_AND_DATA (default)
-- This option provides durability of both schema and data.
-- The level of data durability depends on whether you commit a transaction as fully durable or with delayed durability. Fully durable transactions provide the same durability guarantee for data and schema, similar to a disk-based table. Delayed durability will improve performance but can potentially result in data loss in case of a server crash or fail over.

--SCHEMA_ONLY
--This option ensures durability of the table schema. When SQL Server is restarted or a reconfiguration occurs in an Azure SQL Database, the table schema persists, but data in the table is lost. (This is unlike a table in tempdb, where both the table and its data are lost upon restart.) A typical scenario for creating a non-durable table is to store transient data, such as a staging table for an ETL process. A SCHEMA_ONLY durability avoids both transaction logging and checkpoint, which can significantly reduce I/O operations.


-- NOW WE INSERT IN BOTH TABLES 

-- DURABLE SalesOrder
SET NOCOUNT ON
GO
DECLARE @counter INT
SET @counter = 1
WHILE @counter <= 100000
 BEGIN
 INSERT INTO SalesOrder
 VALUES ( @counter,GETDATE()),
 ( @counter+1,GETDATE()),
 ( @counter+2,GETDATE())

SET @counter = @counter + 3
 END
GO

/* SOMETIMES WE GOT THIS ERROR */

--The statement has been terminated.
--Msg 701, Level 17, State 103, Line 123
--There is insufficient system memory in resource pool 'default' to run this query.


-- check the content of DURABLE DATABASE
SELECT count(*) as 'Total rows in durable table' FROM SalesOrder
GO
--Total rows in durable table
--156987

-- ANNOTATION: THERE ARE MORE THAN 100000 ROWS 
-- REASON IS THAT THE INCOMPLETE PREVIUOS STATEMENT FILL WITH 56987 ROWS BEFORE IT TERMINATES
SELECT TOP (10) [SalesOrderId] as id
      ,[CustomerId] as cid
      ,[OrderDate] as odate
  FROM [imoltp_ppd].[dbo].[SalesOrder] WITH (SNAPSHOT)

--id	cid		odate
--98856	98856	2021-03-12 23:21:11.633
--98857	98857	2021-03-12 23:21:11.633
--98858	98858	2021-03-12 23:21:11.633
--98859	98859	2021-03-12 23:21:11.633
--98860	98860	2021-03-12 23:21:11.633
--98861	98861	2021-03-12 23:21:11.633
--98862	98862	2021-03-12 23:21:11.633
--98863	98863	2021-03-12 23:21:11.633
--98864	98864	2021-03-12 23:21:11.633
--98865	98865	2021-03-12 23:21:11.633


-- NO DURABLE SalesOrder_SO
SET NOCOUNT ON
GO
DECLARE @counter INT
SET @counter = 1
WHILE @counter <= 100000
 BEGIN
 INSERT INTO dbo.SalesOrder_SO
 VALUES (@counter, @counter,1),
 (@counter+1, @counter+1,1),
 (@counter+2, @counter+2,1.5)

SET @counter = @counter + 3
 END
GO
-- check NON DURABLE
SELECT count(*) as 'Total rows in NON durable table' FROM SalesOrder_SO
GO
--Total rows in NON durable table
--100002


SELECT TOP (10) SalesOrderSoId as id
      ,[CustomerId] as cid
      ,Qt
  FROM dbo.SalesOrder_SO WITH (SNAPSHOT)

--id	cid		Qt
--99551	99551	1.00
--99552	99552	1.50
--99553	99553	1.00
--99554	99554	1.00
--99555	99555	1.50
--99556	99556	1.00
--99557	99557	1.00
--99558	99558	1.50
--99559	99559	1.00
--99560	99560	1.00

-- NOW TIME TO CHECK AFTER A RESTART

USE MASTER
GO
-- TAKE THE DB OFFLINE is like to reatarting the SERVER
ALTER DATABASE [containers_ppd_v1] SET OFFLINE WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE [containers_ppd_v1] SET ONLINE
GO
/*
Nonqualified transactions are being rolled back. Estimated rollback completion: 0%.
Nonqualified transactions are being rolled back. Estimated rollback completion: 100%.
*/

-- *******************************************
------ CHECK NOW DATA ON BOTH TABLES ---------
-- *******************************************
USE [containers_ppd_v1];
GO
-- check the content of DURABLE DATABASE
SELECT count(*) as 'Total rows in durable table after restart' FROM SalesOrder
GO
--Total rows in durable table after restart
--156987
SELECT TOP (5) [SalesOrderId] as id
      ,[CustomerId] as cid
      ,[OrderDate] as odate
  FROM SalesOrder WITH (SNAPSHOT)
--id		cid		odate
--156256	99268	2021-03-13 00:08:58.590
--156257	99269	2021-03-13 00:08:58.590
--156258	99270	2021-03-13 00:08:58.590
--156259	99271	2021-03-13 00:08:58.590
--156260	99272	2021-03-13 00:08:58.590



-- check NON DURABLE
SELECT count(*) as 'Total rows in NON durable table after restart' FROM SalesOrder_SO
GO
--Total rows in NON durable table after restart
--0
-------> the NON DURABLE TABLE IS EMPTY!!
