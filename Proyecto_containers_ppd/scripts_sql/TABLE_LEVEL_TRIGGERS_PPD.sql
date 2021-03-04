USE [containers_ppd_test]
GO

/* Create a temporal table from [Mgmt].[estado_cont_ppd]
to test some triggers acting in containers status table */

DROP TABLE IF EXISTS StatusTMP;
GO

SELECT * INTO StatusTMP
FROM [Mgmt].[estado_cont_ppd]
GO

SELECT * FROM StatusTMP
GO

/* trigger to update status description */
IF OBJECT_ID ('trg_cont_update_status', 'TR') IS NOT NULL
  DROP TRIGGER trg_cont_update_status
GO
CREATE OR ALTER TRIGGER trg_cont_update_status
ON StatusTMP -- TABLE LEVEL
FOR UPDATE -- sentence to control is update
AS
    IF UPDATE (desc_estado)
		BEGIN
			RAISERROR ('No puedes cambiar el estado del contenedor', 16,1) 
			ROLLBACK TRAN
		END
	ELSE
		PRINT 'Operacion correcta cambio de grupo'
GO

SELECT * FROM StatusTMP;
GO
/*
id_estado	peso_neto	desc_estado
1			3456	Seminuevo con rayaduras exteriores
2			6500	Un poco de corrosión en los laterales
3			10000	Imperfecciones en la superficie de asiento
4			6800	Seminuevo con rayaduras exteriores y falta lona cobertura
5			4850	Seminuevo con rayaduras exteriores, puertas sellado perfecto
6			8500	Seminuevo con rayaduras en plataforma
7			3485	Deterioro en puertas y platafroma
8			9860	Seminuevo con una puerta bloqueada
9			12240	Seminuevo con pintadas en el exterior
10			8675	pintadas en el exterior, puerta bloqueda y perforaciones en lateral
*/

UPDATE StatusTMP 
SET desc_estado = 'Seminuevo con rayaduras exteriores BIEN MARCADAS'
WHERE id_estado = '1';
GO

--Msg 50000, Level 16, State 1, Procedure trg_cont_update_status, Line 7 [Batch Start Line 47]
--No puedes cambiar el estado del contenedor
--Msg 3609, Level 16, State 1, Line 48
--The transaction ended in the trigger. The batch has been aborted.

/* AVOID DELETE ANY ROW in */

IF OBJECT_ID ('trg_multiple_delete_status_container', 'TR') IS NOT NULL
  DROP TRIGGER trg_multiple_delete_status_container
GO


CREATE OR ALTER TRIGGER trg_multiple_delete_status_container
ON StatusTMP -- TABLE LEVEL
FOR DELETE -- sentence to control
AS
	-- PRINT @@ROWCOUNT --
	DECLARE @rowsAffected INT;
	SET @rowsAffected = @@ROWCOUNT;
    IF (@rowsAffected >1)
		BEGIN
			PRINT 'estas intentando borrar '+ CAST(@rowsAffected AS NVARCHAR(100)) + ' Registros de Estado de contenedores!'
			RAISERROR ('No se puede borrar multiples registros, estás borrando %d !!!', 16,1,@rowsAffected) 
			ROLLBACK TRAN
		END
	ELSE
		PRINT CAST(@rowsAffected AS NVARCHAR(100)) + 'Un registro si se puede borrar'
GO
-- Check how many results we have
SELECT COUNT(*) as 'RESULTS' FROM StatusTMP;
GO
--RESULTS
--10

DELETE FROM StatusTMP
GO

 -- MULTIPLE DELETION  IS NOT ALLOWED
/*
estas intentando borrar 10 Registros de Estado de contenedores!
Msg 50000, Level 16, State 1, Procedure trg_multiple_delete_status_container, Line 13 [Batch Start Line 87]
No se puede borrar multiples registros, estás borrando 10 !!!
Msg 3609, Level 16, State 1, Line 89
The transaction ended in the trigger. The batch has been aborted.
*/

DELETE FROM StatusTMP WHERE id_estado = 1
GO
-- DELETE A SINGLE STATUS IS PERMITTED
--1Un registro si se puede borrar

--(1 row affected)

/* AVOID ANY DELETION IN CONTAINERS DIMENSIONS with INSTEAD OF*/
/* Container dimensions has to be secured and avoid modification so we 
cancel the possibility of deleting items  */

/* Create a temporal table from [Mgmt].[dimension_ppd]
to test the triggers acting in containers dimension table */

DROP TABLE IF EXISTS DimensionsTMP;
GO

SELECT * INTO DimensionsTMP
FROM [Mgmt].dimension_ppd
GO

SELECT * FROM DimensionsTMP
GO
/*
id_dimension	dim_desc	ancho	longitud	altura	volumen
1000	Dimensiones internas DRY VAN	2352	5898	2393	33.2
1001	Dimensiones externas DRY VAN	2438	6058	2591	NULL
1002	Dimensiones puertas DRY VAN	2340	2280	NULL	NULL
1003	Dimensiones internas OPEN TOP	2352	5940	2360	33.2
1004	Dimensiones externas OPEN TOP	2484	6058	2591	NULL
1005	Dimensiones puertas OPEN TOP	2340	2280	NULL	NULL
1006	Dimensiones internas PALLET WIDE	2426	5898	2591	38.6
1007	Dimensiones externas PALLET WIDE	2484	6058	2591	NULL
1008	Dimensiones puertas PALLET WIDE	2374	2585	NULL	NULL
1009	Dimensiones internas PALLET WIDE HIGH CUBE	2426	5898	2712	36.6
1010	Dimensiones externas PALLET WIDE HIGH CUBE	2484	6058	2896	NULL
1011	Dimensiones puertas PALLET WIDE HIGH CUBE	2374	2585	NULL	NULL
1012	Dimensiones internas 40 DRY VAN	2352	12032	2393	67.7
1013	Dimensiones externas 40 DRY VAN	2438	12192	2591	NULL
1014	Dimensiones puertas 40 DRY VAN	2340	2280	NULL	NULL
1015	Dimensiones internas 40 DRY VAN HIGH CUBE	2352	12064	2692	57.41
1016	Dimensiones externas 40 DRY VAN HIGH CUBE	2438	12192	2896	NULL
1017	Dimensiones puertas 40 DRY VAN HIGH CUBE	2340	2280	NULL	NULL
1018	Dimensiones internas 40 PALLET WIDE	2426	12100	2383	79.1
1019	Dimensiones externas 40 PALLET WIDE	2484	12192	2591	NULL
1020	Dimensiones puertas 40 PALLET WIDE	2360	2280	NULL	NULL
1021	Dimensiones internas 40 PALLET WIDE HIGH CUBE	2352	12100	2694	79.1
1022	Dimensiones externas 40 PALLET WIDE HIGH CUBE	2438	12192	2896	NULL
1023	Dimensiones puertas 40 PALLET WIDE HIGH CUBE	2340	2280	NULL	NULL
*/

IF OBJECT_ID ('trg_avoid_delete_dimensions_instead', 'TR') IS NOT NULL
  DROP TRIGGER trg_avoid_delete_dimensions_instead
GO
CREATE OR ALTER TRIGGER trg_avoid_delete_dimensions_instead
ON DimensionsTMP -- TABLE LEVEL
INSTEAD OF DELETE -- sentence to control
AS
	DECLARE @rowsAffected INT;
	SET @rowsAffected = @@ROWCOUNT;
    IF @rowsAffected = 0
		RETURN

	BEGIN
		PRINT 'Se está intentando actuar sobre la tabla dimensiones y no se puede borrar registros, solo se actualizan'
		RAISERROR ('No se pueden borrar registros !!!', 16,1) 
		IF @@TRANCOUNT > 0
		BEGIN
			PRINT 'Se restauran Transacciones'
			ROLLBACK TRANSACTION
		END;
	END
GO

-- Try to DELETE all table content
DELETE DimensionsTMP
GO

/* DELETION IS NOT POSSIBLE IN TABLE DIMENSIONS */ 
--Se está intentando actuar sobre la tabla dimensiones y no se puede borrar registros, solo se actualizan
--Msg 50000, Level 16, State 1, Procedure trg_avoid_delete_dimensions_instead, Line 12 [Batch Start Line 173]
--No se pueden borrar registros !!!
--Se restauran Transacciones
--Msg 3609, Level 16, State 1, Line 175
--The transaction ended in the trigger. The batch has been aborted.

-- try to delete a single dimension

DELETE FROM DimensionsTMP
      WHERE id_dimension = '1000'
GO
/* NOT POSSIBLE */
--Se está intentando actuar sobre la tabla dimensiones y no se puede borrar registros, solo se actualizan
--Msg 50000, Level 16, State 1, Procedure trg_avoid_delete_dimensions_instead, Line 12 [Batch Start Line 186]
--No se pueden borrar registros !!!
--Se restauran Transacciones
--Msg 3609, Level 16, State 1, Line 187
--The transaction ended in the trigger. The batch has been aborted.