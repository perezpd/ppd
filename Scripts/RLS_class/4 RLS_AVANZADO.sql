
--
-- RLS admite dos tipos de predicados de seguridad.
-- FILTER   Controla read (Select Update Delete)
-- BLOCK	Controla Write (Insert Update Delete)



-- Los predicados de filtro filtran en modo silencioso las filas disponibles 
-- para leer operaciones (SELECT, UPDATE y DELETE).

-- Los predicados de bloqueo bloquean explícitamente las operaciones de escritura 
-- (AFTER INSERT, AFTER UPDATE, BEFORE UPDATE, BEFORE DELETE) 
-- que infringen el predicado.

---
--Los predicados de filtro se aplican al leer los datos de la tabla base y afectan a todas las operaciones get: SELECT, DELETE (por ejemplo, el usuario no puede eliminar las filas filtradas) y UPDATE (por ejemplo, el usuario no puede actualizar las filas filtradas, aunque es posible actualizar las filas de modo que se filtren posteriormente). Los predicados de bloqueo afectan a todas las operaciones de escritura.

--Los predicados AFTER INSERT y AFTER UPDATE pueden impedir que los usuarios actualicen las filas con valores que infrinjan el predicado.

--Los predicados BEFORE UPDATE pueden impedir que los usuarios actualicen las filas que actualmente infrinjan el predicado.

--Los predicados BEFORE DELETE pueden bloquear las operaciones de eliminación.

------


select @@version
DROP DATABASE IF Exists RLS
CREATE DATABASE RLS
USE RLS

DROP USER IF EXISTS BigHat; --DROP IF EXISTS works with users as well as objects: 
CREATE USER BigHat WITHOUT LOGIN; 

DROP USER IF EXISTS MedHat --MediumHat, which we want to get all of SmallHat's rights, but not BigHats
CREATE USER MedHat WITHOUT LOGIN;

DROP USER IF EXISTS SmallHat -- gets a minimal amount of security 
CREATE USER SmallHat WITHOUT LOGIN;
GO

CREATE SCHEMA Demo
GO
CREATE TABLE Demo.SaleItem 
( 
    SaleItemId    int CONSTRAINT PKSaleIitem PRIMARY KEY, 
    ManagedByUser sysname 
)
GO

INSERT demo.SaleItem
VALUES (1,'BigHat'),
(2,'BigHat'),
(3,'MedHat'),
(4,'MedHat'),
(5,'SmallHat'),
(6,'SmallHat')
GO

SELECT *
FROM demo.SaleItem
GO

--The predicate for the function needs to determine:

--Bighat user sees all
--SmallHat user sees only rows where ManagedByUser = 'SmallHat' (we wll expand this in later blogs, but we are starting here
--MedHat sees rows where ManagedByUser = 'MedHat' or the username <> 'BigHat', allowing for other low rights user to be createdin the future


--

--CREATE FUNCTION dbo.ManagedByUser$SecurityPredicate (@ManagedByUser AS sysname) 
--    RETURNS TABLE 
--WITH SCHEMABINDING 
--AS 
--    RETURN (SELECT 1 AS ManagedByUser$SecurityPredicate 
--            WHERE @ManagedByUser = USER_NAME() --If the ManagedByUser = the database username 
--               OR (USER_NAME() = 'MedHat' and @ManagedByUser <> 'BigHat') --if the user is MedHat, and the row isn't managed by BigHat 
--               OR (USER_NAME() = 'BigHat')); --Or the user is the BigHat person, they can see everything 
--GO

--
-- Para incluir DBO
DROP SECURITY POLICY IF EXISTS rowLevelSecurity.Demo_SaleItem_SecurityPolicy; --if exists helps when debugging! 
go 
ALTER FUNCTION dbo.ManagedByUser$SecurityPredicate (@ManagedByUser AS sysname) 
    RETURNS TABLE 
WITH SCHEMABINDING 
AS 
    RETURN (SELECT 1 AS ManagedByUser$SecurityPredicate 
            WHERE @ManagedByUser = USER_NAME() 
               OR (USER_NAME() = 'MedHat' and @ManagedByUser <> 'BigHat') 
               OR (USER_NAME() IN ('BigHat','dbo'))); --give 'dbo' full rights 
GO 
CREATE SECURITY POLICY rowLevelSecurity.Demo_SaleItem_SecurityPolicy 
ADD FILTER PREDICATE rowLevelSecurity.ManagedByUser$SecurityPredicate(ManagedByUser) ON Demo.SaleItem 
WITH (STATE = ON); 
----

CREATE FUNCTION dbo.ManagedByUser$SecurityPredicate 
			(@ManagedByUser AS sysname) 
    RETURNS TABLE 
WITH SCHEMABINDING 
AS 
    RETURN (SELECT 1 AS ManagedByUser$SecurityPredicate 
            WHERE @ManagedByUser = USER_NAME() 
               OR (USER_NAME() = 'MedHat' and @ManagedByUser <> 'BigHat') 
               OR (USER_NAME() IN ('BigHat','dbo'))); --give 'dbo' full rights
GO

--GRANT SELECT ON rowLevelSecurity.ManagedByUser$SecurityPredicate TO PUBLIC; --testing only
--GO
GRANT SELECT ON demo.SaleItem TO BigHat,MedHat,SmallHat
GO
-- Pruebo sin RLS
EXECUTE AS USER = 'SmallHat'; 
GO 
SELECT * FROM Demo.SaleItem; 
GO 
REVERT; 
-- Ve 6

EXECUTE AS USER = 'MedHat'; 
GO 
SELECT * FROM Demo.SaleItem; 
GO 
REVERT; 

EXECUTE AS USER = 'BigHat'; 
GO 
SELECT * FROM Demo.SaleItem; 
GO 
REVERT; 
---

-- BLOCK PREDICATE
-- Now the goal is going to be to demonstrate how we can execute INSERTs, UPDATEs, 
-- and DELETEs on the table.

--First, I will grant the user rights to INSERT, UPDATE and DELETE from the table to all of the users we have set up:
GRANT INSERT,UPDATE,DELETE ON Demo.SaleItem TO SmallHat, MedHat,BigHat; 
GO


-- 
CREATE SECURITY POLICY dbo.Demo_SaleItem_SecurityPolicy 
    ADD FILTER PREDICATE dbo.ManagedByUser$SecurityPredicate(ManagedByUser) 
	ON Demo.SaleItem 
    WITH (STATE = ON, SCHEMABINDING = ON);
GO

-- Before we start to look at the BLOCK predicates, let't take a look at what the user can do at this point, starting with an INSERT from the SmallHat user, with a ManagedByUser that we configured back in part 1 that they cannot see:
-- Aplicando Filter

EXECUTE AS USER = 'SmallHat'; 
GO 
SELECT * FROM Demo.SaleItem; 
GO 

--SaleItemId	ManagedByUser
--5	SmallHat
--6	SmallHat
REVERT
-- Pruebo a insertar un registro que no es el "suyo"
EXECUTE AS USER = 'SmallHat'; 
GO 
INSERT INTO Demo.SaleItem (saleItemId, ManagedByUser) 
VALUES (7,'BigHat'); 
GO 

-- (1 row affected)

SELECT * FROM Demo.SaleItem; 
SELECT COUNT(*) FROM Demo.SaleItem WHERE saleItemId = 7 
GO 

-- Es decir, podria insertar y sin embargo no podria select


REVERT

EXECUTE AS USER = 'BigHat'; 
SELECT * 
FROM   Demo.SaleItem 
WHERE  saleItemId = 7;
GO

--SaleItemId	ManagedByUser
--7	BigHat
REVERT

-- Next up, can we UPDATE or DELETE the row as the SmallHat user? 
-- It seems fairly obvious we cannot since we can’t see it in a WHERE clause 
-- of a SELECT, but it never hurts to check: 

EXECUTE AS USER = 'SmallHat'; 
GO 
UPDATE Demo.SaleItem 
SET    ManagedByUser = 'SmallHat' 
WHERE  SaleItemId = 7; --Give it back to me!
GO

-- If you haven't turn the NOCOUNT setting on for your connection, you will see
-- (0 rows affected)
-- Respuesta silenciosa en lugar de error

DELETE Demo.SaleItem 
WHERE  SaleItemId = 7; --or just delete it 
GO 
-- (0 rows affected)
-- -- Respuesta silenciosa en lugar de error

REVERT; 
GO 

SELECT * 
FROM   Demo.SaleItem 
WHERE  SaleItemId = 7;
GO

-- Ni UPDATE Ni DELETE

--SaleItemId	ManagedByUser
--7				BigHat

-- So the FILTER predicate we previously established works on 
-- UPDATES and DELETEs as well.


-- Conclusión:
-- Con FILTER PREDICATE
-- Select	cumpliendo Politica
-- Insert	puede hacerlo incluso sobre valores que no sean los suyos
-- Update - Delete no puede

 -- Sin embargo

EXECUTE AS USER = 'SmallHat'; 
GO 
SELECT * FROM Demo.SaleItem 
GO
--SaleItemId	ManagedByUser
--5	SmallHat
--6	SmallHat

DELETE Demo.SaleItem 
WHERE  SaleItemId = 5; 
GO 

-- (1 row affected)

-- Si lo ve lo puede borrar
SELECT * FROM Demo.SaleItem 
GO

--SaleItemId	ManagedByUser
--6	SmallHat

REVERT; 
GO 
-- Didáctico: Vuelvo a insertar
INSERT demo.SaleItem
VALUES (5,'SmallHat')
GO
SELECT * 
FROM   Demo.SaleItem 
GO

-- Now let's work on making sure that 
-- the user can't do something silly to the data they have in their view 
-- UNLESS it is an acceptable purpose.


-- Drop the existing security policy for the time being to demonstrate 
-- how the block predicate works.
-- We will put back the filter in the very last part of the blog to meet the requirement of letting the user modify data to a state they can’t see:

-- GUI Security Policies
DROP SECURITY POLICY IF EXISTS dbo.Demo_SaleItem_SecurityPolicy;
GO
-- Posible error SSMS Refresh pero sigue la Politica
-- Nota: Comprobar si escribi bien el nombre de la Politica
-- Lo hago desde GUI y la borra
-------
--Next we are going BLOCK predicate, that will block users from doing certain options. There are two block types: AFTER and BEFORE.

-- AFTER - If the row would not match your ability to see the data after 
-- the operation, it will fail. Have INSERT and UPDATE. 
-- So in example scenario, for INSERT SmallHat would not be able to insert a row 
-- that didn't have 'SmallHat' for the ManagedByUser. 
-- For UPDATE (with no before setting), SmallHat could update any row they can see 
-- to 'SmallHat', but not something else.


-- BEFORE - This seem like it is the same thing as the filter predicate, 
-- saying that if you can't see the row, you can't UPDATE or DELETE it, 
-- but there is a subtle difference. 
-- This says, no matter if you can see the row, before you can modify the row, 
-- it must match the predicate. So in our case, if we added BEFORE update, 
-- and dropped the FILTER predicate, the SmallHat could see all rows, 
-- but only change the rows they manage.

-- I am going to set one of the obvious (to me) set of row level security predicates 
-- that one might set in a realistic scenario for a managed by user type column.

-- BLOCK AFTER INSERT, to say that if you can't see the row, 
	-- that you can't create a new row.
-- BLOCK UPDATE and DELETE you don't own.
-- Allow you to update a row to a manager that you cannot see, 
-- to enable you to pass the row to a peer. 
-- Naturally some level of "are you sure" protection needs to be placed on the row, 
-- because once you update it, it will be gone from your view
--

-- So, using the security predicate function we already created, 
-- we apply the following:

--CREATE SECURITY POLICY dbo.Demo_SaleItem_SecurityPolicy 
--    ADD BLOCK PREDICATE dbo.ManagedByUser$SecurityPredicate(ManagedByUser) ON Demo.saleItem AFTER INSERT, 
--    ADD BLOCK PREDICATE dbo.ManagedByUser$SecurityPredicate(ManagedByUser) ON Demo.saleItem BEFORE UPDATE, 
--    ADD BLOCK PREDICATE dbo.ManagedByUser$SecurityPredicate(ManagedByUser) ON Demo.saleItem BEFORE DELETE 
--    WITH (STATE = ON, SCHEMABINDING = ON); 
--GO
REVERT
-- A veces CREATE SECURITY POLICY aqui da error ejecuta un par de veces
CREATE SECURITY POLICY dbo.Demo_SaleItem_SecurityPolicy 
    ADD BLOCK PREDICATE dbo.ManagedByUser$SecurityPredicate(ManagedByUser) 
	ON Demo.saleItem AFTER INSERT
GO
-- Ver GUI
-- let's try again add a row that SmallHat couldn't see: 
-- Intento lo que antes podia funcionar
EXECUTE AS USER = 'SmallHat'; 
GO 
INSERT INTO Demo.SaleItem (SaleItemId, ManagedByUser) 
VALUES (8,'BigHat');
GO

--Msg 33504, Level 16, State 1, Line 258
--The attempted operation failed because the target object 'RLS.Demo.SaleItem' has a block predicate that conflicts with this operation. If the operation is performed on a view, the block predicate might be enforced on the underlying table. Modify the operation to target only the rows that are allowed by the block predicate.
--The statement has been terminated.

-- Now try again, with SmallHat as the ManagedByUser column value:

INSERT INTO Demo.SaleItem (SaleItemId, ManagedByUser) 
VALUES (8,'SmallHat');
GO
-- (1 row affected)
-- Funciona 
-- Conclusión:
-- INSERT funciona con valores permitidos, en este caso, SmallHat

-- Vemos todo porque quite Filter Predicate
SELECT * FROM Demo.SaleItem -- WHERE SaleItemId=1
GO
REVERT
SELECT * FROM Demo.SaleItem
GO


-- Next, continuing in the security context of the SmallHat user, 
-- let's try the UPDATE and DELETE we tried earlier to SaleItemId 7:
REVERT
GO

-- BEFORE UPDATE


ALTER SECURITY POLICY dbo.Demo_SaleItem_SecurityPolicy  
ADD BLOCK PREDICATE dbo.ManagedByUser$SecurityPredicate(ManagedByUser) 
ON Demo.saleItem BEFORE UPDATE
GO 

EXECUTE AS USER = 'SmallHat'; 
GO 
SELECT * FROM Demo.SaleItem
WHERE  SaleItemId = 7
GO

--SaleItemId	ManagedByUser
--7					BigHat

-- Si intento Actualizar un registro que no sea "suyo", en este caso deSmallHat
-- Intenta actualizar un registro de BigHat

UPDATE Demo.SaleItem 
SET    ManagedByUser = 'SmallHat' 
WHERE  SaleItemId = 7; 
GO 

--Msg 33504, Level 16, State 1, Line 298
--The attempted operation failed because the target object 'RLS.Demo.SaleItem' has a block predicate that conflicts with this operation. If the operation is performed on a view, the block predicate might be enforced on the underlying table. Modify the operation to target only the rows that are allowed by the block predicate.
--The statement has been terminated

-- Showing we have stopped the user from modifying the rows, even though they can see them.

-- Sin embargo

-- Now, lets use the security hole we left. 
-- That of letting the user update the row by not checking that the value matched 
-- AFTER the UPDATE operation , 
-- in the following case changing the ManagedByUser column to another user.
REVERT
EXECUTE AS USER = 'SmallHat'; 
GO
-- Recuerda este no funcionaba
UPDATE Demo.SaleItem 
SET    ManagedByUser = 'SmallHat' 
WHERE  SaleItemId = 7; 
GO 
-----
SELECT * FROM Demo.SaleItem WHERE SaleItemId = 8;
GO

--SaleItemId	ManagedByUser
--8					SmallHat


UPDATE Demo.SaleItem 
SET    ManagedByUser = 'BigHat' 
WHERE  SaleItemId = 8;
GO
-- (1 row affected)

SELECT * FROM Demo.SaleItem 
WHERE SaleItemId = 8;
GO

--SaleItemId	ManagedByUser
--8	BigHat

-- Conclusión:
-- BEFORE UPDATE deja Update si cumple predicado

-- Por DELETE		
-- BEFORE DELETE
REVERT
GO

-- Nota:
-- Si ejecutas ALTER SECURITY POLICY sin REVERT no tenes permisos 
-- y da error

ALTER SECURITY POLICY dbo.Demo_SaleItem_SecurityPolicy  
ADD BLOCK PREDICATE dbo.ManagedByUser$SecurityPredicate(ManagedByUser) 
ON Demo.saleItem BEFORE DELETE
GO 


--Msg 229, Level 14, State 5, Line 349
--The REFERENCES permission was denied on the object 'SaleItem', database 'RLS', schema 'Demo'.
--Msg 1088, Level 16, State 18, Line 349
--Cannot find the object "SaleItem" because it does not exist or you do not have permissions.

-- Esto no es necesario funciona el ALTER SECURITY POLICY dbo.Demo_SaleItem_SecurityPolicy
-- pero queria controlar funcionamiento con todas las Politicas BLOCK PREDICATE 
DROP SECURITY POLICY IF EXISTS dbo.Demo_SaleItem_SecurityPolicy;
GO

CREATE SECURITY POLICY dbo.Demo_SaleItem_SecurityPolicy 
    ADD BLOCK PREDICATE dbo.ManagedByUser$SecurityPredicate(ManagedByUser) ON Demo.saleItem AFTER INSERT, 
    ADD BLOCK PREDICATE dbo.ManagedByUser$SecurityPredicate(ManagedByUser) ON Demo.saleItem BEFORE UPDATE, 
    ADD BLOCK PREDICATE dbo.ManagedByUser$SecurityPredicate(ManagedByUser) ON Demo.saleItem BEFORE DELETE 
    WITH (STATE = ON, SCHEMABINDING = ON); 
GO

-- Ver GUI


-- BEFORE DELETE

EXECUTE AS USER = 'SmallHat'; 
GO
SELECT * FROM Demo.SaleItem order by 2 DESC;
GO

--SaleItemId	ManagedByUser
--5	SmallHat
--6	SmallHat
--3	MedHat
--4	MedHat
--1	BigHat
--2	BigHat
--7	BigHat
--8	BigHat


SELECT * FROM Demo.SaleItem 
 WHERE SaleItemId = 7
GO

--SaleItemId	ManagedByUser
--7				BigHat

PRINT user
GO
-- Intento borrar un registro que no cumple predicado

DELETE FROM Demo.SaleItem 
WHERE SaleItemId = 7;
GO

--Msg 33504, Level 16, State 1, Line 382
--The attempted operation failed because the target object 'RLS.Demo.SaleItem' has a block predicate that conflicts with this operation. If the operation is performed on a view, the block predicate might be enforced on the underlying table. Modify the operation to target only the rows that are allowed by the block predicate.
--The statement has been terminated.

-- Es de MedHat

DELETE FROM Demo.SaleItem 
WHERE SaleItemId = 3;
GO

--Msg 33504, Level 16, State 1, Line 513
--The attempted operation failed because the target object 'RLS.Demo.SaleItem' has a block predicate that conflicts with this operation. If the operation is performed on a view, the block predicate might be enforced on the underlying table. Modify the operation to target only the rows that are allowed by the block predicate.
--The statement has been terminated.


-- Sin embargo

SELECT * FROM Demo.SaleItem 
 WHERE SaleItemId = 5
GO

--SaleItemId	ManagedByUser
--5				SmallHat

DELETE FROM Demo.SaleItem 
WHERE SaleItemId = 5;
GO

-- (1 row affected)

SELECT * FROM Demo.SaleItem order by 2 DESC;
GO

--SaleItemId	ManagedByUser
--6	SmallHat
--3	MedHat
--4	MedHat
--1	BigHat
--2	BigHat
--7	BigHat
--8	BigHat

REVERT
GO

-- Conclusión:
-- BEFORE DELETE Borra si cumple Predicado

---------------------------------

-- Add a predicate using the same syntax, without knowing the other items 
-- that are in the policy.

ALTER SECURITY POLICY dbo.Demo_SaleItem_SecurityPolicy 
    ADD FILTER PREDICATE dbo.ManagedByUser$SecurityPredicate(ManagedByUser) 
	ON Demo.SaleItem; 
GO 

-- Tenemos
-- Now we have the following policy defined: 

CREATE SECURITY POLICY dbo.Demo_SaleItem_SecurityPolicy 
    ADD FILTER PREDICATE dbo.ManagedByUser$SecurityPredicate(ManagedByUser) ON Demo.SaleItem, 
    ADD BLOCK PREDICATE dbo.ManagedByUser$SecurityPredicate(ManagedByUser) ON Demo.SaleItem AFTER INSERT, 
    ADD BLOCK PREDICATE dbo.ManagedByUser$SecurityPredicate(ManagedByUser) ON Demo.SaleItem BEFORE UPDATE, 
    ADD BLOCK PREDICATE dbo.ManagedByUser$SecurityPredicate(ManagedByUser) ON Demo.SaleItem BEFORE DELETE 
    WITH (STATE = ON, SCHEMABINDING = ON);
GO

--But what if we want to remove a predicate, in this example, say the redundant
--  BEFORE predicates to the FILTER one we just added back. 
-- Note that there is no name to each predicate, so for example, 
-- to drop the different BEFORE BLOCK predicates on Demo.SaleItem: 

ALTER SECURITY POLICY rowLevelSecurity.Demo_SaleItem_SecurityPolicy 
    DROP BLOCK PREDICATE ON Demo.SaleItem BEFORE UPDATE, 
    DROP BLOCK PREDICATE ON Demo.SaleItem BEFORE DELETE;

--  
	
-- With Stored Procedure
 
-- For the final read operation demonstration, lets see how it works from a stored procedure.

CREATE OR ALTER PROCEDURE Demo.SaleItem$select 
AS 
    SET NOCOUNT ON;  
    SELECT USER_NAME(); --Show the userName so we can see the context 
    SELECT * FROM  Demo.SaleItem; 
GO 
GRANT EXECUTE ON   Demo.SaleItem$select to SmallHat, MedHat, BigHat; 

-- Now execute the procedure as the different users (I am only going to include SmallHat to avoid being over repetitive, try it out for yourself) 

EXECUTE AS USER = 'SmallHat'; 
GO 
EXEC Demo.SaleItem$select; 
GO 
REVERT;

--Which returns:

------------------------------- 
--SmallHat

--SaleItemId  ManagedByUser 
------------- --------------- 
--5           SmallHat 
--6           SmallHat

--This shows us that the row level security works as expected without ownership chaining coming into place for the selection of rows, but it does come into play for running the TVF that determines which rows can be seen. In a later entry in this series, I will show how you can use a table in the function if you can't simply code the query to just use system functions.

--So how could you override it? Just like in the Dynamic Data Masking examples, in the procedure code, use WITH EXECUTE AS to elevate to a different users rights (and we will see some other possible solutions later as well in the third entry where I will show some methods of using values other than the simple system functions.)

CREATE OR ALTER PROCEDURE Demo.SaleItem$select 
WITH EXECUTE AS 'BigHat' --use a similar user/role, and avoid dbo/owner if possible to avoid security holes. 
AS 
    SET NOCOUNT ON; 
    SELECT USER_NAME(); 
    SELECT * FROM Demo.SaleItem;
GO
-- Now execute this and note the output:

EXECUTE AS USER = 'smallHat' 
go 
EXEC Demo.SaleItem$select 
GO 
REVERT

-- Not only did you get the elevated rights of the user for objects they own, you now look like that user to the USER_NAME() function which is good for this example.

---------------------------------- 
--BigHat

--SaleItemId  ManagedByUser 
------------- --------------- 
--1           BigHat 
--2           BigHat 
--3           MedHat 
--4           MedHat 
--5           SmallHat 
--6           SmallHat

-- The downside here is that if you are using USER_NAME for any sort of 
-- logging purposes, this might be a bad thing. 
-- I would suggest that if you are using the user's context for logging stuff 
-- like RowLastModifiedByUser, to consider using ORIGINAL_LOGIN(), 
-- which will always return the server principal that the user attached 
-- to the server with.
 

 -- Reset the demo
DROP SECURITY POLICY IF EXISTS Security.patientSecurityPolicy
DROP FUNCTION IF EXISTS Security.patientAccessPredicate
DROP SCHEMA IF EXISTS Security
go
---------

-- PRUEBAS NO INCLUIR


-- Observe existing schema
SELECT * FROM Patients
go

-- Mapping table, assigning application users to patients
-- We'll use RLS to ensure that application users can only access patients assigned to them
SELECT * FROM ApplicationUserPatients
go

-- Create separate schema for RLS objects
-- (not required, but best practice to limit access)
CREATE SCHEMA Security
go

-- Create predicate function for RLS
-- This determines which users can access which rows
CREATE FUNCTION Security.patientAccessPredicate(@PatientID int)
	RETURNS TABLE
	WITH SCHEMABINDING
AS
	RETURN SELECT 1 AS isAccessible
	FROM dbo.ApplicationUserPatients
	WHERE 
	(
		-- application users can access only patients assigned to them
		Patient_PatientID = @PatientID
		AND ApplicationUser_Id = CAST(SESSION_CONTEXT(N'UserId') AS nvarchar(128)) 
	)
	OR 
	(
		-- DBAs can access all patients
		IS_MEMBER('db_owner') = 1
	)
go

-- Create security policy that adds this function as a security predicate on the Patients and Visits tables
--	Filter predicates filter out patients who shouldn't be accessible by the current user
--	Block predicates prevent the current user from inserting any patients who aren't mapped to them
CREATE SECURITY POLICY Security.patientSecurityPolicy
	ADD FILTER PREDICATE Security.patientAccessPredicate(PatientID) ON dbo.Patients,
	ADD BLOCK PREDICATE Security.patientAccessPredicate(PatientID) ON dbo.Patients,
	ADD FILTER PREDICATE Security.patientAccessPredicate(PatientID) ON dbo.Visits,
	ADD BLOCK PREDICATE Security.patientAccessPredicate(PatientID) ON dbo.Visits
go

