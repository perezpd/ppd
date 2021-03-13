/* OWNER PEREZ PONTE DIEGO*/

/*********************************************************************************************/
/********************************     PROCEDURE        ***************************************/
/**************************  GET_CONTAINER_MODELS_WITH_STOCK *********************************/
/************************  WITH CURSOR CS_containers_stock_data  *******************************/
/*********************************************************************************************/

/*
 CURSOR DECLARATION TO REPORT containers WE HAVE in Stock
 --> will show model, stock and dimensions of each
*/

USE [containers_ppd_test_TR];
GO
-- a cursor let us make a loop into data result of a select
CREATE OR ALTER PROC GET_CONTAINER_MODELS_WITH_STOCK
-- NO INPUT PARAMETERS
AS
DECLARE
  @modelId INT, --model id
  @model VARCHAR(50), --model name
  @stock VARCHAR(256),  --model stock qt
  @dimId INT,
  @reportLine VARCHAR (200)
BEGIN 
	DECLARE CS_containers_stock_data CURSOR READ_ONLY FOR
	  SELECT [cantidad],[modelo_cont_ppd_id_modelo]
	  FROM [dbo].[Containers_stock_tmp];
	OPEN CS_containers_stock_data -- like an index but in memory

	FETCH NEXT FROM CS_containers_stock_data INTO @stock,@modelId;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- create the report line
		SELECT @model = [modelo],
				@dimId = [dimension_ppd_id_dimension]
			 FROM [dbo].[modelo_cont_ppd] WHERE id_modelo = @modelId;
		SET @reportLine = @stock + ' existencias de ' + (@model); -- container stock,
		PRINT @reportLine;
		SELECT @reportLine = CONCAT(' - ',[dim_desc],' => ancho:',([ancho]/1000 ),' m, ',
			'longitud:',([longitud]/1000 ),' m, ','altura:',([altura]/1000 ),' m, ',
			'volumen interno:',([altura]/1000 * [longitud]/1000 * [ancho]/1000 ),' metros cúbicos.')
			FROM [Mgmt].[dimension_ppd] WHERE id_dimension = @dimId;
		PRINT @reportLine;
		FETCH NEXT FROM CS_containers_stock_data INTO @stock,@modelId;
	END
	CLOSE CS_containers_stock_data;
	DEALLOCATE CS_containers_stock_data;
END
GO

/* test getting containers in stock */

EXECUTE GET_CONTAINER_MODELS_WITH_STOCK;
GO
/* ---    REPORTE    --- */
--12 existencias de 20 FEET PALLET WIDE
-- - Dimensiones internas PALLET WIDE => ancho:2.426 m, longitud:5.898 m, altura:2.591 m, volumen interno:37.0734 metros cúbicos.
--4 existencias de 40 FEET DRY VAN
-- - Dimensiones internas 40 DRY VAN => ancho:2.352 m, longitud:12.032 m, altura:2.393 m, volumen interno:67.7201 metros cúbicos.
--25 existencias de 40 FEET PALLET WIDE
-- - Dimensiones internas 40 PALLET WIDE => ancho:2.426 m, longitud:12.1 m, altura:2.383 m, volumen interno:69.952 metros cúbicos.
--1 existencias de 40 FEET DRY VAN HIGH CUBE
-- - Dimensiones internas 40 DRY VAN HIGH CUBE => ancho:2.352 m, longitud:12.064 m, altura:2.692 m, volumen interno:76.3842 metros cúbicos.