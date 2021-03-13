/* OWNER PEREZ PONTE DIEGO*/

/*********************************************************************************************/
/********************************     PROCEDURES       ***************************************/
/********************************  BACKUP_DB_GIVEN   *****************************************/
/********************************  BACKUP_DB_CUSTOM  *****************************************/
/*********************************************************************************************/


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


EXECUTE BACKUP_DB_GIVEN 'C:\Backups\', 'containers_1'
GO

-- RESULT OK
--(1 row affected)
--1
--C:\Backups\containers_1_20210313.BAK
--Processed 472 pages for database 'containers_1', file 'containers_1' on file 1.
--Processed 2 pages for database 'containers_1', file 'containers_1_log' on file 1.
--BACKUP DATABASE successfully processed 474 pages in 0.108 seconds (34.229 MB/sec).

-- RESULT ERROR when the folder does not exist or its wrong spelling
EXECUTE BACKUP_DB_GIVEN 'C:\BackupsWrong\', 'containers_ppd_test'
GO

--(1 row affected)
--1
--C:\BackupsWrong\containers_ppd_test_20210313.BAK
--Msg 3201, Level 16, State 1, Procedure BACKUP_DB_GIVEN, Line 66 [Batch Start Line 92]
--Cannot open backup device 'C:\BackupsWrong\containers_ppd_test_20210313.BAK'. Operating system error 3(The system cannot find the path specified.).
--Msg 3013, Level 16, State 1, Procedure BACKUP_DB_GIVEN, Line 66 [Batch Start Line 92]
--BACKUP DATABASE is terminating abnormally.


USE MASTER;
GO
/* WE PASS THE FOLDER and the PPROCEDURE MAKE THE BACKUP OF THE DATABASES DEFINED INTERNALLY*/
/* --- My DATABASES
'containers_ppd_test',
'containers_ppd_test_TR',
'PruebaFilestream',
'caledario_eventos_ppd',
'PruebaFilestream',
'PPD_Contained'  
---- */
CREATE OR ALTER PROC BACKUP_DB_CUSTOM
-- INPUT PARAMETERS
  @path VARCHAR(256)
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
	WHERE name IN ('containers_ppd_test','containers_ppd_test_TR','PruebaFilestream','caledario_eventos_ppd','PruebaFilestream','PPD_Contained')

-- I select the bds used in my project and take the last identifier that would be the highest starting with 1
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


EXECUTE BACKUP_DB_CUSTOM 'C:\BackupsPPD\';
GO

--(5 rows affected)
--5
--C:\BackupsPPD\caledario_eventos_ppd_20210313.BAK
--Processed 416 pages for database 'caledario_eventos_ppd', file 'caledario_eventos_ppd' on file 1.
--Processed 24 pages for database 'caledario_eventos_ppd', file 'Eventos_Archivo' on file 1.
--Processed 24 pages for database 'caledario_eventos_ppd', file 'eventos_2019' on file 1.
--Processed 8 pages for database 'caledario_eventos_ppd', file 'eventos_2020' on file 1.
--Processed 8 pages for database 'caledario_eventos_ppd', file 'eventos_2021' on file 1.
--Processed 2 pages for database 'caledario_eventos_ppd', file 'caledario_eventos_ppd_log' on file 1.
--BACKUP DATABASE successfully processed 482 pages in 0.064 seconds (58.815 MB/sec).
--C:\BackupsPPD\containers_ppd_test_20210313.BAK
--Processed 520 pages for database 'containers_ppd_test', file 'containers_ppd_test' on file 1.
--Processed 3 pages for database 'containers_ppd_test', file 'containers_ppd_test_log' on file 1.
--BACKUP DATABASE successfully processed 523 pages in 0.125 seconds (32.683 MB/sec).
--C:\BackupsPPD\containers_ppd_test_TR_20210313.BAK
--Processed 592 pages for database 'containers_ppd_test_TR', file 'containers_ppd_test_TR_dat' on file 1.
--Processed 8 pages for database 'containers_ppd_test_TR', file 'containers_ppd_test_TR_log' on file 1.
--BACKUP DATABASE successfully processed 600 pages in 0.119 seconds (39.353 MB/sec).
--C:\BackupsPPD\PPD_Contained_20210313.BAK
--Processed 416 pages for database 'PPD_Contained', file 'PPD_Contained' on file 1.
--Processed 2 pages for database 'PPD_Contained', file 'PPD_Contained_log' on file 1.
--BACKUP DATABASE successfully processed 418 pages in 0.089 seconds (36.621 MB/sec).
--C:\BackupsPPD\PruebaFilestream_20210313.BAK
--Processed 408 pages for database 'PruebaFilestream', file 'PruebaFilestream' on file 1.
--Processed 3 pages for database 'PruebaFilestream', file 'MyDB_filestream' on file 1.
--Processed 2 pages for database 'PruebaFilestream', file 'PruebaFilestream_log' on file 1.
--BACKUP DATABASE successfully processed 412 pages in 0.099 seconds (32.497 MB/sec).

