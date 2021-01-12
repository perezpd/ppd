USE master
GO
-- activate advanced options in sql server
EXEC SP_CONFIGURE 'show advanced options', 1
GO
-- RESULT
--Configuration option 'show advanced options' changed from 0 to 1. Run the RECONFIGURE statement to install.

-- update the value for the option
-- is the same effect than restart the server instance
RECONFIGURE
GO


-- activate the option
EXEC SP_CONFIGURE 'contained database authentication', 1
GO
-- RESULT
-- Configuration option 'contained database authentication' changed from 0 to 1. Run the RECONFIGURE statement to install.

-- update the value for the option
RECONFIGURE
GO

-- the enviroment is ready to go

DROP DATABASE  IF EXISTS PPD_Contained2;
GO
CREATE DATABASE PPD_Contained2
  CONTAINMENT=PARTIAL;
GO

-- after creation we activate it
USE PPD_Contained2;
GO

DROP USER  IF EXISTS diego;
GO
CREATE USER diego
  WITH PASSWORD='abcd1234.',
  DEFAULT_SCHEMA=[dbo]
GO

ALTER ROLE db_owner
  ADD MEMBER diego


GRANT CONNECT TO diego;
GO