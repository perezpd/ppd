USE MASTER;
GO

CREATE OR ALTER PROC BACKUP_DB_WITH_CURSOR
-- NO INPUT PARAMETERS
AS
DECLARE
  @name VARCHAR(50), --database name
  @path VARCHAR(256),  --path destination for the resulting backup
  @fileName VARCHAR(256),-- filename for the backup file
  @fileDate VARCHAR(20), -- used to contruct file name with date
  @backupCount INT
BEGIN -- start of the code inside the procedure
-- temp backup dies with the user sesion
-- with double # --> all user sessions could see the temporal table
  -- CREATE TABLE [dbo].#tempBackupsOngoing (
  --   intID INT IDENTITY (1,1),
  --   name VARCHAR(200)
  -- );
  SET @backupCount = 0;
  --// create Backup folder first
  SET @path = 'C:\Backups\'
  -- establish the value of the date form the system
  -- SET @fileDate = CONVERT(VARCHAR(20),GETDATE(),112)
  -- if we want to generate filename with the date and the time
  SET @fileDate = CONVERT(VARCHAR(20),GETDATE(),112) + '_' + REPLACE(CONVERT(VARCHAR(20),GETDATE(),108),':','')
  -- https://docs.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql?f1url=%3FappId%3DDev14IDEF1%26l%3DEN-US%26k%3Dk(CONVERT_TSQL);k(sql13.swb.tsqlresults.f1);k(sql13.swb.tsqlquery.f1);k(DevLang-TSQL)%26rd%3Dtrue&view=sql-server-ver15

  -- a cursor let us make a loop into data result of a select
  DECLARE db_cursor CURSOR READ_ONLY FOR
    SELECT name
    FROM master.dbo.sysdatabases
    WHERE name IN ('Northwind','AdventureWorks2017')

  OPEN db_cursor -- like an index but in memory

  FETCH NEXT FROM db_cursor INTO @name

  WHILE @@FETCH_STATUS = 0
  	BEGIN
      SET @fileName = @path + @name + '_' + @fileDate + '.BAK' --unique file name,

      BACKUP DATABASE @name TO DISK = @fileName WITH INIT
      SET @backupCount = @backupCount + 1
	  PRINT 'Done backup ' + CONVERT(VARCHAR(20),@backupCount) + ' of => ' + @fileName
  	  FETCH NEXT FROM db_cursor INTO @name
  	END
  CLOSE db_cursor;
  DEALLOCATE db_cursor;

END -- end of the code inside the procedure
GO


EXECUTE BACKUP_DB_WITH_CURSOR;
GO

--RESULT
--Processed 26304 pages for database 'AdventureWorks2017', file 'AdventureWorks2017' on file 1.
--Processed 2 pages for database 'AdventureWorks2017', file 'AdventureWorks2017_log' on file 1.
--BACKUP DATABASE successfully processed 26306 pages in 1.380 seconds (148.919 MB/sec).
--Done backup 1 of => C:\Backups\AdventureWorks2017_20210112_214857.BAK
--Processed 824 pages for database 'Northwind', file 'Northwind' on file 1.
--Processed 2 pages for database 'Northwind', file 'Northwind_log' on file 1.
--BACKUP DATABASE successfully processed 826 pages in 0.147 seconds (43.848 MB/sec).
--Done backup 2 of => C:\Backups\Northwind_20210112_214857.BAK
