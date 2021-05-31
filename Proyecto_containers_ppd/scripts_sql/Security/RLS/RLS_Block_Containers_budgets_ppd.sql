/* OWNER PEREZ PONTE DIEGO*/

/*********************************************************************************************/
/**********************     ROW LEVEL SECURITY BLOCK        **********************************/
/**********  Block actions on ROWS FOR SPECIFIC users depending on the owner *****************/
/**********  TEST USING USERS: VendedorAngel VendedorVeronica EncargadoLuis  *****************/
/*********************************************************************************************/

USE [containers_ppd_test];
GO
-- we starts with the table form FILTER RLS example with 5 rows
SELECT *  FROM [Mgmt].[budgets_rls_ppd]
--id_presupuesto	fecha	notas	cliente_ppd_id_cliente	OfferedBy
--id_presupuesto	fecha	notas	cliente_ppd_id_cliente	OfferedBy
--1001	2021-05-31	Contenerdor Seminuevo con abolladura en lateral exterior izquierdo por impacto. Venta por valor de 5600 Euros	1002	VendedorAngel
--1002	2021-05-31	Contenedor 20 pies nº serie 3241314 por 4560€	1001	VendedorAngel
--1003	2021-05-31	Contenerdor Seminuevo con abolladura. Venta rebajada por valor de 5400 Euros	1002	VendedorVeronica
--1004	2021-05-31	Contenedor 40 pies nº serie 3242513 por 3860€	1001	VendedorVeronica
--1005	2021-05-31	Contenedor 20 pies nº serie 11234 por 3860€	1003	VendedorAngel

-- we have customers 1001 1002 and 1003 on table [Mgmt].[cliente_ppd]
SELECT * FROM [Mgmt].[cliente_ppd]

--id_cliente	nombre	direccion_ppd_id_direccion	cif	iban
--1001			Estructuras NOROESTE	1005	1111111A	ES36 2222 5555 2222 1111 8888
--1002			Prefabricados PFR	1004	2222222B	ES31 3333 5555 4563 1231 9674
--1003			Estructuras NOROESTE	1003	3333333C	ES32 4444 1234 4432 6784 2452


/******   BLOCK AFTER PREDICATE   ********/
-- DEFINITION OF PREDICATE for the function needs to determine:

--EncargadoLuis user: can insert all kind of budgets
--VendedorAngel: cannot insert if it is not offeredby by him budget
--VendedorVeronica: cannot insert if it is not offeredby by her budget 



-- THE FUNCTION CONTROLS WHO are performing action
-- WE will use same function as in the FILTER example to know the user
--CREATE FUNCTION Mgmt.OfferedByUserSP_PPD(@OfferedBy AS sysname) 
--    RETURNS TABLE 
--WITH SCHEMABINDING 
--AS 
--    RETURN (SELECT 1 AS OfferedByUserSP_PPD 
--            WHERE @OfferedBy = USER_NAME() 
--               OR (USER_NAME() IN ('EncargadoLuis','dbo')));
--GO 

/******    SECURITY POLICY BLOCK AFTER INSERT DEFINITION   ********/
DROP SECURITY POLICY IF EXISTS [Mgmt].[OfferedBy_On_Budgets_SP]
GO
CREATE SECURITY POLICY Mgmt.OfferedBy_On_Budgets_SP 
	ADD BLOCK PREDICATE Mgmt.OfferedByUserSP_PPD(OfferedBy) 
	ON [Mgmt].[budgets_rls_ppd] 
	AFTER INSERT
WITH (STATE = ON); 


--LETS INSERT DATA AS USER VendedorAngel

EXECUTE as user='VendedorAngel'
GO	
Select USer	
USE [containers_ppd_test]
GO

-- TRY INSERT DATA THAT NOT FOLLOW THE PREDICATE
INSERT INTO [Mgmt].[budgets_rls_ppd]
           ([fecha],[notas],[cliente_ppd_id_cliente], [OfferedBy])
     VALUES
       (GETDATE(),'Contenerdor Seminuevo con abolladura en lateral num serie 3241314. Venta por valor de 5600 Euros',1002,'VendedorVeronica')
GO
		
--Msg 33504, Level 16, State 1, Line 78
--The attempted operation failed because the target object 'containers_ppd_test.Mgmt.budgets_rls_ppd' has a block predicate that conflicts with this operation. If the operation is performed on a view, the block predicate might be enforced on the underlying table. Modify the operation to target only the rows that are allowed by the block predicate.
--The statement has been terminated.

-- Select and Angel can see all rows because we do´t have now the filter predicate security policy
SELECT * FROM [Mgmt].[budgets_rls_ppd]
--id_presupuesto	fecha	notas	cliente_ppd_id_cliente	OfferedBy
--1001	2021-05-31	Contenerdor Seminuevo con abolladura en lateral exterior izquierdo por impacto. Venta por valor de 5600 Euros	1002	VendedorAngel
--1002	2021-05-31	Contenedor 20 pies nº serie 3241314 por 4560€	1001	VendedorAngel
--1003	2021-05-31	Contenerdor Seminuevo con abolladura. Venta rebajada por valor de 5400 Euros	1002	VendedorVeronica
--1004	2021-05-31	Contenedor 40 pies nº serie 3242513 por 3860€	1001	VendedorVeronica
--1005	2021-05-31	Contenedor 20 pies nº serie 11234 por 3860€	1003	VendedorAngel


-- TRY INSERT DATA THAT FOR SURE FOLLOW THE PREDICATE
INSERT INTO [Mgmt].[budgets_rls_ppd]
           ([fecha],[notas],[cliente_ppd_id_cliente], [OfferedBy])
     VALUES
       (GETDATE(),'Contenerdor Seminuevo con abolladura en lateral num serie 3241314. Venta por valor de 5600 Euros',1002,'VendedorAngel')
GO

--(1 row affected)
SELECT id_presupuesto, [OfferedBy] FROM [Mgmt].[budgets_rls_ppd]
-- new row is there
--id_presupuesto		OfferedBy
--1001				VendedorAngel
--1002				VendedorAngel
--1003				VendedorVeronica
--1004				VendedorVeronica
--1005				VendedorAngel
--1007				VendedorAngel
REVERT


/******    SECURITY POLICY BLOCK AFTER UPDATE DEFINITION   ********/

ALTER SECURITY POLICY Mgmt.OfferedBy_On_Budgets_SP 
	ADD BLOCK PREDICATE Mgmt.OfferedByUserSP_PPD(OfferedBy) 
	ON [Mgmt].[budgets_rls_ppd] 
	AFTER UPDATE;
GO

--LETS UPDATE DATA AS USER VendedorVeronica

EXECUTE as user='VendedorVeronica'
GO	
Select USer	

-- UPDATE: the new data to set doest not match the predicate, offereby is  VendedorAngel so block the insertion

UPDATE [Mgmt].[budgets_rls_ppd] SET OfferedBy='VendedorAngel' WHERE id_presupuesto=1005;
GO

--Msg 33504, Level 16, State 1, Line 134
--The attempted operation failed because the target object 'containers_ppd_test.Mgmt.budgets_rls_ppd' has a block predicate that conflicts with this operation. If the operation is performed on a view, the block predicate might be enforced on the underlying table. Modify the operation to target only the rows that are allowed by the block predicate.
--The statement has been terminated.

UPDATE [Mgmt].[budgets_rls_ppd] SET OfferedBy='VendedorVeronica' WHERE id_presupuesto=1005;
GO
--(1 row affected)

REVERT

-- CONCLUSION: AFTER UPDATE/INSERT BLOCK the action when the new dat does not fits the predicate function



/*************************************************************************************************/


/******   BLOCK BEFORE PREDICATE   ********/
-- DEFINITION OF PREDICATE for the function

DROP SECURITY POLICY IF EXISTS Mgmt.OfferedBy_On_Budgets_SP
CREATE SECURITY POLICY Mgmt.OfferedBy_On_Budgets_SP 
	ADD BLOCK PREDICATE Mgmt.OfferedByUserSP_PPD(OfferedBy) 
	ON [Mgmt].[budgets_rls_ppd] 
	BEFORE DELETE;
GO


SELECT id_presupuesto, [OfferedBy] FROM [Mgmt].[budgets_rls_ppd]
-- We have 6 rows
--id_presupuesto		OfferedBy
--1001				VendedorAngel
--1002				VendedorAngel
--1003				VendedorVeronica
--1004				VendedorVeronica
--1005				VendedorAngel
--1007				VendedorAngel


EXECUTE as  USER='VendedorVeronica'; 
DELETE FROM [Mgmt].[budgets_rls_ppd] WHERE id_presupuesto=1005;
GO

--Msg 33504, Level 16, State 1, Line 168
--The attempted operation failed because the target object 'containers_ppd_test.Mgmt.budgets_rls_ppd' has a block predicate that conflicts with this operation. If the operation is performed on a view, the block predicate might be enforced on the underlying table. Modify the operation to target only the rows that are allowed by the block predicate.
--The statement has been terminated.



--CONCLUSION: WITH Before predicate we prevent DELETE statements violating the predicate rule 

 -- CLEAN DB BEFORE CLOSE
DROP SECURITY POLICY IF EXISTS Mgmt.OfferedBy_On_Budgets_SP
DROP FUNCTION IF EXISTS Mgmt.OfferedByUserSP_PPD
GO