--
-- RLS admite dos tipos de predicados de seguridad.
-- FILTER   Controla read (Select Update Delete)
-- BLOCK	Controla Write (Insert Update Delete)



-- Los predicados de filtro filtran en modo silencioso las filas disponibles 
-- para leer operaciones (SELECT, UPDATE y DELETE).

-- Los predicados de bloqueo bloquean expl�citamente las operaciones de escritura 
-- (AFTER INSERT, AFTER UPDATE, BEFORE UPDATE, BEFORE DELETE) 
-- que infringen el predicado.

---
--Los predicados de filtro se aplican al leer los datos de la tabla base y afectan a todas las operaciones get: SELECT, DELETE (por ejemplo, el usuario no puede eliminar las filas filtradas) y UPDATE (por ejemplo, el usuario no puede actualizar las filas filtradas, aunque es posible actualizar las filas de modo que se filtren posteriormente). Los predicados de bloqueo afectan a todas las operaciones de escritura.

--Los predicados AFTER INSERT y AFTER UPDATE pueden impedir que los usuarios actualicen las filas con valores que infrinjan el predicado.

--Los predicados BEFORE UPDATE pueden impedir que los usuarios actualicen las filas que actualmente infrinjan el predicado.

--Los predicados BEFORE DELETE pueden bloquear las operaciones de eliminaci�n.

------

-- EJEMPLO 1

USE Tempdb
GO
DROP TABLE IF EXISTS [dbo].[Ventas]
GO
CREATE TABLE [dbo].[Ventas](
 [Ventas] [int] IDENTITY(1,1) NOT NULL,
 [Producto] [int] NULL,
 [Fecha] [datetime] NULL,
 [Cantidad] [int] NULL,
 [Usuario] [varchar](50) NULL,
 CONSTRAINT [PK_Ventas] PRIMARY KEY CLUSTERED 
(
 [Ventas] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET IDENTITY_INSERT [dbo].[Ventas] ON 

INSERT [dbo].[Ventas] ([Ventas], [Producto], [Fecha], [Cantidad], [Usuario]) VALUES (2, 1, CAST(N'2016-12-02T12:46:38.333' AS DateTime), 4, N'RAUL')
INSERT [dbo].[Ventas] ([Ventas], [Producto], [Fecha], [Cantidad], [Usuario]) VALUES (3, 1, CAST(N'2016-12-02T12:46:38.333' AS DateTime), 5, N'RAUL')
INSERT [dbo].[Ventas] ([Ventas], [Producto], [Fecha], [Cantidad], [Usuario]) VALUES (4, 1, CAST(N'2016-12-02T12:46:38.333' AS DateTime), 6, N'JORGE')
INSERT [dbo].[Ventas] ([Ventas], [Producto], [Fecha], [Cantidad], [Usuario]) VALUES (5, 1, CAST(N'2016-12-02T12:46:38.333' AS DateTime), 7, N'JORGE')
INSERT [dbo].[Ventas] ([Ventas], [Producto], [Fecha], [Cantidad], [Usuario]) VALUES (6, 1, CAST(N'2016-12-02T12:46:38.333' AS DateTime), 8, N'MANUEL')
INSERT [dbo].[Ventas] ([Ventas], [Producto], [Fecha], [Cantidad], [Usuario]) VALUES (7, 1, CAST(N'2016-12-02T12:46:38.333' AS DateTime), 9, N'MARIA')
INSERT [dbo].[Ventas] ([Ventas], [Producto], [Fecha], [Cantidad], [Usuario]) VALUES (8, 1, CAST(N'2016-12-02T12:46:38.333' AS DateTime), 10, N'JOSE')
SET IDENTITY_INSERT [dbo].[Ventas] OFF
GO

SELECT TOP (1000) [Ventas]
 ,[Producto]
 ,[Fecha]
 ,[Cantidad]
 ,[Usuario]
 FROM [Ventas]
 GO

CREATE USER RAUL WITHOUT LOGIN;
CREATE USER JORGE WITHOUT LOGIN;
CREATE USER MANUEL WITHOUT LOGIN;
CREATE USER MARIA WITHOUT LOGIN;
GO
GRANT SELECT ON dbo.Ventas TO RAUL;
GRANT SELECT ON dbo.Ventas TO JORGE;
GRANT SELECT ON dbo.Ventas TO MANUEL;
GRANT SELECT ON dbo.Ventas TO MARIA;
GO

-- VER SSMS  PROGRAMMABILITY FUNCTIONS TABLE-VALUED FUNCTIONS

Create or alter Function fn_securitypredicateVentas(@processedby sysname)
returns table
with Schemabinding
as
	return select 1 as [fn_securityPredicateVentas_result]
	from dbo.Ventas
	where @processedby = user_name()
GO

-- VER SSMS SECURITY SECURITY POLICIES

CREATE SECURITY POLICY FiltrarTrabajador
ADD FILTER PREDICATE dbo.fn_securitypredicateVentas(Usuario)
ON dbo.Ventas
WITH (STATE = ON);
GO

EXECUTE AS USER = 'RAUL';
SELECT *
FROM Ventas;
REVERT;
GO


--Ventas	Producto	Fecha	Cantidad	Usuario
--2	1	2016-12-02 12:46:38.333	4	RAUL
--3	1	2016-12-02 12:46:38.333	5	RAUL


EXECUTE AS USER = 'MANUEL';
SELECT *
FROM Ventas;
REVERT;
GO

--Ventas	Producto	Fecha	Cantidad	Usuario
--6	1	2016-12-02 12:46:38.333	8	MANUEL


----------------------------------------


-- EJEMPLO 2

-- FILTER PREDICATE (READ)
-- BLOCK PREDICATE  (WRITE)


--  Crea tres usuarios, crea y llena una tabla con seis filas, y 
--  crea una funci�n de valores de tabla insertada y una directiva de seguridad de la tabla. 
-- El ejemplo muestra c�mo seleccionar instrucciones filtradas para los distintos usuarios.

USE TEMPDB
GO
DROP USER IF EXISTS Manager
GO
DROP USER IF EXISTS Sales1
GO
DROP USER IF EXISTS Sales2
GO
CREATE USER Manager WITHOUT LOGIN;  
CREATE USER Sales1 WITHOUT LOGIN;  
CREATE USER Sales2 WITHOUT LOGIN;
GO

DROP TABLE If Exists Sales
GO
CREATE TABLE Sales  
    (  
    OrderID int,  
    SalesRep sysname,  
    Product varchar(10),  
    Qty int  
    );
GO


INSERT Sales VALUES   
(1, 'Sales1', 'Valve', 5),   
(2, 'Sales1', 'Wheel', 2),   
(3, 'Sales1', 'Valve', 4),  
(4, 'Sales2', 'Bracket', 2),   
(5, 'Sales2', 'Wheel', 5),   
(6, 'Sales2', 'Seat', 5); 
GO 
-- View the 6 rows in the table  
SELECT * FROM Sales;
GO

GRANT SELECT ON Sales TO Manager;  
GRANT SELECT ON Sales TO Sales1;  
GRANT SELECT ON Sales TO Sales2;
GO

DROP Function IF Exists fn_securitypredicate
GO
-- Creamos una funci�n de valores de tabla insertada (TABLE-VALUED FUNCTIONS) 
-- La funci�n devuelve 1 cuando una fila de la columna SalesRep es la misma que el usuario 
-- que ejecuta la consulta (@SalesRep = USER_NAME()) 
-- o si el usuario que ejecuta la consulta es el usuario administrador (USER_NAME() = 'Manager').

CREATE OR ALTER FUNCTION fn_securitypredicate(@SalesRep AS sysname)  
    RETURNS TABLE  
WITH SCHEMABINDING  
AS  
    RETURN SELECT 1 AS fn_securitypredicate_result   
		WHERE @SalesRep = USER_NAME() OR USER_NAME() = 'Manager';
GO

-- Importante: Este error se corrige poniendo dbo

-- Msg 4512, Level 16, State 3, Line 133
-- Cannot schema bind security policy 'SalesFilter' because name 'fn_securitypredicate' is invalid for schema binding. Names must be in two-part format and an object cannot reference itself.

-- Cree una directiva de seguridad agregando la funci�n como un predicado de filtro. 
-- El estado se debe configurar en ON para habilitar la directiva.

-- Error
CREATE SECURITY POLICY SalesFilter  
ADD FILTER PREDICATE fn_securitypredicate(SalesRep)   
ON dbo.Sales  
WITH (STATE = ON);
GO

--Msg 4512, Level 16, State 3, Line 147
--Cannot schema bind security policy 'SalesFilter' because name 'fn_securitypredicate' is invalid for schema binding. Names must be in two-part format and an object cannot reference itself.


-- Sin Error porque a�ado dbo

CREATE SECURITY POLICY SalesFilter  
ADD FILTER PREDICATE dbo.fn_securitypredicate(SalesRep)   
ON dbo.Sales  
WITH (STATE = ON);
GO

-- Probamos ahora el predicado de filtrado seleccionando de la tabla Ventas como cada usuario.

-- El administrador debe ver las 6 filas. 
-- Los usuarios Sales1 y Sales2 solo deben ver sus propias ventas.


EXECUTE AS USER = 'Sales1';  
SELECT * FROM Sales; 
GO 

--OrderID	SalesRep	Product	Qty
--1	Sales1	Valve	5
--2	Sales1	Wheel	2
--3	Sales1	Valve	4 

REVERT;  
GO
EXECUTE AS USER = 'Sales2';  
SELECT * FROM Sales; 
GO  

--OrderID	SalesRep	Product	Qty
--4	Sales2	Bracket	2
--5	Sales2	Wheel	5
--6	Sales2	Seat	5

REVERT;  
GO
EXECUTE AS USER = 'Manager';  
SELECT * FROM Sales; 
GO  

--OrderID	SalesRep	Product	Qty
--1	Sales1	Valve	5
--2	Sales1	Wheel	2
--3	Sales1	Valve	4
--4	Sales2	Bracket	2
--5	Sales2	Wheel	5
--6	Sales2	Seat	5


REVERT;  
GO

-- El administrador debe ver las 6 filas. 
-- Los usuarios Sales1 y Sales2 solo deben ver sus propias ventas.

-- Modificamos la directiva de seguridad para deshabilitarla.

ALTER SECURITY POLICY SalesFilter  
WITH (STATE = OFF);
GO

-- Ahora los usuarios Sales1 y Sales2 pueden ver las 6 filas


EXECUTE AS USER = 'Sales1';  
SELECT * FROM Sales; 
GO 
REVERT
GO
EXECUTE AS USER = 'Sales2';  
SELECT * FROM Sales; 
GO 
REVERT
GO
-------------------------------------
-- ESTE EJEMPLO SER�A SI TENEMOS UNA APLICACI�N DE TERCEROS CONECTADOS (CONTEXT)


-- Escenario para los usuarios que se conectan a la base de datos a trav�s de una aplicaci�n de nivel intermedio
-- Este ejemplo muestra c�mo una aplicaci�n de nivel intermedio puede implementar el filtrado de conexiones, 
-- donde los usuarios de la aplicaci�n (o inquilinos) comparten el mismo usuario de SQL Server (la aplicaci�n). 
-- La aplicaci�n configura el identificador de usuario de la aplicaci�n actual en SESSION_CONTEXT (Transact-SQL) 
-- despu�s de conectarse a la base de datos y, luego, las directivas de seguridad filtran de forma transparente las filas
--  que no deber�an ser visibles para este identificador e impiden tambi�n que el usuario inserte filas para el 
-- identificador de usuario incorrecto.  
-- No es necesario ning�n otro cambio en la aplicaci�n.

-- Cree una tabla sencilla para almacenar los datos.

USE Tempdb
GO
DROP Table If Exists Sales
GO

-- Error
--Msg 3729, Level 16, State 1, Line 179
--Cannot DROP TABLE 'Sales' because it is being referenced by object 'SalesFilter'.

-- Tengo que borrar la funci�n
CREATE FUNCTION fn_securitypredicate(@SalesRep AS sysname)  
    RETURNS TABLE  
WITH SCHEMABINDING  
AS  
    RETURN SELECT 1 AS fn_securitypredicate_result   
WHERE @SalesRep = USER_NAME() OR USER_NAME() = 'Manager';
GO

DROP Function If Exists fn_securitypredicate
GO
--Msg 3729, Level 16, State 1, Line 194
--Cannot DROP FUNCTION 'fn_securitypredicate' because it is being referenced by object 'SalesFilter'.


ALTER SECURITY POLICY SalesFilter  
WITH (STATE = OFF);
GO

DROP SECURITY POLICY SalesFilter
GO
DROP Function If Exists fn_securitypredicate
GO


DROP Table If Exists Sales
GO
CREATE TABLE Sales (  
    OrderId int,  
    AppUserId int,  
    Product varchar(10),  
    Qty int  
);
GO

INSERT Sales VALUES   
    (1, 1, 'Valve', 5),   
    (2, 1, 'Wheel', 2),   
    (3, 1, 'Valve', 4),  
    (4, 2, 'Bracket', 2),   
    (5, 2, 'Wheel', 5),   
    (6, 2, 'Seat', 5);
GO

-- Cree un usuario con pocos privilegios que la aplicaci�n usar� para conectarse.

-- Without login only for demo  
CREATE USER AppUser WITHOUT LOGIN;   
GRANT SELECT, INSERT, UPDATE, DELETE ON Sales TO AppUser;  
GO
-- Never allow updates on this column  
DENY UPDATE ON Sales(AppUserId) TO AppUser;
GO

-- Creamos una funci�n de predicado nuevos, que usar�n el identificador de usuario de la aplicaci�n almacenado en SESSION_CONTEXT para filtrar las filas.


CREATE FUNCTION fn_securitypredicate(@AppUserId int)  
    RETURNS TABLE  
    WITH SCHEMABINDING  
AS  
    RETURN SELECT 1 AS fn_securitypredicate_result  
    WHERE  
        DATABASE_PRINCIPAL_ID() = DATABASE_PRINCIPAL_ID('AppUser')    
        AND CAST(SESSION_CONTEXT('UserId') AS int) = @AppUserId; 
GO


--Msg 8116, Level 16, State 1, Procedure fn_securitypredicate, Line 5 [Batch Start Line 241]
--Argument data type varchar is invalid for argument 1 of session_context function.

-- Cree una directiva de seguridad que agregue esta funci�n como un predicado de filtro y 
-- un predicado de bloqueo en Sales. 
-- El predicado de bloqueo solo necesita AFTER INSERT, ya que BEFORE UPDATE y BEFORE DELETE ya est�n filtrados 
-- y AFTER UPDATE no es necesario porque la columna AppUserId no se puede actualizar con otros valores debido 
-- al permiso de columna que se ha establecido anteriormente.

CREATE SECURITY POLICY SalesFilter 
    ADD FILTER PREDICATE dbo.fn_securitypredicate(AppUserId)   
        ON dbo.Sales,  
    ADD BLOCK PREDICATE dbo.fn_securitypredicate(AppUserId)   
        ON dbo.Sales AFTER INSERT   
    WITH (STATE = ON);
GO

-- Ahora podemos simular el filtrado de conexiones al seleccionar la tabla Sales despu�s de configurar los distintos identificadores de usuario en SESSION_CONTEXT. En la pr�ctica, la aplicaci�n es responsable de establecer el identificador de usuario actual en SESSION_CONTEXT despu�s de abrir una conexi�n.

EXECUTE AS USER = 'AppUser'; 
GO 
EXEC sp_set_session_context @key=N'UserId', @value=1; 
GO 
SELECT * FROM Sales;  
GO  


--OrderId	AppUserId	Product	Qty
--1	1	Valve	5
--2	1	Wheel	2
--3	1	Valve	4



--  Note: @read_only prevents the value from changing again   
--  until the connection is closed (returned to the connection pool)  
EXEC sp_set_session_context @key='UserId', @value=2, @read_only=1;   
GO
SELECT * FROM Sales;  
GO  


--OrderId	AppUserId	Product	Qty
--4	2	Bracket	2
--5	2	Wheel	5
--6	2	Seat	5


INSERT INTO Sales VALUES (7, 1, 'Seat', 12); -- error: blocked from inserting row for the wrong user ID  
GO  


--Msg 33504, Level 16, State 1, Line 297
--The attempted operation failed because the target object 'tempdb.dbo.Sales' has a block predicate that conflicts with this operation. If the operation is performed on a view, the block predicate might be enforced on the underlying table. Modify the operation to target only the rows that are allowed by the block predicate.
--The statement has been terminated.

REVERT;  
GO







-- 