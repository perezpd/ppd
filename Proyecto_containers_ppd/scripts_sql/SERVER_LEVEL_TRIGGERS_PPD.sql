/* CREATE SOME TRIGGERS IN SERVER LEVEL */

-- Objectives:
--  Avoid login creation after all server setup is ready

 USE master;
 GO

 /* We will avoid login creation on our server after all configuration is set*/
 DROP TRIGGER IF EXISTS trg_avoid_create_logins;
 GO
 CREATE OR ALTER TRIGGER trg_avoid_create_logins
 ON ALL SERVER --SERVER LEVEL
 FOR CREATE_LOGIN -- sentence to control CREATE_LOGIN
 AS --> TRIGGER BODY
	PRINT 'The new login creations are forbidden, you need DBS involvement'
	ROLLBACK TRAN
GO

-- try to create new login to new employees team
CREATE LOGIN SalesForce WITH PASSWORD ='33##22$$11&&..'
GO


-- Now WE are not able to creat new LOGINS in any case
--The new login creations are forbidden, you need DBS involvement
--Msg 3609, Level 16, State 2, Line 44
--The transaction ended in the trigger. The batch has been aborted.


-- WHEN NEW LOGIN NEED TO BE CREATE WE WILL DISABLE THE TRIGGER THIS WAY
DISABLE TRIGGER trg_avoid_create_logins ON ALL SERVER;
GO
