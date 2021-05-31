
-- FUNCIONES: Sistema y Usuario (UDF)

-- FUNCIONES DE USUARIO (UDF)

-- UDF MEANING User-Defined Functions

-- Tipos de funciones definidas por el usuario (UDF)
--	Scalar
--	InLine Table-Valued
--	Multi-Statement Table-Valued

------------
-- Teoria

--In SQL Server you can create/ define 3 types of User-defined functions:

--- Scalar-valued Function => return a value

--- Inline Table-valued Function => no function body; 
-- the table is the result set of a single SELECT statement

--- Multi-statement Table-valued Function => return a table data type


-- CREATE FUNCTION (Transact-SQL)

-- https://docs.microsoft.com/es-es/sql/t-sql/statements/create-function-transact-sql?view=sql-server-ver15

-- https://www.sqlservertutorial.net/sql-server-user-defined-functions/sql-server-table-valued-functions/

-- Ver GUI 
-- Programmability

-- The different types of function :

---  Scalar (1) - Table-valued (set / varios)

-- Scalar Functions (SFs) return a single scalar data value of the type defined in the RETURNS clause.

-- Table-valued functions
-- Multi-statement table-valued functions (TVFs) return a table data type that can read from in the same way as you would use a table:.
-- Inline Table-valued functions (ITVFs) have no function body; the scalar value that is returned is the result of a single statement without a BEGIN..END block.

-- Inline functions do not have associated return variables, they just return a value functions. 
-- Multi-statement functions have a function body that is defined in a BEGIN…END block, consisting of a series of Transact-SQL statements that together do not produce a side effect such as modifying a table.
-- In the case of a multi-statement table-valued function, these T-SQL statements build 
-- and insert rows into the TABLE variable that is then returned. 
-- In inline table-valued functions, the TABLE return value is defined through a single 
-- SELECT statement. This makes it far easier to produce a sensible query plan.


-- FUNCIONES ESCALARES

-- Scalar Function:
-- Scalar functions returns only scalar/single value. Which can be used in Select statement,
-- Where, -- Group By, Having clause. It returns single data value of the type mentioned 
-- in RETURNS clause.

-------------------------------------------------------------
-- NOTA:
-- Scalar UDF Inlining Nueva Caracteristica de SQL SERVER 2019
-- Scalar UDF Inlining in SQL Server 2019
-- https://sqlperformance.com/2019/01/sql-performance/scalar-udf-sql-server-2019

------------------------------------------------------------
--1.  Scalar User-Defined Function

--A Scalar UDF can accept 0 to many input parameter and will return a single value. A Scalar user-defined function returns one of the scalar (int, char, varchar etc) data types. Text, ntext, image and timestamp data types are not supported. These are the type of user-defined functions that most developers are used to in other programming languages.

--Example 1: Here we are creating a Scalar UDF AddTwoNumbers which accepts two input parameters @a and @b and returns output as the sum of the two input parameters.


USE TEMPDB
GO
CREATE OR ALTER FUNCTION AddTwoNumbers
(
@a int,
@b int
)
	RETURNS int
	AS
	BEGIN
	RETURN @a + @b
	END
GO

PRINT dbo.AddTwoNumbers(10,20)
GO 

-- 10
--OR
 
SELECT dbo.AddTwoNumbers(30,20)
GO

--Inline Table-Valued User-Defined Function

--An inline table-valued function returns a variable of data type table whose value is derived from a single SELECT statement. Since the return value is derived from the SELECT statement, there is no BEGIN/END block needed in the CREATE FUNCTION statement. There is also no need to specify the table variable name (or column definitions for the table variable) because the structure of the returned value is generated from the columns that compose the SELECT statement. Because the results are a function of the columns referenced in the SELECT, no duplicate column names are allowed and all derived columns must have an associated alias.

--Example: In this example we are creating a Inline table-valued function GetAuthorsByState which accepts state as the input parameter and returns firstname and lastname  of all the authors belonging to the input state.

USE PUBS
GO
 
CREATE or ALTER FUNCTION GetAuthorsByState
( @state char(2) )
RETURNS table
AS
RETURN (
	SELECT au_fname, au_lname
	FROM Authors
	WHERE state=@state
)
GO

SELECT * FROM GetAuthorsByState('CA')
GO

-- (15 rows affected)


--3. Multi-statement Table-Valued User-Defined Function

--A Multi-Statement Table-Valued user-defined function returns a table. It can have one or more than one T-Sql statement. Within the create function command you must define the table structure that is being returned. After creating this type of user-defined function, we can use it in the FROM clause of a T-SQL command unlike the behavior found when using a stored procedure which can also return record sets.

--Example: In this example we are creating a Multi-Statement Table-Valued function GetAuthorsByState which accepts state as the input parameter and returns author id and firstname of all the authors belonging to the input state. If for the input state there are no authors then this UDF will return a record with no au_id column value and firstname as ‘No Authors Found’.

USE PUBS
GO
IF  EXISTS (SELECT [name] FROM sys.objects 
            WHERE object_id = OBJECT_ID('GetAuthorsByState'))
BEGIN
   DROP FUNCTION GetAuthorsByState;
END
GO
CREATE or alter FUNCTION GetAuthorsByState
(@state char(2) )
RETURNS
@AuthorsByState table (
au_id Varchar(11),
au_fname Varchar(20)
)
AS
BEGIN
 
INSERT INTO @AuthorsByState
SELECT  au_id,
au_fname
FROM Authors
WHERE state = @state
 
IF @@ROWCOUNT = 0
BEGIN
INSERT INTO @AuthorsByState
VALUES ('','No Authors Found')
END
 
RETURN
END
GO

SELECT * FROM GetAuthorsByState('CA')
go

-- (15 rows affected)

SELECT * FROM GetAuthorsByState('XY')
GO

--au_id	au_fname
--	No Authors Found





