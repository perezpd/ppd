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
  CREATE TABLE [dbo].#tempBackupsOngoing (
    intID INT IDENTITY (1,1),
    name VARCHAR(200)
  );
  GO
  --// crear la carpeta Backup
  --SET @path = 'C:\Backp'
  -- establish the value of the date form the system
  SET @fileDate = CONVERT(VARCHAR(20),GETDATE(),112)

END -- end of the code inside the procedure
GO
