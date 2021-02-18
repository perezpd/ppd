--TRIGGER EL SIGNIFICADO ES DISPARADOR Y SE PUEDE ENCUADRAR DENTRO DE LOS STORED PROCEDURES.

--ES UN PROCEDIMIENTO ALMACENADO QUE SE EJECUTE CUANDO OCURRE UNA DETERMINADA ACCIÓN. ES COMO LA RESPUESTA A ESA ACCIÓN.
-- ESTA POSIBLE ACCIÓN PODRÍA SER UNA INSERCIÓN, UN BORRADO.

-- UN PRIMER NIVEL ES DONDE SE EJECUTA EL TRIGGER, Y LOS NIVELES QUE HAY SON: A NIVEL SERVER, A NIVEL DATABASE Y A NIVEL DE TABLE/VIEW

-- A NIVEL TABLE/VIEW ESTÁN LOS AFTER (DESPUÉS) Y INSTEAD OF (EN LUGAR DE)


-- POR ÚLTIMO, EN LOS TRIGGERS COMO EN LAS RESTRICCIONES PODEMOS TENERLOS HABILITADOS, DEHABILITADOS (ENABLE/DISABLE)

-- VAMOS A CONTROLAR QUE NO SE PUEDAN BORRAR TABLAS A NIVEL DATABASE. A NIVEL SERVER CONTROL DE USUARIOS.





/*FORMA*/
-- CREATE [OR ALTER] TRIGGER [schema_name .] trigger_name --> corchetes implica opcionalidad por ello si pongo si no pongo schema pone dbo
-- ON {table | view } --> brackets implican opción. O una u otra
-- [WITH <dml_trigger_option> [,...n]]
--{ FOR | AFTER | INSTEAD OF }   
--{ [ INSERT ] [ , ] [ UPDATE ] [ , ] [ DELETE ] }   
--[ WITH APPEND ]  
--[ NOT FOR REPLICATION ]   
--AS { sql_statement  [ ; ] [ ,...n ] | EXTERNAL NAME <method specifier [ ; ] > }  
  
--<dml_trigger_option> ::=  
   -- [ ENCRYPTION ]  
    --[ EXECUTE AS Clause ]  
  
--<method_specifier> ::=  
 --   assembly_name.class_name.method_name  


 /*********************TRIGGER SERVER************************/
 -- FOR E INSTEAD OF NO SE APLICAN SOBRE SERVERS
 USE master
 GO

 DROP TRIGGER IF EXISTS trg_NoNuevoLogin --> trg es como sp (stored procedures), significa trigger y es una notación recomendada por Windows


 CREATE OR ALTER TRIGGER trg_NoNuevoLogin
 ON ALL SERVER --SERVER LEVEL
 FOR CREATE_LOGIN -- Sentencia a controlar (puede hacer más de una) --> La más típica es la palabra reservada CREATE_LOGIN
 AS --> CUERPO DEL TRIGGER
	PRINT 'No login creations without DBS involvement'
	ROLLBACK TRAN --> Provoca que la sentencia no se provoque. Es el antónimo de EXECUTE
GO

/*AQUI LO QUE HACEMOS ES QUE SOBRE LA PALABRA RESERVADA CREATE_LOGIN, LO PROHIBE Y TE ENSEÑA EL BANNER*/


--Intentamos crear un login y nos va a dar error
CREATE LOGIN Joe WITH PASSWORD ='Abcd .1234'
GO
--No login creations without DBS involvement --> BANNER
--Msg 3609, Level 16, State 2, Line 55
--The transaction ended in the trigger. The batch has been aborted. --> ROLLBACK


/*A EFECTOS DE OBJECT EXPLORER ME LO CREA EN LA CARPETA SERVER OBJECTS>TRIGGERS. AHÍ PODRÍA SACARLO CON CREATE O NEW QUERY EDITOR*/

--Vemos que no nos deja
-- En vez de print podríamos hacer lo mismo con un RAISERROR

DISABLE trigger ALL ON ALL SERVER;
GO

DISABLE Trigger ALL ON ALL SERVER;
GO

-- El trigger está activado. Si queremos borrarlo: DROP
DROP TRIGGER trg_NoNuevoLogin
GO




------------------------------------------PERMISOS A NIVEL BASE DE DATOS-------------------------------------------------------
--En el entorno gráfico este tipo de trigger aparece dentro de 'programmability'

USE pubs
GO

--Primero Creamos una tabla con select into
IF OBJECT_ID ('Autores', 'U') IS NOT NULL
	DROP TABLE Autores;
GO
	
DROP TABLE IF EXISTS Autores
GO


SELECT *
		into autores
		from authors
GO

SELECT * FROM Autores

--Creamos el trigger (el FOR AFTER, no es necesario, llega con poner FOR)
IF OBJECT_ID('trg_PrevenirBorrado', 'TR') IS NOT NULL
	DROP TRIGGER trg_PrevenirBorrado
GO

DROP TRIGGER IF EXISTS trg_PreveniBorrado
GO


CREATE OR ALTER TRIGGER trg_PreveniBorrado
ON DATABASE
FOR DROP_TABLE, ALTER_TABLE

AS
	RAISERROR ('No se puede borrar o modificar tablas',16,1)
	ROLLBACK TRAN
GO

--Probamos a borrar la tabla recien creada
DROP TABLE Autores;
GO
-- Vemos que no nos deja y nos devuelve el siguiente mensaje
/*
Msg 50000, Level 16, State 1, Procedure trg_PreveniBorrado, Line 6 [Batch Start Line 121]
No se puede borrar o modificar tablas
Msg 3609, Level 16, State 2, Line 123
The transaction ended in the trigger. The batch has been aborted.
*/


/*EN EL OBJECT EXPLORER ESTÁ EN BASE DE DATOS>PROGRAMMABILITY>DATABSE TRIGGERS*/

DISABLE TRIGGER trg_PreveniBorrado
ON DATABASE;
GO


DROP TABLE Autores;
GO
--RECREAMOS LA TABLA AUTORES


SELECT *
		into autores
		from authors
GO

SELECT * FROM Autores;
GO


ENABLE TRIGGER trg_PreveniBorrado ON DATABASE;
GO
DROP TABLE Autores;
GO

--Para Borrar
DROP TRIGGER trg_PreveniBorrado
GO

-- Si no funciona borrar, lo hacemos en el GUI


/*****************A NIVEL DE TABLA/VISTA******************/

-- NO SE CONTROLAN TRIGGERS DE VARIAS TABLAS EN UNA MISMA INSTRUCCIÓN

--Después de una inserción o un update en la tabla autores

use pubs
Go

IF OBJECT_ID ('Autores', 'U') IS NOT NULL
	DROP TABLE Autores;
GO
	
DROP TABLE IF EXISTS Autores
GO


SELECT *
		into autores
		from authors
GO

SELECT * FROM Autores


--Controlo el trigger
IF OBJECT_ID ('Trg_DarAutor', 'TR') IS NOT NULL
	DROP TRIGGER trg_DarAutor;
GO

DROP TRIGGER IF EXISTS trg_DarAutor
GO


-- Creamos un trigger que nos ejecute un raiserror y un procedimiento almacenado
-- Después de una inserción o un update en la tabla autores
CREATE OR ALTER TRIGGER trg_DarAutor
ON AUTORES
AFTER INSERT, UPDATE --SI ponermos FOR es un 'After' --> hacen la misma función
AS
	RAISERROR (50009,16,10)
	EXEC sp_helpdb pubs
GO
/*EL TRIGER CONTROLA OPERACIONES DE ACTUALIZACIÓN, LO QUE HACE ES EJECUTAR UNA OPERACIÓN DE ACTUALIZCIÓN, TE DA EL RAISERROR Y A MAYORES EXJECUTA*/	


--Comprobamos

Select * from Autores;
GO


--Lo probamos
UPDATE autores
	SET au_lname = 'Black'
	Where au_fname = 'Johnson';
GO
--Msg 18054, Level 16, State 1, Procedure trg_DarAutor, Line 5 [Batch Start Line 211]
--Error 50009, severity 16, state 10 was raised, but no message with that error number was found in sys.messages. If error is larger than 50000, make sure the user-defined message is added using sp_addmessage.
 

 Select * from Autores;
GO

DISABLE TRIGGER trg_DarAutor ON Autores
GO

ENABLE TRIGGER trg_DarAutor ON Autores
GO


DROP TRIGGER trg_DarAutor
GO

-- vamos a por el último
CREATE OR ALTER TRIGGER trg_borra
On Autores
FOR DELETE, UPDATE
AS
	RAISERROR ('%d filas modificadas en la tabla Autores', 16,1,@@rowcount) --> es una especie de formato %d
GO

SELECT*
FROM autores
Where au_fname = 'Johnson'
GO

--Try out
DELETE Autores
Where au_fname= 'Johnson';
GO

--Msg 50000, Level 16, State 1, Procedure trg?borra, Line 5 `Batch Start Line 246+
--1 filas modificadas en la tabla Autores

SELECT*
FROM autores
Where au_fname = 'Johnson'
GO

--cerramos el circulo deshabilitando habilitando y borrando

DISABLE TRIGGER trg_borra ON Autores
GO

ENABLE TRIGGER trg_borra ON Autores
GO

DROP TRIGGER trg_borra
GO

/**********************CREAMOS UN TRIGGER SOBRE UNA VISTA******************/
USE pubs
GO

-- Creamos la vista
CREATE OR ALTER VIEW vAutores -- El nombre de la notación es la recomendada por Microsoft
AS
	SELECT * -- LA VISTA ES LA DE LA TABLA, ES UNA INUTIL AL NO TENER UN WHERE
	FROM autores
GO

-- CREAMOS UN TRIGGER PARA LA VISTA ( DE TIPO INSTEAD OF)

CREATE OR ALTER TRIGGER trg_BorrarVista
	ON vAutores -- En la vista
	INSTEAD OF DELETE -- Cuando alguien intente borrar, haz lo que pone el código dentro del AS
AS	
	PRINT 'No puedes borrar la visa'
GO

-- VEO LO QUE HACE AUTORES
SELECT *
FROM vAutores
GO

-- LANZO EL DELETE
DELETE FROM vAutores
GO

-- Nos devuelve el banner
--No puedes borrar la visa
-- (22 rows affected)

SELECT *
FROM vAutores
GO
-- VEMOS QUE ESTÁ TODO IGUAL, ES DECIR, EL TRIGGER EVITÓ EL DELETE
-- Y EN SU LUGAR NOS MOSTRÓ EL MENSAJE 'No puedes borrar la vista'



DROP TRIGGER trg_BorrarVista
GO



/***************TRIGGERS SOBRE TABLAS TEMPORALES DE TRIGGERS *********/
--Hay dos tipos de tablas temporales: insertes y deleted
USE pubs
GO



--IF OBJECT_DEFINITION_ID ('trg_tablasTemporales', 'TR') IS NOT NULL
--	DROP TRIGGER trg_TablasTemporales;
--GO

DROP TRIGGER IF EXISTS trg_TablasTemporales
GO
CREATE OR ALTER TRIGGER trg_TablasTemporales
ON Autores
AFTER UPDATE
AS
	PRINT 'Tabla inserted'
	SELECT * FROM inserted
	PRINT 'Tabla deleted'
	SELECT * FROM deleted
GO





SELECT *
FROM autores
GO

--TRY OUT
UPDATE autores
set au_lname= 'VERDE'
WHERE au_fname= 'Marjorie'
GO


-- Otro ejemplo pero usando los registros a la vez

--Usaos el mismo trigger anterior
SELECT * FROM autores
GO
UPDATE autores
SET city= 'A Coruña'
WHERE contract= 0 ;
GO



























































