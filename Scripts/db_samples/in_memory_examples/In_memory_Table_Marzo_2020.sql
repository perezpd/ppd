-- 2021/03/09
-- transact operations in RAM memory
-- IN MEMORY TABLE EXAMPLE

use master
GO


SELECT d.compatibility_level
    FROM sys.databases as d
    WHERE d.name = Db_Name();
GO


-- GUI Properties DB
--compatibility_level
--140

ALTER DATABASE AdventureWorks2017
SET COMPATIBILITY_LEVEL = 140;
GO

ALTER DATABASE AdventureWorks2017
SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON;
GO

ALTER DATABASE AdventureWorks2017
ADD FILEGROUP AdventureWorks2017_mod CONTAINS MEMORY_OPTIMIZED_DATA;
go
-- folder must exists
ALTER DATABASE AdventureWorks2017
ADD FILE
	(name='AdventureWorks2017_mod1',
	filename='c:\data\AdventureWorks2017test')
	TO FILEGROUP AdventureWorks2017_mod
go

USE AdventureWorks2017
go

/****** Object:  Table [dbo].[InMemoryExample]    Script Date: 09/03/2021 21:36:49 ******/
DROP TABLE [dbo].[InMemoryExample]
GO

CREATE TABLE dbo.InMemoryExample
    (
        OrderID   INTEGER   NOT NULL   IDENTITY
            PRIMARY KEY NONCLUSTERED,
        ItemNumber   INTEGER    NOT NULL,
        OrderDate    DATETIME   NOT NULL
    )
        WITH
            (MEMORY_OPTIMIZED = ON,
            DURABILITY = SCHEMA_AND_DATA);
GO

INSERT INTO dbo.InMemoryExample 
     VALUES
           (2, GETDATE()),
           (3, GETDATE()),
           (4, GETDATE()),
           (5, GETDATE()),
           (6, GETDATE())
GO

SELECT * FROM dbo.InMemoryExample;
GO

--OrderID	ItemNumber	OrderDate
--1			1			2021-03-09 21:25:05.770
--2			2			2021-03-09 21:25:36.430
--3			3			2021-03-09 21:25:36.430
--4			4			2021-03-09 21:25:36.430
--5			5			2021-03-09 21:25:36.430
--6			6			2021-03-09 21:25:36.430


/* Table properties show Memory Optimized = TRUE and Durability = SchemaAndData once the table is created
 -- which makes it very simple to verify what the table is doing.


 --    Inserting and selecting against the table is syntactically the same as any other regular table, however, internally it is far different.
 -- Above and beyond the table creation, its structured behavior is basically the same in these actions including adding or removing a column.
 -- Now one caveat to these tables is that you cannot CREATE or DROP an Index the same way. You must use ADD/DROP Index to accomplish this,
 -- and, believe me, I tried. Indexing these tables is covered later in the article.


 --    Remember the DURABILITY option I briefly mentioned before? This is important.
 -- The example above has it set to SCHEMA_AND_DATA which means, upon database going offline,
 -- both the schema and data are preserved on disk. If you choose SCHEMA_ONLY,
 -- this means that only the structure will be preserved,
 -- and data will be deleted. This is very important to note as it can introduce data loss when used incorrectly.


--   As you can see, In-Memory tables are not as complicated as my brain wanted to make them.
-- It is a relatively simple concept that just incorporates row versioning and two copies of the table.
   Once you pull the concept apart into its parts, it really makes it easier to understand.

--Which Tables Do I Put In-Memory?
--  Determining which tables could benefit from being In-Memory is made easy by using a tool
-- called Memory Optimization Advisor (MOA). This a is a tool built into SQL Server Management Studio (SSMS)
-- that will inform you of which tables could benefit using In-Memory OLTP capabilities,
-- and which may have non supported features. Once identified, MOA will help you
-- to migrate that table and data to be optimized.

--To see how it works, I will walk you through using it on a table I use for demonstrations in AdventureWorks2016CTP3.
  Since this is a smaller table and does not incur a ton writes it is not a good use case, however, for simplicity I am using it for this demo.

--To get started, right-click on the Sales.OrderTracking table and select Memory Optimization Advisor.
*/

-- Using Memory Optimization Advisor

-- Memory-Optimized TempDB Metadata in SQL Server 2019
-- https://www.mssqltips.com/sqlservertip/6230/memoryoptimized-tempdb-metadata-in-sql-server-2019/

-- https://www.mssqltips.com/sqlservertip/4268/sql-server-memory-optimization-advisor-to-migrate-to-inmemory-oltp/

CREATE TABLE [dbo].[MemoryOptimizationAdvisor](
[Id] [int] NOT NULL,
CONSTRAINT [PK_Example] PRIMARY KEY CLUSTERED
(
[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
