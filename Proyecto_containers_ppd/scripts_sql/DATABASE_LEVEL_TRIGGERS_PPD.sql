
/* CREATE SOME TRIGGERS IN DATABASE LEVEL */

-- Objectives:
--  Secure all tables and its data on all tables


USE containers_ppd_test
GO

-- this does not work on transact-SQL
-- we must delete it directly and manually on the object explorer
IF (OBJECT_ID('TRG_Avoid_TableDrop_ppd','TR') IS NOT NULL)
	DROP TRIGGER TRG_Avoid_TableDrop_ppd ON DATABASE;
GO

-- disable DROP table on final DATABASE 
CREATE OR ALTER TRIGGER TRG_Avoid_TableDrop_ppd
ON DATABASE -- DATABASE LEVEL
FOR DROP_TABLE, ALTER_TABLE -- sentence to control
AS
	RAISERROR( 'DROP Table FORBIDDEN, please contact the DBA at containers_ppd!',16,8)
	ROLLBACK TRAN;
GO
