-- 1/ 12 / 2020
USE [QUECOVID_CLASE]
GO

-- annotation: JOIN by default is understood as INNER JOIN
-- get all restricciones applied to a single CODIGOPOSTAL------------
-- get restricciones by CP

-- how to create procedure
CREATE OR ALTER PROCEDURE quecovid
-- here we put the parameters separated by comma if we have more than one
-- we set teh taype of the parameters and optinoal the default value with eqal sign
	 @codigopostal VARCHAR(5) = '3015' --15010;--3015 -- 4004 ;
AS
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

-- then we execute this way
-- without parameters
EXECUTE quecovid
GO
-- results
--cp	POBLACION	NOMBRE_PROVINCIA	TIPO_RESTRICCION	OBSERVACION
--3015	ALMERIA	ALICANTE	Restricción de movilidad	Prohibida la entrada y salida de personas del ámbito territorial delimitado conjuntamente por los municipios de A Coruña, Culleredo, Arteixo, Oleiros y Cambre, salvo causa debidamente justificada.
--3015	ALMERIA	ALICANTE	Restricción de movilidad	Restricción de entradas y salidas de la comunidad autónoma, salvo desplazamientos por motivos laborales, de estudios, cuidado de familiares, retorno al lugar de residencia y otras razones de fuerza mayor.

-- with a single parameter of codigopostal
EXECUTE quecovid '15010'
GO
--results
--cp	POBLACION	NOMBRE_PROVINCIA	TIPO_RESTRICCION	OBSERVACION
--15010	A CORUÑA	A CORUÑA	Restricción de movilidad	Prohibida la entrada y salida de personas del ámbito territorial delimitado conjuntamente por los municipios de A Coruña, Culleredo, Arteixo, Oleiros y Cambre, salvo causa debidamente justificada.
--15010	A CORUÑA	A CORUÑA	Limitación de reuniones sociales	Prohibidas las agrupaciones de personas al desarrollo de cualquier actividad o evento de carácter familiar o social en la vía pública, espacios de uso público o espacios privados. Se excluye a los constituidos exclusivamente por personas que conviven.


-- with a wrong codigopostal
EXECUTE quecovid '15110'
GO
-- no results
--cp	POBLACION	NOMBRE_PROVINCIA	TIPO_RESTRICCION	OBSERVACION

