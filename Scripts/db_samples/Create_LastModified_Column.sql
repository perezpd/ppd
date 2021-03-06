
-- Create a �Last Modified� Column in SQL Server
/*
DML trigger statements use two special tables: the deleted table and the inserted tables. 

SQL Server automatically creates and manages these tables. You can use these temporary, 
memory-resident tables to test the effects of certain data modifications and 
to set conditions for DML trigger actions. You cannot directly modify the data in the tables or 
perform data definition language (DDL) operations on the tables, such as CREATE INDEX.

In DML triggers, the inserted and deleted tables are primarily used to perform the following:

Extend referential integrity between tables.

Insert or update data in base tables underlying a view.

Test for errors and take action based on the error.

Find the difference between the state of a table before and after a data modification and 
take actions based on that difference.
*/

USE tempdb
GO
DROP TABLE IF EXISTS dbo.Books
GO
CREATE TABLE dbo.Books (
	BookId int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	BookName nvarchar(1000) NOT NULL,
	CreateDate datetime DEFAULT CURRENT_TIMESTAMP,
	ModifiedDate datetime DEFAULT CURRENT_TIMESTAMP
);
GO

CREATE OR ALTER TRIGGER trg_Books_UpdateModifiedDate
ON dbo.Books
AFTER UPDATE
AS
	UPDATE dbo.Books
	SET ModifiedDate = CURRENT_TIMESTAMP
	WHERE BookId IN (SELECT DISTINCT BookId FROM inserted);
GO

INSERT INTO Books (BookName) 
VALUES ('Trigger Happy');
GO

SELECT * FROM Books;
GO

--BookId	BookName		CreateDate					ModifiedDate
--1			Trigger Happy	2021-02-23 21:11:08.693		2021-02-23 21:11:08.693

UPDATE Books 
SET BookName = 'Trigger Hoppy'
WHERE BookId = 1;
GO

SELECT * FROM Books;
GO

--BookId	BookName			CreateDate						ModifiedDate
--1			Trigger Hippy	2021-02-18 22:15:18.120	    2021-02-23 21:11:26.410


--Second book
INSERT INTO Books (BookName) 
VALUES ('Trigger Repeated');
GO

SELECT * FROM Books;
GO

--BookId	BookName			CreateDate				ModifiedDate
--1		Trigger Hoppy		2021-02-23 21:11:08.693		2021-02-23 21:11:26.410
--2		Trigger Repeated	2021-02-23 21:11:47.980		2021-02-23 21:11:47.980


UPDATE Books 
SET BookName = 'Trigger Repeated Again'
WHERE BookId = 2;
GO

SELECT * FROM Books;
GO
--1		Trigger Hoppy			2021-02-23 21:11:08.693	2021-02-23 21:11:26.410
-- 2	Trigger Repeated Again	2021-02-18 22:16:09.203	2021-02-23 21:12:26.100