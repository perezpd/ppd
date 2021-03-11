-- TODOOOOOOOOOO
/*
BEFORE
-- Create Memory Optimized Table Template
Msg 41337, Level 16, State 100, Line 22
Cannot create memory optimized tables. To create memory optimized tables, the database must have a MEMORY_OPTIMIZED_FILEGROUP that is online and has at least one container.
*/
USE containers_ppd_v1
GO

ALTER DATABASE containers_ppd_v1
ADD FILEGROUP containers_ppd_v1_mod CONTAINS MEMORY_OPTIMIZED_DATA;
go

-- folder must exists
ALTER DATABASE containers_ppd_v1
ADD FILE
	(name='containers_ppd_v1_mod1',
	filename='c:\data\containers_ppd_v1')
	TO FILEGROUP containers_ppd_v1_mod
go

--Drop table if it already exists.
IF OBJECT_ID('dbo.sample_memoryoptimizedtable_ppd','U') IS NOT NULL
    DROP TABLE dbo.sample_memoryoptimizedtable_ppd
GO

CREATE TABLE dbo.sample_memoryoptimizedtable_ppd
(
	c1 int NOT NULL,
	c2 float NOT NULL,
	c3 decimal(10,2) NOT NULL INDEX index_sample_memoryoptimizedtable_ppd_c3 NONCLUSTERED (c3),

   CONSTRAINT PK_sample_memoryoptimizedtable_ppd PRIMARY KEY NONCLUSTERED (c1),
   -- See SQL Server Books Online for guidelines on determining appropriate bucket count for the index
   INDEX hash_index_sample_memoryoptimizedtable_ppd_c2 HASH (c2) WITH (BUCKET_COUNT = 131072)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)
GO

/*
Msg 41337, Level 16, State 100, Line 22
Cannot create memory optimized tables. To create memory optimized tables, the database must have a
MEMORY_OPTIMIZED_FILEGROUP that is online and has at least one container.
*/
-- --------------------------------------------------


SELECT d.compatibility_level
    FROM sys.databases as d
    WHERE d.name = Db_Name();
go

-- compatibility_level
-- 140

-- Si hubiera que cambiar

ALTER DATABASE CURRENT
    SET COMPATIBILITY_LEVEL = 130;
Go


ALTER DATABASE CURRENT
    SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON;
GO

--Msg 12104, Level 16, State 1, Line 17
--ALTER DATABASE CURRENT failed because 'master' is a system database. System databases cannot be altered by using the CURRENT keyword. Use the database name to alter a system database.

DROP DATABASE IF EXISTS imoltp
go
CREATE DATABASE imoltp
go

USE imoltp
go
-- Create an optimized FILEGROUP

-- https://docs.microsoft.com/en-us/sql/relational-databases/in-memory-oltp/the-memory-optimized-filegroup?view=sql-server-2017

ALTER DATABASE imoltp
	ADD FILEGROUP imoltp_mod
	CONTAINS MEMORY_OPTIMIZED_DATA
GO

-- You need to add one or more containers to the MEMORY_OPTIMIZED_DATA filegroup

ALTER DATABASE imoltp
	ADD FILE (name='imoltp_mod1',
	filename='c:\data\imoltp_mod1')
	TO FILEGROUP imoltp_mod
go

-- Look up DB Properties FILEGROUS

-- Create a memory-optimized table

DROP TABLE IF EXISTS SalesOrder
go
CREATE TABLE SalesOrder
(
    SalesOrderId   integer        not null  IDENTITY
        PRIMARY KEY NONCLUSTERED,
    CustomerId     integer        not null,
    OrderDate      datetime       not null
)
    WITH
        (MEMORY_OPTIMIZED = ON,
        DURABILITY = SCHEMA_AND_DATA);
go

-- https://docs.microsoft.com/en-us/sql/relational-databases/in-memory-oltp/defining-durability-for-memory-optimized-objects?view=sql-server-2017

--SCHEMA_AND_DATA (default)
-- This option provides durability of both schema and data.
-- The level of data durability depends on whether you commit a transaction as fully durable or with delayed durability. Fully durable transactions provide the same durability guarantee for data and schema, similar to a disk-based table. Delayed durability will improve performance but can potentially result in data loss in case of a server crash or fail over.

--SCHEMA_ONLY
--This option ensures durability of the table schema. When SQL Server is restarted or a reconfiguration occurs in an Azure SQL Database, the table schema persists, but data in the table is lost. (This is unlike a table in tempdb, where both the table and its data are lost upon restart.) A typical scenario for creating a non-durable table is to store transient data, such as a staging table for an ETL process. A SCHEMA_ONLY durability avoids both transaction logging and checkpoint, which can significantly reduce I/O operations.


-- ADVISOR
-- Object Explorer
-- [HumanResources].[Department]
-- Memory Optimization Advisor

USE AdventureWorks2017
GO

SELECT *
INTO [HumanResources].[Departmento]
FROM [HumanResources].[Department]
GO

-- Memory Optimization Advisor

-- https://docs.microsoft.com/en-us/sql/relational-databases/in-memory-oltp/overview-and-usage-scenarios?view=sql-server-2017#sample-script

-- https://docs.microsoft.com/en-us/sql/relational-databases/tables/system-versioned-temporal-tables-with-memory-optimized-tables?view=sql-server-2017
