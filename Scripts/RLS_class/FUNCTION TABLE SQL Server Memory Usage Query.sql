
-- SQL Server Memory Usage Query
-- https://www.mssqltips.com/sqlservertip/6833/sql-server-memory-usage-query/


-- All this information is gathered from two memory related 
-- DMVs (dynamic management views): sys.dm_os_sys_info and sys.dm_os_sys_memory.

-- sys.dm_os_sys_info returns a miscellaneous set of useful information about the computer
-- and about the resources available and consumed by SQL Server 

-- sys.dm_os_sys_memory returns memory information from the operating system.

-- =============================================
-- Author:      manuel. Create date: 01-04-2021
-- Description: Check current SQL memory status compared to the OS status
-- =============================================
USE master
GO
-- Multi statement table function 

CREATE OR ALTER FUNCTION dbo.fn_CheckSQLMemory()
RETURNS @Sql_MemStatus TABLE 
 (
   SQLServer_Start_DateTime datetime, 
   SQL_current_Memory_usage_mb int,
   SQL_Max_Memory_target_mb int,
   OS_Total_Memory_mb int,
   OS_Available_Memory_mb int)
AS
BEGIN
   declare @strtSQL datetime
   declare @currmem int
   declare @smaxmem int
   declare @osmaxmm int
   declare @osavlmm int 
 
   -- SQL memory
   SELECT 
      @strtSQL = sqlserver_start_time,
      @currmem = (committed_kb/1024),
      @smaxmem = (committed_target_kb/1024)           
   FROM sys.dm_os_sys_info;
   
   --OS memory
   SELECT 
      @osmaxmm = (total_physical_memory_kb/1024),
      @osavlmm = (available_physical_memory_kb/1024) 
   FROM sys.dm_os_sys_memory;
   
   INSERT INTO @Sql_MemStatus 
	values (@strtSQL, @currmem, @smaxmem, @osmaxmm, @osavlmm)
 
   RETURN 
END
GO 

-- Here is how to use the function:

USE master 
GO 
select * from dbo.fn_CheckSQLMemory()
GO

--SQLServer_Start_DateTime	SQL_current_Memory_usage_mb	SQL_Max_Memory_target_mb	OS_Total_Memory_mb	OS_Available_Memory_mb
--2021-04-29 16:43:48.550				359						361							4094				1882