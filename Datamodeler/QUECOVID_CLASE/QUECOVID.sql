
USE [QUECOVID_CLASE]
GO


-- set a variable as 
DECLARE @codigopostal as NUMERIC;
SET @codigopostal = 3015 -- 4004 15010
SELECT * 
FROM [dbo].[CODIGOPOSTAL]
WHERE [CP] = @codigopostal   -- 3015;
GO

/*
si ejecuto sin el declare 
Msg 137, Level 15, State 2, Line 11
Must declare the scalar variable "@codigopostal".

*/


-- set a variable as 
DECLARE @codigopostal as NUMERIC;
SET @codigopostal = 3015 -- 4004 15010
SELECT cp.CP, p.NOMBRE_PROVINCIA, c.NOMBRE_CCAA
FROM [dbo].[CODIGOPOSTAL] cp JOIN [dbo].[PROVINCIA] p
ON cp.[PROVINCIA_COD_PROVINCIA] = p.COD_PROVINCIA 
	 JOIN [dbo].[CCAA] c ON p.CCAA_COD_CCAA = c.COD_CCAA
WHERE [CP] = @codigopostal   -- 3015;
GO

-- set a variable as 
DECLARE @codigopostal as NUMERIC;
SET @codigopostal = 15010 -- 4004 15010
SELECT cp.CP, p.NOMBRE_PROVINCIA, c.NOMBRE_CCAA
FROM [dbo].[CODIGOPOSTAL] cp JOIN [dbo].[PROVINCIA] p
ON cp.[PROVINCIA_COD_PROVINCIA] = p.COD_PROVINCIA 
	 JOIN [dbo].[CCAA] c ON p.CCAA_COD_CCAA = c.COD_CCAA
WHERE [CP] = @codigopostal   -- 3015;
GO

--DECLARE @codigopostal  NUMERIC;
--SET @codigopostal = 3015 -- 4004 15010
--SELECT p.[NOMBRE_PROVINCIA],ESTADO.CODIGOPOSTAL_CP
--FROM [dbo].[CODIGOPOSTAL] cp JOIN  [dbo].[PROVINCIA] p
--ON cp.PROVINCIA_COD_PROVINCIA = p.COD_PROVINCIA 
--WHERE [CP] = @codigopostal   -- 3015;
--GO

----
-- Ejercicio COVID

-- [dbo].[CCAA]

--COD_CCAA	NOMBRE_CCAA
--1	Andalucia
--2	Galicia
--3	Valencia

-- [dbo].[PROVINCIA]
--COD_PROVINCIA	NOMBRE_PROVINCIA	CCAA_COD_CCAA
--1	A Coruña	2
--2	Almeria		1
--3	Alicante	3

-- [dbo].[CODIGOPOSTAL]
--CP	POBLACION	PROVINCIA_COD_PROVINCIA
--3015	Alicante	3
--4004	Almeria	    2
--15010	A Coruña	1

-- [dbo].[RESTRICCION]
--COD_RESTRICCION	TIPO_RESTRICCION
--1	Restricción de movilidad
--2	Limitación en Reuniones Sociales
--3	Limitaciones en el comercio,centros comerciales

--[dbo].[OBSERVACION]
--COD_OBSERVACION	COD_RESTRICCION	OBSERVACION
--1				1	Prohibida la entrada y salida de personas del ámbito territorial delimitado conjuntamente por los municipios de A Coruña, Culleredo, Arteixo, Oleiros y Cambre, salvo causa debidamente justificada.
--1	2	Máximo agrupaciones de 5 personas al desarrollo de cualquier actividad o evento de carácter familiar o social en la vía pública, espacios de uso público o espacios privados.
--2	2	Máximo agrupaciones de 2 personas al desarrollo de cualquier actividad o evento de carácter familiar o social en la vía pública, espacios de uso público o espacios privados.




--[dbo].[CODPOSTAL_RESTRICCION_OBSERVACION]
--CODIGOPOSTAL_CP	RESTRICCION_COD_RESTRICCION	OBSERVACION_COD_OBSERVACION
--3015	1	1  
--3015	2	1  
--15010	1	1  
--15010	2	1 
--

USE [QUECOVID_CLASE]
GO

-- 25/11/2020

-- get all restricciones applied to a single CODIGOPOSTAL------------
-- restricciones aplicadas
DECLARE @codigopostal  VARCHAR(5);
SET @codigopostal = 3015; --15010;--3015 -- 4004 ;
SELECT cp.cp,cp.[POBLACION],p.[NOMBRE_PROVINCIA],r.[TIPO_RESTRICCION],o.[OBSERVACION]
FROM [dbo].[CODIGOPOSTAL] cp JOIN  [dbo].[PROVINCIA] p
	ON cp.PROVINCIA_COD_PROVINCIA = p.COD_PROVINCIA
JOIN [dbo].ESTADO e
	ON (cp.[CP] = e.CODIGOPOSTAL_CP)
JOIN [dbo].[RESTRICCION]   r
	ON e.[RESTRICCION_COD_RESTRICCION] = r.[COD_RESTRICCION]
JOIN  [dbo].[OBSERVACION] o
	ON e.[COD_OBSERVACION] = o.[COD_OBSERVACION]
		and e.[RESTRICCION_COD_RESTRICCION]= o.[RESTRICCION_COD_RESTRICCION]
WHERE [CP] = @codigopostal ;
GO

--cp	POBLACION	NOMBRE_PROVINCIA	TIPO_RESTRICCION	OBSERVACION
--15010	A Coruña	A Coruña	Restricción de movilidad	Prohibida la entrada y salida de personas del ámbito territorial delimitado conjuntamente por los municipios de A Coruña, Culleredo, Arteixo, Oleiros y Cambre, salvo causa debidamente justificada.
--15010	A Coruña	A Coruña	Limitación en Reuniones Sociales	Máximo agrupaciones de 5 personas al desarrollo de cualquier actividad o evento de carácter familiar o social en la vía pública, espacios de uso público o espacios privados.

---------------------
--CODIGOPOSTAL_CP	RESTRICCION_COD_RESTRICCION	COD_OBSERVACION
--15010					1		1
--15010					2		1
--3015					1		1
--3015					2		1
--4004					1		1
--4004					1		2
------------
DECLARE @codigopostal  VARCHAR(5);
SET @codigopostal = 3015; --15010 -- 4004 ;
SELECT cp.cp,cp.[POBLACION],p.[NOMBRE_PROVINCIA],r.[TIPO_RESTRICCION],o.[OBSERVACION]
FROM [dbo].[CODIGOPOSTAL] cp JOIN  [dbo].[PROVINCIA] p
	ON cp.PROVINCIA_COD_PROVINCIA = p.COD_PROVINCIA 
JOIN [dbo].ESTADO e
	ON (cp.[CP] = e.CODIGOPOSTAL_CP) 
JOIN [dbo].[RESTRICCION] r
	ON e.[RESTRICCION_COD_RESTRICCION] = r.[COD_RESTRICCION]
JOIN  [dbo].[OBSERVACION] o
	ON e.[COD_OBSERVACION] = o.[COD_OBSERVACION]
		and e.[RESTRICCION_COD_RESTRICCION]= o.[RESTRICCION_COD_RESTRICCION]
WHERE [CP] = @codigopostal ;
GO


----cp	POBLACION	NOMBRE_PROVINCIA	TIPO_RESTRICCION	OBSERVACION
----3015	Alicante	Alicante	Restricción de movilidad	Prohibida la entrada y salida de personas del ámbito territorial delimitado conjuntamente por los municipios de A Coruña, Culleredo, Arteixo, Oleiros y Cambre, salvo causa debidamente justificada.
----3015	Alicante	Alicante	Limitación en Reuniones Sociales	Máximo agrupaciones de 2 personas al desarrollo de cualquier actividad o evento de carácter familiar o social en la vía pública, espacios de uso público o espacios privados.


DECLARE @codigopostal  VARCHAR(5);
SET @codigopostal = 4004 ;
SELECT cp.cp,cp.[POBLACION],p.[NOMBRE_PROVINCIA],r.[TIPO_RESTRICCION],o.[OBSERVACION]
FROM [dbo].[CODIGOPOSTAL] cp JOIN  [dbo].[PROVINCIA] p
	ON cp.PROVINCIA_COD_PROVINCIA = p.COD_PROVINCIA 
JOIN [dbo].ESTADO e
	ON (cp.[CP] = e.CODIGOPOSTAL_CP) 
JOIN [dbo].[RESTRICCION] r
	ON e.[RESTRICCION_COD_RESTRICCION] = r.[COD_RESTRICCION]
JOIN  [dbo].[OBSERVACION] o
	ON e.[COD_OBSERVACION] = o.[COD_OBSERVACION]
		and e.[RESTRICCION_COD_RESTRICCION]= o.[RESTRICCION_COD_RESTRICCION]
WHERE [CP] = @codigopostal ;
GO

--cp	POBLACION	NOMBRE_PROVINCIA	TIPO_RESTRICCION	OBSERVACION
--4004	ALMERIA	ALMERIA	Restricción de movilidad	Prohibida la entrada y salida de personas del ámbito territorial delimitado conjuntamente por los municipios de A Coruña, Culleredo, Arteixo, Oleiros y Cambre, salvo causa debidamente justificada.
--4004	ALMERIA	ALMERIA	Limitación en Reuniones Sociales	Máximo agrupaciones de 2 personas al desarrollo de cualquier actividad o evento de carácter familiar o social en la vía pública, espacios de uso público o espacios privados. 

-- STORED PROCEDURE (Procedimiento Almacenado)

USE [QUECOVID1]
GO
CREATE OR ALTER PROCEDURE quecovid
	@codigopostal  VARCHAR(5) = '15010'
AS
	SELECT cp.cp,cp.[POBLACION],p.[NOMBRE_PROVINCIA],r.[TIPO_RESTRICCION],o.[OBSERVACION]
	FROM [dbo].[CODIGOPOSTAL] cp JOIN  [dbo].[PROVINCIA] p
		ON cp.PROVINCIA_COD_PROVINCIA = p.COD_PROVINCIA 
	INNER JOIN [dbo].ESTADO e
		ON (cp.[CP] = e.CODIGOPOSTAL_CP) 
	JOIN [dbo].[RESTRICCION] r
		ON e.[RESTRICCION_COD_RESTRICCION] = r.[COD_RESTRICCION]
	JOIN  [dbo].[OBSERVACION] o
		ON e.[COD_OBSERVACION] = o.[COD_OBSERVACION]
			and e.[RESTRICCION_COD_RESTRICCION]= o.[RESTRICCION_COD_RESTRICCION]
	WHERE [CP] = @codigopostal 
GO
EXECUTE quecovid
GO
EXECUTE quecovid '15010'
GO
EXECUTE quecovid '4004'
GO
EXECUTE quecovid '3015'
GO