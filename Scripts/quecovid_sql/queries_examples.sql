-- 23/ 11 / 2020
USE [QUECOVID_CLASE]
GO


-- set a variable as
DECLARE @codigopostal as NUMERIC;
SET @codigopostal = 3015 -- 4004 15010 alternatives for declaration
SELECT *
FROM [dbo].[CODIGOPOSTAL]
WHERE [CP] = @codigopostal   -- 3015;
GO

/*
without declare if I execute it I get:
Msg 137, Level 15, State 2, Line 11
Must declare the scalar variable "@codigopostal".

*/

-- set a variable as codigopostal to only change it
DECLARE @codigopostal as NUMERIC;
SET @codigopostal = 3015 -- 4004 15010
SELECT cp.CP, p.NOMBRE_PROVINCIA, c.NOMBRE_CCAA
FROM [dbo].[CODIGOPOSTAL] cp JOIN [dbo].[PROVINCIA] p
ON cp.[PROVINCIA_COD_PROVINCIA] = p.COD_PROVINCIA
	 JOIN [dbo].[CCAA] c ON p.CCAA_COD_CCAA = c.COD_CCAA
WHERE [CP] = @codigopostal   -- 3015;
GO

-- 25/11/2020
-- annotation: JOIN by defaul is understood as INNER JOIN
-- get all restricciones applied to a single CODIGOPOSTAL------------
-- get restricciones by CP

DECLARE @codigopostal  VARCHAR(5);
SET @codigopostal = 3015; --15010;--3015 -- 4004 ;
SELECT cp.cp,cp.[POBLACION],p.[NOMBRE_PROVINCIA],r.[TIPO_RESTRICCION],o.[OBSERVACION]
FROM [dbo].[CODIGOPOSTAL] cp
  JOIN  [dbo].[PROVINCIA] p
  	ON cp.[PROVINCIA_COD_PROVINCIA] = p.[COD_PROVINCIA]
  JOIN [dbo].ESTADO e
  	ON (cp.[CP] = e.[CODIGOPOSTAL_CP])
  JOIN [dbo].[RESTRICCION]   r
  	ON e.[RESTRICCION_COD_RESTRICCION] = r.[COD_RESTRICCION]
  JOIN  [dbo].[OBSERVACION] o
    --must match both conditions in this last table
  	ON e.[COD_OBSERVACION] = o.[COD_OBSERVACION]
  		and e.[RESTRICCION_COD_RESTRICCION]= o.[RESTRICCION_COD_RESTRICCION]
WHERE [CP] = @codigopostal ;
GO

-- results
-- cp	POBLACION	NOMBRE_PROVINCIA	TIPO_RESTRICCION	OBSERVACION
-- 3015	ALMERIA	ALICANTE	Restricción de movilidad	Prohibida la entrada y salida de personas del ámbito territorial delimitado conjuntamente por los municipios de A Coruña, Culleredo, Arteixo, Oleiros y Cambre, salvo causa debidamente justificada.
-- 3015	ALMERIA	ALICANTE	Restricción de movilidad	Restricción de entradas y salidas de la comunidad autónoma, salvo desplazamientos por motivos laborales, de estudios, cuidado de familiares, retorno al lugar de residencia y otras razones de fuerza mayor.

/*
 Explanation
 There are local varaibles(created by user) and global variables(system)
 SQL has not implicit memory reservation, so we have to DECLARE the variable
  -> we have to provide a type for the variable
  -> in some specific types we have to provide a size for the variables .
  For example: VARCAHS(5) for codigopostal
  -> the we use SET to establish first value for the declare

  *** WATCH OUT!!! ***
  we have to use the declared variable befor launch a GO ending sentence,
  if not in this way, we lose the reserved memory spot.
 */
