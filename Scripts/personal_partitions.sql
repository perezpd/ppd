
-- https://docs.microsoft.com/en-us/sql/relational-databases/partitions/partitioned-tables-and-indexes?view=sql-server-ver15

-- PARTITIONS
--Crear un grupo o grupos de archivos y los archivos correspondientes que contendrán las particiones especificadas por el esquema de partición.
--Crear una función de partición que asigna las filas de una tabla o un índice a particiones según los valores de una columna especificada.
--Crear un esquema de partición que asigna las particiones de una tabla o índice con particiones a los nuevos grupos de archivos.
--Crear o modificar una tabla o un índice y especificar el esquema de partición como ubicación de almacenamiento.


-- OPERATIONS
-- Operations SPLIT-MERGE-SWITCH-TRUNCATE PARTITION

--Create a database with multiple files and filegroups
--Create a Partition Function and a Partition Scheme based on date
--Create a Table on the Partition
--Insert Data into the Table
--Investigate how the data is stored according to partition

-- ONLY HORIZONTAL
-- http://datablog.roman-halliday.com/index.php/2019/02/02/partitions-in-sql-server-creating-a-partitioned-table/


--What makes a partitioned table in SQL Server?
--In SQL Server, to partition a table you first need to define a function, and then a scheme.

--Partition Function: The definition of how data is to be split.
-- It includes the data type and the value ranges to use in each partition.

--Partition Scheme: The definition of how a function is to be applied to data files.
-- This allows DBAs to split data across logical storage locations if required,
-- however in most modern environments with large SANs most SQL Server implementations and their DBAs
--  will just use ‘primary’.

--A partition function can be used in one or more schemes,
-- and a scheme in one or more tables.
-- There can be organisational advantages to sharing a scheme/function across tables
--(update one, and you update everything in kind). However, in my experience most cases DBAs prefer to have one function and scheme combination for each table.

USE master
go
DROP DATABASE IF EXISTS caledario_eventos_ppd
GO
CREATE DATABASE [caledario_eventos_ppd]
	ON PRIMARY ( NAME = 'caledario_eventos_ppd',
		FILENAME = 'C:\Oficina\caledario_eventos_ppd_main.mdf' ,
		SIZE = 15360KB , MAXSIZE = UNLIMITED, FILEGROWTH = 0)
	LOG ON ( NAME = 'caledario_eventos_ppd_log',
		FILENAME = 'C:\Oficina\caledario_eventos_ppd_log.ldf' ,
		SIZE = 10176KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

-- SSMS DB Properties

USE caledario_eventos_ppd
GO

ALTER DATABASE [caledario_eventos_ppd] ADD FILEGROUP [filegrp_archivo]
GO
ALTER DATABASE [caledario_eventos_ppd] ADD FILEGROUP [filegrp_2018]
GO
ALTER DATABASE [caledario_eventos_ppd] ADD FILEGROUP [filegrp_2019]
GO
ALTER DATABASE [caledario_eventos_ppd] ADD FILEGROUP [filegrp_2020]
GO

select * from sys.filegroups
GO

ALTER DATABASE [caledario_eventos_ppd] ADD FILE ( NAME = 'Eventos_Archivo', FILENAME = 'C:\Oficina\Eventos_Archivo.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [filegrp_archivo]
GO
ALTER DATABASE [caledario_eventos_ppd] ADD FILE ( NAME = 'eventos_2018', FILENAME = 'C:\Oficina\eventos_2018.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [filegrp_2018]
GO
ALTER DATABASE [caledario_eventos_ppd] ADD FILE ( NAME = 'eventos_2018', FILENAME = 'C:\Oficina\eventos_2019.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [filegrp_2019]
GO
ALTER DATABASE [caledario_eventos_ppd] ADD FILE ( NAME = 'eventos_2020', FILENAME = 'C:\Oficina\eventos_2020.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [filegrp_2020]
GO


select * from sys.filegroups
GO
--name	data_space_id	type	type_desc	is_default	is_system	filegroup_guid	log_filegroup_id	is_read_only	is_autogrow_all_files
--PRIMARY	1	FG	ROWS_FILEGROUP	1	0	NULL	NULL	0	0
--filegrp_archivo	2	FG	ROWS_FILEGROUP	0	0	08B2A421-A73B-4F1E-AEE4-5A61001EAFB6	NULL	0	0
--filegrp_2018	3	FG	ROWS_FILEGROUP	0	0	673D0483-C35E-4687-8384-3D8486B8D5C4	NULL	0	0
--filegrp_2019	4	FG	ROWS_FILEGROUP	0	0	94930C7B-F75E-4655-8D22-0A851709584B	NULL	0	0
--filegrp_2020	5	FG	ROWS_FILEGROUP	0	0	9B7B3FCE-E019-411C-8D8C-83E371EA326D	NULL	0	0

select * from sys.database_files
GO


-- PARTITION FUNCTION

CREATE PARTITION FUNCTION fn_events_date (datetime)
AS RANGE RIGHT
	FOR VALUES ('2018-01-01','2019-01-01')
GO

-- PARTITION SCHEME


CREATE PARTITION SCHEME events_date
AS PARTITION fn_events_date
	TO (filegrp_archivo,filegrp_2018,filegrp_2019,filegrp_2020)
GO


-- Partition scheme 'events_date' has been created successfully. 'filegrp_2020' is marked as the next used filegroup in partition scheme 'events_date'.


--Partitioned Table
--Lastly a table needs to be defined (as normal), with two additional requirements:

--The storage location is given as the partition scheme (with the name of the column to be used
--for partitioning).
--The table must have a clustered index (usually the primary key) which includes the column to be used
-- for partitioning.

DROP TABLE IF EXISTS event_data
GO
CREATE TABLE event_data
	( id_evento int identity (1,1),
	nombre varchar(20),
	info_extra varchar (200),
	fecha_evento datetime )
	ON events_date -- partition scheme
		(fecha_evento) -- the column to apply the function within the scheme
GO

-- SSMS TABLE PROPERTIES PARTITIONS

INSERT INTO event_data
	Values ('Salida puerto','Se realiza por la mañana','2018-01-01'), ('Cambio de buque','Se realiza directo sin almacenaje en puerto','2018-01-05'), ('Llegada a puerto','Se descargará por la tarde','2018-01-11')
Go


----------------

SELECT *,$Partition.fn_events_date(fecha_alta) AS Partition
FROM event_data
GO

-- partition function
select name, create_date, value from sys.partition_functions f
inner join sys.partition_range_values rv
on f.function_id=rv.function_id
where f.name = 'fn_events_date'
gO

--name	create_date	value
--fn_events_date	2020-02-03 10:32:30.537	2016-01-01 00:00:00.000
--fn_events_date	2020-02-03 10:32:30.537	2017-01-01 00:00:00.000

select p.partition_number, p.rows from sys.partitions p
inner join sys.tables t
on p.object_id=t.object_id and t.name = 'event_data'
GO

--partition_number	rows
--1	3
--2	0
--3	0

DECLARE @TableName NVARCHAR(200) = N'event_data'
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

--object			p#	filegroup	rows	pages	comparison	value	first_page
--dbo.event_data	1	FG_Archivo	3		9			less than	2016-01-01 00:00:00.000	3:8
--dbo.event_data	2	FG_2016		0		0			less than	2017-01-01 00:00:00.000	0:0
--dbo.event_data	3	FG_2017		0		0			less than	NULL	0:0
-------------------
INSERT INTO event_data
	VALUES ('Laura','Muñoz','2016-06-23'), ('Rosa Maria','Leandro','2016-02-03'), ('Federico','Ramos','2016-04-06')
GO

SELECT *,$Partition.fn_events_date(fecha_alta)
FROM event_data
GO

select name, create_date, value from sys.partition_functions f
inner join sys.partition_range_values rv
on f.function_id=rv.function_id
where f.name = 'fn_events_date'
gO


select p.partition_number, p.rows from sys.partitions p
inner join sys.tables t
on p.object_id=t.object_id and t.name = 'event_data'
GO

DECLARE @TableName NVARCHAR(200) = N'event_data'
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

--object	p#	filegroup	rows	pages	comparison	value	first_page
--dbo.event_data	1	FG_Archivo	3	9	less than	2016-01-01 00:00:00.000	3:8
--dbo.event_data	2	FG_2016	3	9	less than	2017-01-01 00:00:00.000	4:8
--dbo.event_data	3	FG_2017	0	0	less than	NULL	0:0

--------------------
INSERT INTO event_data
	VALUES ('Ismael','Cabana','2017-05-21'), ('Alejandra','Martinez','2017-07-09'), ('Alfonso','Verdes','2017-09-12')
GO

SELECT *,$Partition.fn_events_date(fecha_alta)
FROM event_data
GO

select name, create_date, value from sys.partition_functions f
inner join sys.partition_range_values rv
on f.function_id=rv.function_id
where f.name = 'fn_events_date'
gO


select p.partition_number, p.rows from sys.partitions p
inner join sys.tables t
on p.object_id=t.object_id and t.name = 'event_data'
GO

DECLARE @TableName NVARCHAR(200) = N'event_data'
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

--object	p#	filegroup	rows	pages	comparison	value	first_page
--dbo.event_data	1	FG_Archivo	3	9	less than	2016-01-01 00:00:00.000	3:8
--dbo.event_data	2	FG_2016	3	9	less than	2017-01-01 00:00:00.000	4:8
--dbo.event_data	3	FG_2017	3	9	less than	NULL	5:8

------------------


INSERT INTO event_data
	VALUES ('Amanda','Smith','2018-02-12'), ('Adolfo','Muñiz','2018-01-23'), ('Rosario','Fuertes','2018-02-23')
GO



SELECT *,$Partition.fn_events_date(fecha_alta) as PARTITION
FROM event_data
GO

select name, create_date, value from sys.partition_functions f
inner join sys.partition_range_values rv
on f.function_id=rv.function_id
where f.name = 'fn_events_date'
gO


select p.partition_number, p.rows from sys.partitions p
inner join sys.tables t
on p.object_id=t.object_id and t.name = 'event_data'
GO

DECLARE @TableName NVARCHAR(200) = N'event_data'
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO


--object	p#	filegroup	rows	pages	comparison	value	first_page
--dbo.event_data	1	FG_Archivo	3	9	less than	2016-01-01 00:00:00.000	3:8
--dbo.event_data	2	FG_2016		3	9	less than	2017-01-01 00:00:00.000	4:8
--dbo.event_data	3	FG_2017		6	9	less than	NULL	5:8


-- SPLIT

ALTER PARTITION FUNCTION fn_events_date()
	SPLIT RANGE ('2018-01-01');
GO

SELECT *,$Partition.fn_events_date(fecha_alta) as PARTITION
FROM event_data
GO

DECLARE @TableName NVARCHAR(200) = N'event_data'
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

--object			p#	filegroup	rows	pages	comparison	value	first_page
--dbo.event_data	1	FG_Archivo	3	9	less than	2016-01-01 00:00:00.000	3:8
--dbo.event_data	2	FG_2016		3	9	less than	2017-01-01 00:00:00.000	4:8
--dbo.event_data	3	FG_2017		3	9	less than	2018-01-01 00:00:00.000	5:8
--dbo.event_data	4	FG_2018		3	9	less than	NULL	6:8

-- MERGE

ALTER PARTITION FUNCTION fn_events_date ()
 MERGE RANGE ('2016-01-01');
 GO

SELECT *,$Partition.fn_events_date(fecha_alta)
FROM event_data
GO
DECLARE @TableName NVARCHAR(200) = N'event_data'
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

--object			p#	filegroup	rows	pages	comparison	value	first_page
--dbo.event_data	1	FG_Archivo	6	9	less than	2017-01-01 00:00:00.000	3:8
--dbo.event_data	2	FG_2017		3	9	less than	2018-01-01 00:00:00.000	5:8
--dbo.event_data	3	FG_2018		3	9	less than	NULL	6:8

-- Example SWITCH

USE master
GO
ALTER DATABASE [caledario_eventos_ppd] REMOVE FILE Altas_2016
go

ALTER DATABASE [caledario_eventos_ppd] REMOVE FILEGROUP FG_2016
GO


--The file 'Altas_2016' has been removed.
--The filegroup 'FG_2016' has been removed.

select * from sys.filegroups
GO

select * from sys.database_files
GO


-- SWITCH

USE caledario_eventos_ppd
go

SELECT *,$Partition.fn_events_date(fecha_alta)
FROM event_data
GO
DECLARE @TableName NVARCHAR(200) = N'event_data'
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

--object			p#	filegroup	rows	pages	comparison	value	first_page
--dbo.event_data	1	FG_Archivo	6	9	less than	2017-01-01 00:00:00.000	3:8
--dbo.event_data	2	FG_2017		3	9	less than	2018-01-01 00:00:00.000	5:8
--dbo.event_data	3	FG_2018		3	9	less than	NULL	6:8



CREATE TABLE Archivo_Altas
( id_alta int identity (1,1),
nombre varchar(20),
apellido varchar (20),
fecha_alta datetime )
ON FG_Archivo
go


ALTER TABLE event_data
	SWITCH Partition 1 to Archivo_Altas
go


select * from event_data
go


--id_alta	nombre	apellido	fecha_alta
--7	Ismael	Cabana	2017-05-21 00:00:00.000
--8	Alejandra	Martinez	2017-07-09 00:00:00.000
--9	Alfonso	Verdes	2017-09-12 00:00:00.000
--10	Amanda	Smith	2018-02-12 00:00:00.000
--11	Adolfo	Muñiz	2018-01-23 00:00:00.000
--12	Rosario	Fuertes	2018-02-23 00:00:00.000


select * from Archivo_Altas
go

--id_alta	nombre	apellido	fecha_alta
--1	Antonio	Ruiz	2015-01-01 00:00:00.000
--2	Lucas	García	2015-05-05 00:00:00.000
--3	Manuel	Sanchez	2015-08-11 00:00:00.000
--4	Laura	Muñoz	2016-06-23 00:00:00.000
--5	Rosa Maria	Leandro	2016-02-03 00:00:00.000
--6	Federico	Ramos	2016-04-06 00:00:00.000



DECLARE @TableName NVARCHAR(200) = N'event_data' SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows
, au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

--object			p#	filegroup	rows	pages	comparison	value	first_page
--dbo.event_data	1	FG_Archivo	0	0	less than	2017-01-01 00:00:00.000	0:0
--dbo.event_data	2	FG_2017		3	9	less than	2018-01-01 00:00:00.000	5:8
--dbo.event_data	3	FG_2018		3	9	less than	NULL	6:8

-- TRUNCATE

TRUNCATE TABLE event_data
	WITH (PARTITIONS (3));
go

select * from event_data
GO

--id_alta	nombre	apellido	fecha_alta
--7	Ismael	Cabana	2017-05-21 00:00:00.000
--8	Alejandra	Martinez	2017-07-09 00:00:00.000
--9	Alfonso	Verdes	2017-09-12 00:00:00.000


DECLARE @TableName NVARCHAR(200) = N'event_data'
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

--object			p#	filegroup	rows	pages	comparison	value	first_page
--dbo.event_data	1	FG_Archivo	0	0	less than	2017-01-01 00:00:00.000	0:0
--dbo.event_data	2	FG_2017		3	9	less than	2018-01-01 00:00:00.000	5:8
--dbo.event_data	3	FG_2018		0	0	less than	NULL	0:0
