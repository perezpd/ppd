-- 2021/03/09
--GETDATE() and GETUTCDATE()

--The difference between GETDATE() and GETUTCDATE() is in timezone, the GETDATE() function return current date and time in the local timezone,

--the timezone where your database server is running, but GETUTCDATE() return current time and date in UTC (Universal Time Coordinate) or GMT timezone.
use master
GO

print GETDATE()
go

-- Mar  9 2021  9:25PM

print GETUTCDATE()
go

-- Mar  9 2021  8:25PM

print SYSUTCDATETIME()
go

-- 2021-03-09 20:26:54.0182276

--------------
--SYSUTCDATETIME

--Devuelve un valor datetime2 que contiene la fecha y hora del equipo en el que
--  la instancia de SQL Server se está ejecutando. La fecha y hora se devuelven como una hora universal coordinada (UTC). La especificación de precisión de fracción de segundo tiene un intervalo de 1 a 7 dígitos. La precisión predeterminada es 7 dígitos.


----------------------------------

DROP DATABASE IF EXISTS TemporalTable_Trigger
GO
CREATE DATABASE TemporalTable_Trigger
GO
USE TemporalTable_Trigger
GO

DROP TABLE IF EXISTS Birds
GO
CREATE TABLE dbo.Birds
(
 Id INT IDENTITY PRIMARY KEY,
 BirdName varchar(50),
 SightingCount int,
 SysStartTime datetime2 DEFAULT SYSUTCDATETIME(),
 SysEndTime datetime2 DEFAULT '9999-12-31 23:59:59.9999999'
);
GO

DROP TABLE IF EXISTS BirdsHistory
GO
CREATE TABLE dbo.BirdsHistory
(
 Id int,
 BirdName varchar(50),
 SightingCount int,
 SysStartTime datetime2,
 SysEndTime datetime2
) WITH (DATA_COMPRESSION = PAGE);
GO


CREATE CLUSTERED INDEX CL_Id ON dbo.BirdsHistory (Id);
GO

-- Trigger

CREATE OR ALTER TRIGGER TemporalFaking
	ON dbo.Birds
			AFTER UPDATE, DELETE
AS
BEGIN
SET NOCOUNT ON;

DECLARE @CurrentDateTime datetime2 = SYSUTCDATETIME();
PRINT SYSUTCDATETIME()
/* Update start times for newly updated data */
UPDATE b
SET
       SysStartTime = @CurrentDateTime
FROM
    dbo.Birds b
    INNER JOIN inserted i
        ON b.Id = i.Id

/* Grab the SysStartTime from dbo.Birds
   Insert into dbo.BirdsHistory */
INSERT INTO dbo.BirdsHistory
SELECT d.Id, d.BirdName, d.SightingCount,d.SysStartTime,ISNULL(b.SysStartTime,@CurrentDateTime)
FROM
       dbo.Birds b
       RIGHT JOIN deleted d
              ON b.Id = d.Id
END
GO

-----------------------------------------------
SELECT * FROM Birds
GO

SELECT * FROM BirdsHistory
GO
-------------------------------------------------
SELECT * FROM Birds
GO
-- (0 rows affected)

SELECT * FROM BirdsHistory
GO
-- (0 rows affected)


-- TRIGGER    TABLE BIRDS AFTER UPDATE, DELETE

/* inserts */
INSERT INTO dbo.Birds (BirdName, SightingCount) VALUES ('Blue Jay',1);
GO
INSERT INTO dbo.Birds (BirdName, SightingCount) VALUES ('Cardinal',1);
GO
SELECT * FROM Birds
GO
--Id	BirdName	SightingCount	SysStartTime	SysEndTime
--1		Blue Jay	1	2021-03-09 21:06:22.0051607	9999-12-31 23:59:59.9999999
--2		Cardinal	1	2021-03-09 21:06:23.4907587	9999-12-31 23:59:59.9999999
SELECT * FROM BirdsHistory
GO
-- (0 rows affected)

BEGIN TRANSACTION
	INSERT INTO dbo.Birds (BirdName, SightingCount) VALUES ('Canada Goose',1)
	INSERT INTO dbo.Birds (BirdName, SightingCount) VALUES ('Nuthatch',1)
COMMIT
GO
--(1 row affected)
--(1 row affected)
SELECT * FROM Birds
GO
--Id	BirdName		SightingCount	SysStartTime	SysEndTime
--1		Blue Jay		1	2021-03-09 21:06:22.0051607	9999-12-31 23:59:59.9999999
--2		Cardinal		1	2021-03-09 21:06:23.4907587	9999-12-31 23:59:59.9999999
--3		Canada Goose	1	2021-03-09 21:10:26.3390697	9999-12-31 23:59:59.9999999
--4		Nuthatch		1	2021-03-09 21:10:26.3390697	9999-12-31 23:59:59.9999999

SELECT * FROM BirdsHistory
GO
-- (0 rows affected)

-- together transactions -- not executed in both tables because we do rollback
BEGIN TRANSACTION
	INSERT INTO dbo.Birds (BirdName, SightingCount) VALUES ('Dodo',1)
	INSERT INTO dbo.Birds (BirdName, SightingCount) VALUES ('Ivory Billed Woodpecker',1)
ROLLBACK
GO
--(1 row affected)

--(1 row affected)
SELECT * FROM Birds
GO
/*
Id	BirdName	SightingCount	SysStartTime	SysEndTime
1	Blue Jay	1	2021-03-09 21:06:22.0051607	9999-12-31 23:59:59.9999999
2	Cardinal	1	2021-03-09 21:06:23.4907587	9999-12-31 23:59:59.9999999
3	Canada Goose	1	2021-03-09 21:10:26.3390697	9999-12-31 23:59:59.9999999
4	Nuthatch	1	2021-03-09 21:10:26.3390697	9999-12-31 23:59:59.9999999
*/
SELECT * FROM BirdsHistory
GO
-- (0 rows affected)

/* updates */
UPDATE dbo.Birds SET SightingCount = SightingCount+1 WHERE id = 1;
GO
UPDATE dbo.Birds SET SightingCount = SightingCount+1 WHERE id in (2,3);
GO
/*
2021-03-09 21:12:23.1551547
(1 row affected)
2021-03-09 21:12:23.1866735
(2 rows affected)
*/
SELECT * FROM Birds
GO

/*
Id	BirdName	SightingCount	SysStartTime	SysEndTime
1	Blue Jay	2	2021-03-09 21:12:23.1551547	9999-12-31 23:59:59.9999999
2	Cardinal	2	2021-03-09 21:12:23.1866735	9999-12-31 23:59:59.9999999
3	Canada Goose	2	2021-03-09 21:12:23.1866735	9999-12-31 23:59:59.9999999
4	Nuthatch	1	2021-03-09 21:10:26.3390697	9999-12-31 23:59:59.9999999
*/


SELECT * FROM BirdsHistory
GO
/*
Id	BirdName	SightingCount	SysStartTime	SysEndTime
1	Blue Jay	1	2021-03-09 21:06:22.0051607	2021-03-09 21:12:23.1551547
2	Cardinal	1	2021-03-09 21:06:23.4907587	2021-03-09 21:12:23.1866735
3	Canada Goose	1	2021-03-09 21:10:26.3390697	2021-03-09 21:12:23.1866735
*/
BEGIN TRANSACTION
UPDATE dbo.Birds SET SightingCount = SightingCount+1 WHERE id =4;
GO
ROLLBACK
--2021-03-09 21:13:35.0215367

--(1 row affected)
SELECT * FROM Birds
GO
/*
Id	BirdName	SightingCount	SysStartTime	SysEndTime
1	Blue Jay	2	2021-03-09 21:12:23.1551547	9999-12-31 23:59:59.9999999
2	Cardinal	2	2021-03-09 21:12:23.1866735	9999-12-31 23:59:59.9999999
3	Canada Goose	2	2021-03-09 21:12:23.1866735	9999-12-31 23:59:59.9999999
4	Nuthatch	1	2021-03-09 21:10:26.3390697	9999-12-31 23:59:59.9999999
*/
SELECT * FROM BirdsHistory
GO

--Id	BirdName	SightingCount	SysStartTime	SysEndTime
--1	Blue Jay	1	2021-03-09 21:06:22.0051607	2021-03-09 21:12:23.1551547
--2	Cardinal	1	2021-03-09 21:06:23.4907587	2021-03-09 21:12:23.1866735
--3	Canada Goose	1	2021-03-09 21:10:26.3390697	2021-03-09 21:12:23.1866735


/* deletes */

DELETE FROM dbo.Birds WHERE id = 1;
GO
DELETE FROM dbo.Birds WHERE id in (2,3);
GO

SELECT * FROM Birds
GO

--Id	BirdName	SightingCount			SysStartTime						SysEndTime
--4	Nuthatch				1			2021-03-09 21:10:26.3390697		9999-12-31 23:59:59.9999999

SELECT * FROM BirdsHistory
GO
/*
Id	BirdName	SightingCount	SysStartTime	SysEndTime
1	Blue Jay	1	2021-03-09 21:06:22.0051607	2021-03-09 21:12:23.1551547
1	Blue Jay	2	2021-03-09 21:12:23.1551547	2021-03-09 21:14:36.5154222
2	Cardinal	1	2021-03-09 21:06:23.4907587	2021-03-09 21:12:23.1866735
2	Cardinal	2	2021-03-09 21:12:23.1866735	2021-03-09 21:14:39.1306358
3	Canada Goose	1	2021-03-09 21:10:26.3390697	2021-03-09 21:12:23.1866735
3	Canada Goose	2	2021-03-09 21:12:23.1866735	2021-03-09 21:14:39.1306358
*/
BEGIN TRANSACTION
DELETE FROM dbo.Birds WHERE id =4;
GO
ROLLBACK
/*
2021-03-09 21:15:36.5576330

(1 row affected)
*/
SELECT * FROM Birds
GO
--Id	BirdName	SightingCount	SysStartTime							SysEndTime
--4	Nuthatch			1			2021-03-09 21:10:26.3390697		9999-12-31 23:59:59.9999999
SELECT * FROM BirdsHistory
GO
/*
Id	BirdName	SightingCount	SysStartTime	SysEndTime
1	Blue Jay	1	2021-03-09 21:06:22.0051607	2021-03-09 21:12:23.1551547
1	Blue Jay	2	2021-03-09 21:12:23.1551547	2021-03-09 21:14:36.5154222
2	Cardinal	1	2021-03-09 21:06:23.4907587	2021-03-09 21:12:23.1866735
2	Cardinal	2	2021-03-09 21:12:23.1866735	2021-03-09 21:14:39.1306358
3	Canada Goose	1	2021-03-09 21:10:26.3390697	2021-03-09 21:12:23.1866735
3	Canada Goose	2	2021-03-09 21:12:23.1866735	2021-03-09 21:14:39.1306358
*/

-- TODO!!!!!
-- Now seeing what our dbo.Birds data looked like at a certain point-in-time isn’t quite
-- as easy as a system versioned table in SQL Server 2016, but it’s not bad:

DECLARE @SYSTEM_TIME datetime2 = '2021-02-01 19:55:53.128014';
SELECT *
FROM
	(
	SELECT * FROM dbo.Birds
	UNION ALL
	SELECT * FROM dbo.BirdsHistory
	) FakeTemporal
WHERE
	@SYSTEM_TIME >= SysStartTime
	AND @SYSTEM_TIME < SysEndTime;
GO

--Id	BirdName	SightingCount	SysStartTime	SysEndTime
--1	Blue Jay	1	2021-02-01 19:55:53.1280143	2021-02-01 20:01:55.3920048

DECLARE @SYSTEM_TIME datetime2 = '2021-02-01 20:01:55.4756823';
SELECT *
FROM
	(
	SELECT * FROM dbo.Birds
	UNION ALL
	SELECT * FROM dbo.BirdsHistory
	) FakeTemporal
WHERE
	@SYSTEM_TIME >= SysStartTime
	AND @SYSTEM_TIME < SysEndTime;
GO

SELECT * FROM dbo.Birds
	UNION ALL
SELECT * FROM dbo.BirdsHistory
GO
--Id	BirdName		SightingCount		SysStartTime					SysEndTime
--4	Nuthatch				1		2021-02-01 19:57:53.3654352			9999-12-31 23:59:59.9999999
--1	Blue Jay				1		2021-02-01 19:55:53.1280143			2021-02-01 20:01:55.3920048
--1	Blue Jay				2		2021-02-01 20:01:55.3920048			2021-02-01 20:07:17.4070381
--2	Cardinal				1		2021-02-01 19:55:53.1519945			2021-02-01 20:01:55.4756823
--2	Cardinal				2		2021-02-01 20:01:55.4756823			2021-02-01 20:07:17.4179717
--3	Canada Goose			1		2021-02-01 19:57:53.3654352			2021-02-01 20:01:55.4756823
--3	Canada Goose			2		2021-02-01 20:01:55.4756823			2021-02-01 20:07:17.4179717

--WHERE
--	@SYSTEM_TIME >= SysStartTime
--	AND @SYSTEM_TIME < SysEndTime;

-- @SYSTEM_TIME = '2021-02-01 20:01:55.4756823'


--Id	BirdName	SightingCount			SysStartTime				SysEndTime
--4	Nuthatch			1			2021-02-01 19:57:53.3654352		9999-12-31 23:59:59.9999999
--1	Blue Jay			2			2021-02-01 20:01:55.3920048		2021-02-01 20:07:17.4070381
--2	Cardinal			2			2021-02-01 20:01:55.4756823		2021-02-01 20:07:17.4179717
--3	Canada Goose		2			2021-02-01 20:01:55.4756823		2021-02-01 20:07:17.4179717


-- the trigger based version is almost the same as a real system versioned temporal table.


---------------------------------------
-- NOTA : ISNULL

-- Finds the average of the weight of all products.
-- It substitutes the value 50 for all NULL entries in the Weight column of the Product table.


USE AdventureWorks2017;
GO
SELECT AVG(WeighT)
FROM Production.Product;
GO
-- 74.069219
SELECT Weight
FROM Production.Product;
GO
-- (504 rows affected)
SELECT ISNULL(Weight, 50)
FROM Production.Product;
GO
-- (504 rows affected)
SELECT AVG(ISNULL(Weight, 50))
FROM Production.Product;
GO
-- 59.790059
