-- https://docs.microsoft.com/en-us/sql/t-sql/statements/create-sequence-transact-sql?view=sql-server-ver15

-- https://www.sqlshack.com/sequence-objects-in-sql-server/


-- Ejemplo diferente del desarrolado
-- http://www.sqlservertutorial.net/sql-server-basics/sql-server-sequence/

-- https://www.sqlshack.com/sequence-objects-in-sql-server/



-- https://www.sqlshack.com/difference-between-identity-sequence-in-sql-server/

--The syntax for a Sequence object is as follows:

CREATE SEQUENCE [schema_name . ] sequence_name  
    [ AS [ built_in_integer_type | user-defined_integer_type ] ]  
    [ START WITH <constant> ]  
    [ INCREMENT BY <constant> ]  
    [ { MINVALUE [ <constant> ] } | { NO MINVALUE } ]  
    [ { MAXVALUE [ <constant> ] } | { NO MAXVALUE } ]  
    [ CYCLE | { NO CYCLE } ]  
    [ { CACHE [ <constant> ] } | { NO CACHE } ]  
    [ ; ]  
GO

-------------------------

-- EJEMPLO

USE tempdb
go
DROP SEQUENCE IF EXISTS item_counter
GO
CREATE SEQUENCE item_counter
    AS INT
    START WITH 10
    INCREMENT BY 10;
GO

SELECT NEXT VALUE FOR item_counter;
GO
SELECT NEXT VALUE FOR item_counter;
GO
SELECT NEXT VALUE FOR item_counter;
go

-- Using a sequence object in a single table example


CREATE SCHEMA procurement;
GO
CREATE TABLE procurement.purchase_orders(
    order_id INT PRIMARY KEY,
    vendor_id int NOT NULL,
    order_date date NOT NULL
);
GO

DROP SEQUENCE IF EXISTS procurement.order_number
GO
CREATE SEQUENCE procurement.order_number 
AS INT
START WITH 1
INCREMENT BY 1;
GO

INSERT INTO procurement.purchase_orders
    (order_id,
    vendor_id,
    order_date)
VALUES
    (NEXT VALUE FOR procurement.order_number,1,'2019-04-30');


INSERT INTO procurement.purchase_orders
    (order_id,
    vendor_id,
    order_date)
VALUES
    (NEXT VALUE FOR procurement.order_number,2,'2019-05-01');


INSERT INTO procurement.purchase_orders
    (order_id,
    vendor_id,
    order_date)
VALUES
    (NEXT VALUE FOR procurement.order_number,3,'2019-05-02');
GO

SELECT 
    order_id, 
    vendor_id, 
    order_date
FROM 
    procurement.purchase_orders;
GO

-- Using a sequence object in multiple tables example

CREATE SEQUENCE procurement.receipt_no
START WITH 1
INCREMENT BY 1;
GO

CREATE TABLE procurement.goods_receipts
(
    receipt_id   INT	PRIMARY KEY 
        DEFAULT (NEXT VALUE FOR procurement.receipt_no), 
    order_id     INT NOT NULL, 
    full_receipt BIT NOT NULL,
    receipt_date DATE NOT NULL,
    note NVARCHAR(100),
);
GO

CREATE TABLE procurement.invoice_receipts
(
    receipt_id   INT PRIMARY KEY
        DEFAULT (NEXT VALUE FOR procurement.receipt_no), 
    order_id     INT NOT NULL, 
    is_late      BIT NOT NULL,
    receipt_date DATE NOT NULL,
    note NVARCHAR(100)
);
GO


INSERT INTO procurement.goods_receipts(
    order_id, 
    full_receipt,
    receipt_date,
    note
)
VALUES(
    1,
    1,
    '2019-05-12',
    'Goods receipt completed at warehouse'
);
INSERT INTO procurement.goods_receipts(
    order_id, 
    full_receipt,
    receipt_date,
    note
)
VALUES(
    1,
    0,
    '2019-05-12',
    'Goods receipt has not completed at warehouse'
);

INSERT INTO procurement.invoice_receipts(
    order_id, 
    is_late,
    receipt_date,
    note
)
VALUES(
    1,
    0,
    '2019-05-13',
    'Invoice duly received'
);
INSERT INTO procurement.invoice_receipts(
    order_id, 
    is_late,
    receipt_date,
    note
)
VALUES(
    2,
    0,
    '2019-05-15',
    'Invoice duly received'
);
GO

SELECT * FROM procurement.goods_receipts;
GO

--receipt_id	order_id	full_receipt	receipt_date	note
--1	1	1	2019-05-12	Goods receipt completed at warehouse
--2	1	0	2019-05-12	Goods receipt has not completed at warehouse


SELECT * FROM procurement.invoice_receipts;
GO

--receipt_id	order_id	is_late	receipt_date	note
--3	1	0	2019-05-13	Invoice duly received
--4	2	0	2019-05-15	Invoice duly received


SELECT 
    * 
FROM 
    sys.sequences;
GO

--name	object_id	principal_id	schema_id	parent_object_id	type	type_desc	create_date	modify_date	is_ms_shipped	is_published	is_schema_published	start_value	increment	minimum_value	maximum_value	is_cycling	is_cached	cache_size	system_type_id	user_type_id	precision	scale	current_value	is_exhausted	last_used_value
--item_counter	1141579105	NULL	1	0	SO	SEQUENCE_OBJECT	2021-05-01 12:55:06.037	2021-05-01 12:55:06.037	0	0	0	10	10	-2147483648	2147483647	0	1	NULL	56	56	10	0	30	0	30
--order_number	1189579276	NULL	6	0	SO	SEQUENCE_OBJECT	2021-05-01 12:58:49.883	2021-05-01 12:58:49.883	0	0	0	1	1	-2147483648	2147483647	0	1	NULL	56	56	10	0	3	0	3
--receipt_no	1205579333	NULL	6	0	SO	SEQUENCE_OBJECT	2021-05-01 13:02:52.780	2021-05-01 13:02:52.780	0	0	0	1	1	-9223372036854775808	9223372036854775807	0	1	NULL	127	127	19	0	4	0	4

------------------------------
-- OTRO EJEMPLO

DROP DATABASE IF EXISTS Showroom 
GO
CREATE Database ShowRoom;
GO
USE ShowRoom;
GO
DROP TABLE IF EXISTS Cars1
GO
-- HINT : id INT PRIMARY KEY IDENTITY(1,1),
CREATE TABLE Cars1
(
    id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50) NOT NULL,
    company VARCHAR(50) NOT NULL,
    power INT NOT NULL
 )
GO  
DROP TABLE IF EXISTS Cars2
GO
CREATE TABLE Cars2
(
    id INT,
    name VARCHAR(50) NOT NULL,
    company VARCHAR(50) NOT NULL,
    power INT NOT NULL
 )
 GO
 DROP TABLE IF EXISTS Cars3
GO
 CREATE TABLE Cars3
(
    id INT,
    name VARCHAR(50) NOT NULL,
    company VARCHAR(50) NOT NULL,
    power INT NOT NULL
 );
 
 Go
 DROP SEQUENCE IF EXISTS [SequenceCounter]
 GO
 CREATE SEQUENCE [dbo].[SequenceCounter]
 AS INT
	 START WITH 1
	 INCREMENT BY 1
 GO

INSERT INTO Cars2 
	VALUES (NEXT VALUE FOR [dbo].[SequenceCounter], '208', 'Peugeot', 5400)
INSERT INTO Cars2 
	VALUES (NEXT VALUE FOR [dbo].[SequenceCounter], 'C500', 'BMW', 8000)
INSERT INTO Cars2 
	VALUES (NEXT VALUE FOR [dbo].[SequenceCounter], 'C500', 'Peugeot', 5400)
GO

select * from Cars2
go

--id	name	company	power
--1	208	Peugeot	5400
--2	C500	BMW	8000
--3	C500	Peugeot	5400


INSERT INTO Cars3 VALUES (NEXT VALUE FOR [dbo].[SequenceCounter], 'C500', 'Mercedez', 5000)
INSERT INTO Cars3 VALUES (NEXT VALUE FOR [dbo].[SequenceCounter], 'Prius', 'Toyota', 3200)
INSERT INTO Cars3 VALUES (NEXT VALUE FOR [dbo].[SequenceCounter], 'Civic', 'Honda', 1800)
GO

select * from Cars3
go

--id	name	company	power
--4	C500	Mercedez	5000
--5	Prius	Toyota	3200
--6	Civic	Honda	1800

INSERT INTO Cars1 VALUES ('Corrolla', 'Toyota', 1800)
Go

select * from Cars1
go

--id	name	company	power
--1	Corrolla	Toyota	1800

SELECT NEXT VALUE FOR [dbo].[SequenceCounter]
GO
-- 7

INSERT INTO Cars3 VALUES 
(NEXT VALUE FOR [dbo].[SequenceCounter], 'Toyota ', 'Corolla', 1801)
GO

select * from Cars3
go

--id	name	company	power
--4	C500	Mercedez	5000
--5	Prius	Toyota	3200
--6	Civic	Honda	1800
--8	Toyota 	Corolla	1801

INSERT INTO Cars2 VALUES 
(NEXT VALUE FOR [dbo].[SequenceCounter], 'Renault ', 'Corolla', 1801)
GO

select * from Cars2
go

--id	name	company	power
--1	208	Peugeot	5400
--2	C500	BMW	8000
--3	C500	Peugeot	5400
--9	Renault 	Corolla	1801

INSERT INTO Cars1 VALUES 
(NEXT VALUE FOR [dbo].[SequenceCounter], 'Ford ', 'Corolla', 1801)
GO

--Msg 8101, Level 16, State 1, Line 106
--An explicit value for the identity column in table 'Cars1' can only be specified when a column list is used and IDENTITY_INSERT is ON.





--The value for the IDENTITY property cannot be reset to its initial value. 
--In contrast, the value for the SEQUENCE object can be reset.

CREATE SEQUENCE [dbo].[RecycleSequence]
 AS INT
 START WITH 1
 INCREMENT BY 1
 MINVALUE 1
 MAXVALUE 3
 CYCLE;
 GO


 --To reset the value of a SEQUENCE object, you have to set the minimum and maximum values 
 -- for the SEQUENCE and have to specify a CYCLE tag with the script. 
 -- For instance in the above script, the SEQUENCE value is reset 1 once the maximum value i.e. 3 
 --is reached. Therefore, if you execute the following script four times, 
 -- you will see that 1 will be returned


-- Take a look at the following script to see how a value can be reset using SEQUENCE object.

SELECT NEXT VALUE FOR [dbo].[RecycleSequence]
go


--(No column name)
--1

-- Difference 
-- A maximum value cannot be set for the IDENTITY property. 
-- On the other hand, the maximum value for a SEQUENCE object can be defined.

--The maximum value that the IDENTITY can take is equal to the maximum value of the data type of the column that the IDENTITY property is tied to. For example, the IDENTITY property of the id column of the Cars1 table can take the maximum value that the INT data type can hold since the type of the id column is INT.

--For a SEQUENCE object the MAXVALUE clause can be used to set the maximum value as shown in the following example.

CREATE SEQUENCE [dbo].[MaxSequence]
 AS INT
 START WITH 1
 INCREMENT BY 1
 MAXVALUE 3
GO

-- The sequence object 'MaxSequence' cache size is greater than the number of available values.



--In the above script, a SEQUENCE object has been created with a maximum value of 3. 
-- If you increment the value of this SEQUENCE beyond 3, following error will be thrown


-----------------

--Altering a Sequence
--To modify an existing sequence, the ALTER SEQUENCE statement is used. Have a look at the script below:

--ALTER SEQUENCE [NewCounter]
--RESTART WITH 7
--The above script will modify the existing sequence object ‘NewCounter’ by updating its starting value to 7.

--Now if you execute the following statement:

--SELECT NEXT VALUE FOR [dbo].[NewCounter]
--You will see ‘7’ in the output.

--Executing the above statement again will return 12 (7+5). This is because we only updated the starting value, the value for INCREMENT BY remains same, therefore 7 plus the increment value 5 will be equal to 12.

--CREATE SEQUENCE [dbo].[SequenceCounter]
-- AS INT
-- START WITH 1
-- INCREMENT BY 1
-- GO

SELECT NEXT VALUE FOR [dbo].[SequenceCounter]
go

--(No column name)
--10

ALTER SEQUENCE [dbo].[SequenceCounter]
RESTART WITH 100
go
--The above script will modify the existing sequence object ‘NewCounter’ by updating its starting value to 7.

-- Now if you execute the following statement:

SELECT NEXT VALUE FOR [dbo].[SequenceCounter]
go

--(No column name)
--100

SELECT NEXT VALUE FOR [dbo].[SequenceCounter]
go

-- 101

SELECT NEXT VALUE FOR [dbo].[SequenceCounter]
go

-- 102

SELECT *
from  Cars2
go

--id	name	company	power
--1	208	Peugeot	5400
--2	C500	BMW	8000
--3	C500	Peugeot	5400
--9	Renault 	Corolla	1801


INSERT INTO Cars2 VALUES 
(NEXT VALUE FOR [dbo].[SequenceCounter], 'Ferrari ', 'Italy', 2222)
GO

select * from Cars2
go

--id	name	company	power
--1	208	Peugeot	5400
--2	C500	BMW	8000
--3	C500	Peugeot	5400
--9	Renault 	Corolla	1801
--103	Ferrari 	Italy	2222

--------------------------------------------
