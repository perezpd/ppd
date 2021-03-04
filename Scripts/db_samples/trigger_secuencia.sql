USE [AdventureWorks2017]
GO


DROP TABLE IF EXISTS Person.Direcciones;
GO

SELECT [AddressLine1], [City],[StateProvinceID], [PostalCode] INTO Person.Direcciones 
	FROM [Person].[Address]
GO 

 DROP TRIGGER IF EXISTS trg_direcciones_insert;
 GO

 CREATE OR ALTER TRIGGER trg_direcciones_insert
 ON Person.Direcciones
 INSTEAD OF INSERT
 AS
 BEGIN
	IF EXISTS (
		SELECT [AddressLine1] from INSERTED
		WHERE RIGHT([AddressLine1],3) = 'Ave'	
		)
		BEGIN
			PRINT 'Modificamos Ave para insertar!';
			SELECT * FROM INSERTED;
			INSERT INTO Person.Direcciones
				([AddressLine1], [City],[StateProvinceID], [PostalCode] )
			 
					SELECT REPLACE([AddressLine1],'Ave','Avenue'),[City],[StateProvinceID], [PostalCode]
					FROM INSERTED;
		END
	ELSE
		BEGIN
			PRINT 'Insertamos sin mas!'
			SELECT * FROM INSERTED;
			INSERT INTO Person.Direcciones
				([AddressLine1], [City],[StateProvinceID], [PostalCode] )
			 
					SELECT [AddressLine1],[City],[StateProvinceID], [PostalCode]
					FROM INSERTED;
		END
 END 

 USE [AdventureWorks2017]
GO
-- INSERT WITH NO MATCH AND NO CHANGES and aHAVING AVE in the address
INSERT INTO [Person].[Direcciones]
           ([AddressLine1]
           ,[City]
           ,[StateProvinceID]
           ,[PostalCode])
     VALUES
           ('Avenida Concordia'
           ,'Coruña'
           ,2
           ,'12345')
GO


--Insertamos sin mas!

--(1 row affected)

--(1 row affected)

--(1 row affected)

--AddressLine1	City	StateProvinceID	PostalCode
--Avenida Concordia	Coruña	2	12345

-- INSERT WITH MATCH AND REPLACE FIELD ADDRESS
INSERT INTO [Person].[Direcciones]
           ([AddressLine1]
           ,[City]
           ,[StateProvinceID]
           ,[PostalCode])
     VALUES
           ('Concordia Ave'
           ,'Coruña'
           ,2
           ,'89945')
GO

--Modificamos Ave para insertar!

--(1 row affected)

--(1 row affected)

--(1 row affected)

--AddressLine1	City	StateProvinceID	PostalCode
--Concordia Ave	Coruña	2				89945

SELECT * FROM [Person].[Direcciones] 
	WHERE [PostalCode]='89945';
GO

--AddressLine1		City	StateProvinceID	PostalCode
--Concordia Avenue	Coruña	2				89945


INSERT INTO [Person].[Direcciones]
           ([AddressLine1]
           ,[City]
           ,[StateProvinceID]
           ,[PostalCode])
     VALUES
           ('Rua caballeros'
           ,'A Coruña'
           ,6
           ,'232323')
GO

--AddressLine1	City	StateProvinceID	PostalCode
--Rua caballeros	A Coruña	6	232323

SELECT * FROM [Person].[Direcciones] 
	WHERE [PostalCode]='232323';
GO

--AddressLine1	City	StateProvinceID	PostalCode
--Rua caballeros	A Coruña	6	232323

/* TWO TABLES WITH FK INTEGRITY*/

USE master;
DROP DATABASE IF EXISTS	Almacen;
GO
CREATE DATABASE Almacen;
GO
USE Almacen;
GO

/* create two tables*/
DROP TABLE IF EXISTS Products;
GO
DROP TABLE IF EXISTS Orders;
GO

CREATE TABLE Products
    (
     id_prod char(8) NOT NULL PRIMARY KEY ,
     nomber VARCHAR (100) NOT NULL ,
     existencia int not null ,
     precio decimal(10,2)  not null,
     precio_venta decimal(10,2)
    );
GO

CREATE TABLE Orders
    (
     id_order INTEGER IDENTITY(1000,1) NOT NULL PRIMARY KEY ,
     id_producto char(8) NOT NULL ,
     cantidad_pedida INTEGER ,
     CONSTRAINT Fk_id_producto FOREIGN KEY (id_producto)
	  REFERENCES Products(id_prod)
    );
GO
sp_help Products
GO
sp_help Orders
GO
USE [Almacen]
GO

INSERT INTO [dbo].[Products]
     VALUES
           ('P001','filtros',5,10,12.5),
           ('P002','ratones inhalambricos',8,12,15.9),
           ('P003','Cable de red',10,15,18.5)
GO


SELECT * FROM [Products];
GO

/*
id_prod		nomber					existencia	precio	precio_venta
P001    	filtros					5			10.00	12.50
P002    	ratones inhalambricos	8			12.00	15.90
P003    	Cable de red			10			15.00	18.50
*/

/* CREATE TRIGGER TO UPDATE Existencais AFTER insert new Order */

 DROP TRIGGER IF EXISTS trg_update_product_stock_after_order;
 GO

 CREATE OR ALTER TRIGGER trg_update_product_stock_after_order
 ON Orders
FOR INSERT
 AS
	 BEGIN
		PRINT 'Insertamos un pedido';
		SELECT * FROM INSERTED;
		UPDATE Products 
		SET existencia = existencia - (SELECT cantidad_pedida FROM INSERTED)
		WHERE id_prod = (SELECT id_producto FROM INSERTED)
	 END 
 GO

 /* Check inserting order for 5 (cable de red)*/
 INSERT INTO Orders VALUES ('P003',5);
 -- Insertamos un pedido
 /*
 id_order	id_producto	cantidad_pedida
1000	P003    	5*/

SELECT * FROM Orders;

--id_order	id_producto	cantidad_pedida
--1000	P003    	5

/* NOW We have 5 items */
SELECT * FROM Products;

--id_prod	nomber	existencia	precio	precio_venta
--P001    	filtros	5	10.00	12.50
--P002    	ratones inhalambricos	8	12.00	15.90
--P003    	Cable de red	5	15.00	18.50

/* MANAGE CONSTRAINTS CHECKS to DELETE tables*/ 

/* When try to delete both tables to restart the script */
--Msg 3726, Level 16, State 1, Line 137
--Could not drop object 'Products' because it is referenced by a FOREIGN KEY constraint.
--Msg 2714, Level 16, State 6, Line 139
--There is already an object named 'Products' in the database.

sp_helpconstraint Products;
GO
--Object Name
--Products

--constraint_type	constraint_name	delete_action	update_action	status_enabled	status_for_replication	constraint_keys
--PRIMARY KEY (clustered)	PK__Products__0DA34873E98F1F79	(n/a)	(n/a)	(n/a)	(n/a)	id_prod

--Table is referenced by foreign key
--Almacen.dbo.Orders: Fk_producto

sp_helpconstraint Orders;
GO
--Object Name
--Orders

--constraint_type			constraint_name					delete_action	update_action	status_enabled	status_for_replication	constraint_keys
--FOREIGN KEY				Fk_producto						No Action		No Action		Enabled			Is_For_Replication		id_producto
-- 	 	 	 	 	 																											REFERENCES Almacen.dbo.Products (id_prod)
--PRIMARY KEY (clustered)	PK__Orders__DD5B8F3FBEE56745	(n/a)			(n/a)			(n/a)			(n/a)					id_order

-- disable check contranitns
ALTER TABLE Orders
	NOCHECK CONSTRAINT Fk_id_producto


-- enable check contranitns
ALTER TABLE Orders
	CHECK CONSTRAINT Fk_id_producto

-- 04/03/2021
DROP TRIGGER IF EXISTS trg_update_product_stock_after_order_wcheck;
 GO

 CREATE OR ALTER TRIGGER trg_update_product_stock_after_order_wcheck
 ON Orders
FOR INSERT
 AS
	 BEGIN
		PRINT 'Insertamos un pedido';
		SELECT * FROM INSERTED;
		DECLARE @stock INTEGER;
		SELECT @stock = existencia FROM Products WHERE id_prod = (SELECT id_producto FROM INSERTED);
		PRINT @Stock;
		IF (@stock <  (SELECT cantidad_pedida FROM INSERTED))
			BEGIN
				PRINT 'No hay existencias para hacer el pedido';
				RAISERROR ('No hay existencias,  solo quedan %d productos!',16,1,@stock);
				/* RETURN IS NOT ENOUGH WE NEED THE ROLLBACK*/
				ROLLBACK TRAN
				RETURN
			END --if
		ELSE
			BEGIN
				PRINT 'Hay existencias para hacer el pedido, lo creamos.';
				UPDATE Products 
				SET existencia = existencia - (SELECT cantidad_pedida FROM INSERTED)
				WHERE id_prod = (SELECT id_producto FROM INSERTED)
			END --else
	 END 
	 SELECT Existencia as 'Products left' FROM Products WHERE id_prod = (SELECT id_producto FROM INSERTED)
 GO

 --insert a single order
 INSERT INTO Orders VALUES ('P003',2);

 /*

 Insertamos un pedido

(1 row affected)
5
Hay existencias para hacer el pedido, lo creamos.

*/

 --insert a single order
 INSERT INTO Orders VALUES ('P003',2);

 -- ORDER
-- id_order	id_producto	cantidad_pedida
-- 1002		P003    	2

--Existencia
--3


 --insert a single order again
 INSERT INTO Orders VALUES ('P003',2);
--id_order	id_producto	cantidad_pedida
--1003		P003    	2

--Products left
--1

-- try last time
 INSERT INTO Orders VALUES ('P003',2);

 /* MESSAGES
 Insertamos un pedido

(1 row affected)
1
No hay existencias para hacer el pedido
Msg 50000, Level 16, State 1, Procedure trg_update_product_stock_after_order_wcheck, Line 15 [Batch Start Line 324]
No hay existencias,  solo quedan 1 productos!

(1 row affected)
*/
--Result
--id_order	id_producto	cantidad_pedida
--1004	P003    	2

-- ROW was inserted
Select * FROM Orders;
--id_order	id_producto	cantidad_pedida
--1000	P003    	5
--1002	P003    	2
--1003	P003    	2
--1004	P003    	2

-- ROW was inserted
Select * FROM Products;
-- P003 has still 1 product
--id_prod	nomber	existencia	precio	precio_venta
--P001    	filtros	5	10.00	12.50
--P002    	ratones inhalambricos	8	12.00	15.90
--P003    	Cable de red	1	15.00	18.50

-- Update the procedure with rollback tran to avoid insert whe no existences
-- try again to make an order
 --insert a single order
 INSERT INTO Orders VALUES ('P003',7);

  /* MESSAGES */
-- Insertamos un pedido

--(1 row affected)
--1
--No hay existencias para hacer el pedido
--Msg 50000, Level 16, State 1, Procedure trg_update_product_stock_after_order_wcheck, Line 15 [Batch Start Line 362]
--No hay existencias,  solo quedan 1 productos!
--Msg 3609, Level 16, State 1, Line 364
--The transaction ended in the trigger. The batch has been aborted.

Select * FROM Orders;
--id_order	id_producto	cantidad_pedida
--1000		P003    	5
--1002		P003    	2
--1003		P003    	2
--1004		P003    	2

-- ROW was inserted
Select * FROM Products;
-- P003 has still 1 product
--id_prod	nomber					existencia	precio	precio_venta
--P001    	filtros					5			10.00	12.50
--P002    	ratones inhalambricos	8			12.00	15.90
--P003    	Cable de red			1			15.00	18.50