/* OWNER PEREZ PONTE DIEGO*/

/*********************************************************************************************/
/**********************        ROW LEVEL SECURITY        *************************************/
/*************  Hide data ROWS FOR SPECIFIC users depending on the owner *********************/
/**********  TEST USING USERS: VendedorAngel VendedorVeronica EncargadoLuis  *****************/
/*********************************************************************************************/

USE [containers_ppd_test];
GO
DROP TABLE IF EXISTS [Mgmt].[budgets_rls_ppd];
GO

SELECT * INTO [Mgmt].[budgets_rls_ppd]
	FROM [Mgmt].[presupuesto_ppd]
GO
SELECT count(*) as presupuestos FROM [Mgmt].[budgets_rls_ppd]
--presupuestos
--0

-- Add offeredby field as sysname to set up the person who offer the budget on insert [budgets_rls_ppd]
ALTER TABLE [Mgmt].[budgets_rls_ppd] 
	ADD OfferedBy sysname not null;
GO

SELECT *  FROM [Mgmt].[budgets_rls_ppd]
--id_presupuesto	fecha	notas	cliente_ppd_id_cliente	OfferedBy

--GRANT all DML
GRANT SELECT, INSERT,DELETE, UPDATE ON [Mgmt].[budgets_rls_ppd] TO VendedorAngel, VendedorVeronica, EncargadoLuis


-- we have customer 1001 1002 and 1003 on table [Mgmt].[cliente_ppd]
SELECT * FROM [Mgmt].[cliente_ppd]

--id_cliente	nombre	direccion_ppd_id_direccion	cif	iban
--1001			Estructuras NOROESTE	1005	1111111A	ES36 2222 5555 2222 1111 8888
--1002			Prefabricados PFR	1004	2222222B	ES31 3333 5555 4563 1231 9674
--1003			Estructuras NOROESTE	1003	3333333C	ES32 4444 1234 4432 6784 2452


/******    PREDICATE  FUNCTION   ********/
-- DEFINITION OF PREDICATE for the function needs to determine:

--EncargadoLuis user: can see all presupuestos
--VendedorAngel user sees only his rows
--VendedorVeronica sees her rows


-- CONTROLS WHO are performing action
DROP SECURITY POLICY IF EXISTS  [Mgmt].Personal_Role_Accessing_Offer_Budgets_ppd;
go 
CREATE FUNCTION Mgmt.OfferedByUserSP_PPD(@OfferedBy AS sysname) 
    RETURNS TABLE 
WITH SCHEMABINDING 
AS 
    RETURN (SELECT 1 AS OfferedByUserSP_PPD 
            WHERE @OfferedBy = USER_NAME() 
               OR (USER_NAME() IN ('EncargadoLuis','dbo')));
GO 

/******    SECURITY POLICY FILTER DEFINITION   ********/
CREATE SECURITY POLICY Mgmt.OfferedBy_On_Budgets_SP 
ADD FILTER PREDICATE Mgmt.OfferedByUserSP_PPD(OfferedBy) ON [Mgmt].[budgets_rls_ppd] 
WITH (STATE = ON); 


--LETS INSERT DATA AS EACH USER VENDEDOR

EXECUTE as user='VendedorAngel'
GO	
Select USer	
USE [containers_ppd_test]
GO


INSERT INTO [Mgmt].[budgets_rls_ppd]
           ([fecha],[notas],[cliente_ppd_id_cliente], [OfferedBy])
     VALUES
       (GETDATE(),'Contenerdor Seminuevo con abolladura en lateral exterior izquierdo por impacto. Venta por valor de 5600 Euros',1002,(Select USer)),
		   (GETDATE(),'Contenedor 20 pies nº serie 3241314 por 4560€',1001,(Select USer))
		   
--(2 rows affected)

-- Select and Angel can see all his rows
SELECT * FROM [Mgmt].[budgets_rls_ppd]
--id_presupuesto	fecha	notas	cliente_ppd_id_cliente	OfferedBy
--1001	2021-05-31	Contenerdor Seminuevo con abolladura en lateral exterior izquierdo por impacto. Venta por valor de 5600 Euros	1002	VendedorAngel
--1002	2021-05-31	Contenedor 20 pies nº serie 3241314 por 4560€	1001	VendedorAngel
REVERT


EXECUTE as user='VendedorVeronica'
GO	
Select USer	

-- Select and Veronica can see any rows yet, others are form Angel
SELECT * FROM [Mgmt].[budgets_rls_ppd]
--id_presupuesto	fecha	notas	cliente_ppd_id_cliente	OfferedBy
USE [containers_ppd_test]
GO


INSERT INTO [Mgmt].[budgets_rls_ppd]
           ([fecha],[notas],[cliente_ppd_id_cliente], [OfferedBy])
     VALUES
       (GETDATE(),'Contenerdor Seminuevo con abolladura. Venta rebajada por valor de 5400 Euros',1002,(Select USer)),
		   (GETDATE(),'Contenedor 40 pies nº serie 3242513 por 3860€',1001,(Select USer))
		   
--(2 rows affected)

-- Select and Veronica can see all his rows (notice about ID increment
SELECT * FROM [Mgmt].[budgets_rls_ppd]
--id_presupuesto	fecha	notas	cliente_ppd_id_cliente	OfferedBy
--1003	2021-05-31	Contenerdor Seminuevo con abolladura. Venta rebajada por valor de 5400 Euros	1002	VendedorVeronica
--1004	2021-05-31	Contenedor 40 pies nº serie 3242513 por 3860€	1001	VendedorVeronica
REVERT

-- check that dbo or EncargadoLuis can see all data in [Mgmt].[budgets_rls_ppd]
-- Both of them see 4 budgets
-- dbo
SELECT * FROM [Mgmt].[budgets_rls_ppd]
--id_presupuesto	fecha	notas	cliente_ppd_id_cliente	OfferedBy
--1001	2021-05-31	Contenerdor Seminuevo con abolladura en lateral exterior izquierdo por impacto. Venta por valor de 5600 Euros	1002	VendedorAngel
--1002	2021-05-31	Contenedor 20 pies nº serie 3241314 por 4560€	1001	VendedorAngel
--1003	2021-05-31	Contenerdor Seminuevo con abolladura. Venta rebajada por valor de 5400 Euros	1002	VendedorVeronica
--1004	2021-05-31	Contenedor 40 pies nº serie 3242513 por 3860€	1001	VendedorVeronica

-- EncargadoLuis
EXECUTE ('SELECT * FROM [Mgmt].[budgets_rls_ppd]') as user='EncargadoLuis'
--id_presupuesto	fecha	notas	cliente_ppd_id_cliente	OfferedBy
--1001	2021-05-31	Contenerdor Seminuevo con abolladura en lateral exterior izquierdo por impacto. Venta por valor de 5600 Euros	1002	VendedorAngel
--1002	2021-05-31	Contenedor 20 pies nº serie 3241314 por 4560€	1001	VendedorAngel
--1003	2021-05-31	Contenerdor Seminuevo con abolladura. Venta rebajada por valor de 5400 Euros	1002	VendedorVeronica
--1004	2021-05-31	Contenedor 40 pies nº serie 3242513 por 3860€	1001	VendedorVeronica


/*****   END FILTER PREDICATE FOR SELECT ***/


/******    SECURITY POLICY BLOCK DEFINITION   ********/
-- No we avoid let insert VendedorVeronica
CREATE SECURITY POLICY Mgmt.OfferedBy_On_Budgets_SP 
ADD FILTER PREDICATE Mgmt.OfferedByUserSP_PPD(OfferedBy) ON [Mgmt].[budgets_rls_ppd] 
WITH (STATE = ON, SCHEMABINDING = ON); 


-- TRY veronica insert a record for Angel
EXECUTE as user='VendedorVeronica'
GO	

-- Select and Veronica can see only her rows
SELECT * FROM [Mgmt].[budgets_rls_ppd]
--id_presupuesto	fecha	notas	cliente_ppd_id_cliente	OfferedBy
--1003	2021-05-31	Contenerdor Seminuevo con abolladura. Venta rebajada por valor de 5400 Euros	1002	VendedorVeronica
--1004	2021-05-31	Contenedor 40 pies nº serie 3242513 por 3860€	1001	VendedorVeronica
USE [containers_ppd_test]
GO


INSERT INTO [Mgmt].[budgets_rls_ppd]
           ([fecha],[notas],[cliente_ppd_id_cliente], [OfferedBy])
     VALUES
		   (GETDATE(),'Contenedor 20 pies nº serie 11234 por 3860€',1003,'VendedorAngel')

		   --(1 row affected)
SELECT * FROM [Mgmt].[budgets_rls_ppd]
--Veronica still can see only her rows
--id_presupuesto	fecha	notas	cliente_ppd_id_cliente	OfferedBy
--1003	2021-05-31	Contenerdor Seminuevo con abolladura. Venta rebajada por valor de 5400 Euros	1002	VendedorVeronica
--1004	2021-05-31	Contenedor 40 pies nº serie 3242513 por 3860€	1001	VendedorVeronica

REVERT
SELECT count(*) FROM [Mgmt].[budgets_rls_ppd]

-- 5 rows
--id_presupuesto	fecha	notas	cliente_ppd_id_cliente	OfferedBy
--1001	2021-05-31	Contenerdor Seminuevo con abolladura en lateral exterior izquierdo por impacto. Venta por valor de 5600 Euros	1002	VendedorAngel
--1002	2021-05-31	Contenedor 20 pies nº serie 3241314 por 4560€	1001	VendedorAngel
--1003	2021-05-31	Contenerdor Seminuevo con abolladura. Venta rebajada por valor de 5400 Euros	1002	VendedorVeronica
--1004	2021-05-31	Contenedor 40 pies nº serie 3242513 por 3860€	1001	VendedorVeronica
--1005	2021-05-31	Contenedor 20 pies nº serie 11234 por 3860€	1003	VendedorAngel


-- TRY veronica DELETE a record Offered By Angel
EXECUTE ('DELETE FROM [Mgmt].[budgets_rls_ppd] WHERE id_presupuesto=1005') as user='VendedorVeronica';
GO

--(0 rows affected)

-- TRY veronica UPDATE a record Offered By Angel and assign to her
-- TRY veronica insert a record for Angel
EXECUTE as user='VendedorVeronica'
GO	
UPDATE [Mgmt].[budgets_rls_ppd] SET OfferedBy='VendedorVeronica' WHERE id_presupuesto=1005;
GO

--(0 rows affected)
REVERT

-- As ENcargadoLuis chek alla data remains untouched
 EXECUTE ('SELECT * FROM [Mgmt].[budgets_rls_ppd]') as user='EncargadoLuis';
-- id_presupuesto	fecha	notas	cliente_ppd_id_cliente	OfferedBy
--1001	2021-05-31	Contenerdor Seminuevo con abolladura en lateral exterior izquierdo por impacto. Venta por valor de 5600 Euros	1002	VendedorAngel
--1002	2021-05-31	Contenedor 20 pies nº serie 3241314 por 4560€	1001	VendedorAngel
--1003	2021-05-31	Contenerdor Seminuevo con abolladura. Venta rebajada por valor de 5400 Euros	1002	VendedorVeronica
--1004	2021-05-31	Contenedor 40 pies nº serie 3242513 por 3860€	1001	VendedorVeronica
--1005	2021-05-31	Contenedor 20 pies nº serie 11234 por 3860€	1003	VendedorAngel


-- Conclusion, users can insert for others, but cannot select or modify rows who break the row security policy 