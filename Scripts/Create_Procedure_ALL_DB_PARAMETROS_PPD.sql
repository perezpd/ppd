USE MASTER;
GO

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
  --SET @path = 'C:\Backp'
  -- establish the value of the date form the system
  SET @fileDate = CONVERT(VARCHAR(20),GETDATE(),112)
  -- if we want to generate filename with the date and the time
  -- SET @fileDate = CONVERT(VARCHAR(20),GETDATE(),112) + '_' + REPLACE(CONVERT(VARCHAR(20),GETDATE(),108),':','')
  -- https://docs.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql?f1url=%3FappId%3DDev14IDEF1%26l%3DEN-US%26k%3Dk(CONVERT_TSQL);k(sql13.swb.tsqlresults.f1);k(sql13.swb.tsqlquery.f1);k(DevLang-TSQL)%26rd%3Dtrue&view=sql-server-ver15

  INSERT INTO [dbo].#tempBackupsOngoing (name)
	SELECT name 
	FROM master.dbo.sysdatabases
	-- case insensitive names for the DB names
	WHERE name IN ('Northwind','Pubs')
	-- WHERE name NOT IN ('master','model','msdb','tempdb') -- we could use the negative to avoid system databases

  SELECT TOP 1 @backupCount = intID 
  FROM [dbo].#tempBackupsOngoing
  ORDER BY intID DESC

  -- check the number of backups to perform
  PRINT @backupCount

  -- condition with @backupCount: we need to check the count of backups number before executing the loop
	IF ((@backupCount IS NOT NULL) AND (@backupCount > 0) )
	BEGIN

	END
END -- end of the code inside the procedure
GO


