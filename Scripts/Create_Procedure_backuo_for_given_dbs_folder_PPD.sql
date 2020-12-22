USE MASTER;
GO

CREATE OR ALTER PROC BACKUP_DB_GIVEN
-- INPUT PARAMETERS
  @path VARCHAR(256),
  @database VARCHAR(256)
AS
DECLARE
  @name VARCHAR(50), --database name
    -- @Path VARCHAR(256)  --path destination for the resulting backup
  @fileName VARCHAR(256),-- filename for the backup file
  @fileDate VARCHAR(20), -- used to contruct file name with date
  @backupCount INT
BEGIN -- start of the code inside the procedure
-- temp backup dies with the user sesion
-- with double # --> all user sessions could see the temporal table
  CREATE TABLE [dbo].#tempBackupsOngoing (
    intID INT IDENTITY (1,1),
    name VARCHAR(200)
  );

  --// crear la carpeta Backup
  --SET @path = 'C:\Backup'
  -- establish the value of the date form the system
  SET @fileDate = CONVERT(VARCHAR(20),GETDATE(),112)
  -- if we want to generate filename with the date and the time
  -- SET @fileDate = CONVERT(VARCHAR(20),GETDATE(),112) + '_' + REPLACE(CONVERT(VARCHAR(20),GETDATE(),108),':','')
  -- https://docs.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql?f1url=%3FappId%3DDev14IDEF1%26l%3DEN-US%26k%3Dk(CONVERT_TSQL);k(sql13.swb.tsqlresults.f1);k(sql13.swb.tsqlquery.f1);k(DevLang-TSQL)%26rd%3Dtrue&view=sql-server-ver15

  INSERT INTO [dbo].#tempBackupsOngoing (name)
	SELECT name
	FROM master.dbo.sysdatabases
	-- case insensitive names for the DB names
	WHERE name = @database
	-- WHERE name NOT IN ('master','model','msdb','tempdb') -- we could use the negative to avoid system databases
-- I select the bd and take the last identifier that would be the highest starting with 1
-- and its equal to the count of DATABASES
  SELECT TOP 1 @backupCount = intID
  FROM [dbo].#tempBackupsOngoing
  ORDER BY intID DESC

  -- check the number of backups to perform
  PRINT @backupCount

  -- condition with @backupCount:
  -- we need to check the count of backups number before executing the loop
	IF ((@backupCount IS NOT NULL) AND (@backupCount > 0) )
  	BEGIN
    -- 22/12/2020
      DECLARE @currentBackup INT
      SET @currentBackup = 1
      -- while loop to iterate all databases inside the [dbo].#tempBackupsOngoing
      WHILE (@currentBackup <= @backupCount)
        BEGIN
          SELECT
            @name = name,
            @fileName = @path + name + '_' + @fileDate + '.BAK' --unique file name,
            -- @fileName = @path + @name + '.BAK' -- NOT unique file name,
            FROM [dbo].#tempBackupsOngoing
            WHERE intID = @currentBackup

            PRINT @fileName -- to see the name

			-- this instruction to backup does dirty backups increasing  te size of the file adding data
            --BACKUP DATABASE @name TO DISK = @fileName
            -- the following overrites the existing file (with init overrides the backup)
            BACKUP DATABASE @name TO DISK = @fileName WITH INIT

            -- increment currentBackup index to continue the while loop
            SET @currentBackup = @currentBackup + 1
        END -- while
  	END -- if count > 0
END -- end of the code inside the procedure
GO


EXECUTE BACKUP_DB_CUSTOM 'C:\Backups\'
GO


-- RESULT OK
--(2 rows affected)
--2
--C:\Backups\Northwind_20201222.BAK
--Processed 824 pages for database 'Northwind', file 'Northwind' on file 1.
--Processed 2 pages for database 'Northwind', file 'Northwind_log' on file 1.
--BACKUP DATABASE successfully processed 826 pages in 0.161 seconds (40.042 MB/sec).
--C:\Backups\pubs_20201222.BAK
--Processed 584 pages for database 'pubs', file 'pubs' on file 1.
--Processed 2 pages for database 'pubs', file 'pubs_log' on file 1.
--BACKUP DATABASE successfully processed 586 pages in 0.148 seconds (30.890 MB/sec).


-- RESULT ERROR when the folder does not exist or its wrong spelling
--EXECUTE BACKUP_DB_CUSTOM 'C:\Backpus\'
--GO
-- (3 rows affected)
--3
--C:\Back\AdventureWorks2017_20201222.BAK
--Msg 3201, Level 16, State 1, Procedure BACKUP_DB_CUSTOM, Line 65 [Batch Start Line 75]
--Cannot open backup device 'C:\Back\AdventureWorks2017_20201222.BAK'. Operating system error 3(The system cannot find the path specified.).
--Msg 3013, Level 16, State 1, Procedure BACKUP_DB_CUSTOM, Line 65 [Batch Start Line 75]
--BACKUP DATABASE is terminating abnormally.
--C:\Back\Northwind_20201222.BAK
--Msg 3201, Level 16, State 1, Procedure BACKUP_DB_CUSTOM, Line 65 [Batch Start Line 75]
--Cannot open backup device 'C:\Back\Northwind_20201222.BAK'. Operating system error 3(The system cannot find the path specified.).
--Msg 3013, Level 16, State 1, Procedure BACKUP_DB_CUSTOM, Line 65 [Batch Start Line 75]
--BACKUP DATABASE is terminating abnormally.
--C:\Back\pubs_20201222.BAK
--Msg 3201, Level 16, State 1, Procedure BACKUP_DB_CUSTOM, Line 65 [Batch Start Line 75]
--Cannot open backup device 'C:\Back\pubs_20201222.BAK'. Operating system error 3(The system cannot find the path specified.).
--Msg 3013, Level 16, State 1, Procedure BACKUP_DB_CUSTOM, Line 65 [Batch Start Line 75]
--BACKUP DATABASE is terminating abnormally.
