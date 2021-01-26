
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
ALTER DATABASE [caledario_eventos_ppd] ADD FILE ( NAME = 'eventos_2019', FILENAME = 'C:\Oficina\eventos_2019.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [filegrp_2019]
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

SELECT *,$Partition.fn_events_date(fecha_evento) AS Partition
FROM event_data
GO

--id_evento	nombre	info_extra	fecha_evento	Partition
--1	Salida puerto	Se realiza por la mañana	2018-01-01 00:00:00.000	2
--2	Cambio de buque	Se realiza directo sin almacenaje en puerto	2018-01-05 00:00:00.000	2
--3	Llegada a puerto	Se descargará por la tarde	2018-01-11 00:00:00.000	2

-- partition function
select name, create_date, value from sys.partition_functions f
inner join sys.partition_range_values rv
on f.function_id=rv.function_id
where f.name = 'fn_events_date'
gO

--name	create_date	value
--fn_events_date	2021-01-26 21:30:16.570	2018-01-01 00:00:00.000
--fn_events_date	2021-01-26 21:30:16.570	2019-01-01 00:00:00.000

select p.partition_number, p.rows from sys.partitions p
inner join sys.tables t
on p.object_id=t.object_id and t.name = 'event_data'
GO

--partition_number	rows
--1	0
--2	3
--3	0

DECLARE @TableName NVARCHAR(200) = N'event_data'
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

--object			p#	filegroup		rows	pages	comparison	value	first_page
--dbo.event_data	1	filegrp_archivo	0		0		less than	2018-01-01 00:00:00.000	0:0
--dbo.event_data	2	filegrp_2018	3		9		less than	2019-01-01 00:00:00.000	4:8
--dbo.event_data	3	filegrp_2019	0		0		less than	NULL	0:0
-------------------



INSERT INTO event_data
	Values ('Salida puerto','Se realiza por la tarde','2015-03-01'), ('Cambio de buque','Se realiza directo sin almacenaje en puerto','2019-01-05'), ('Llegada a puerto','Se descargará por la tarde','2020-01-11')
Go

SELECT *,$Partition.fn_events_date(fecha_evento)
FROM event_data
GO

--id_evento	nombre	info_extra	fecha_evento	(No column name)
--4	Salida puerto	Se realiza por la tarde	2015-03-01 00:00:00.000	1
--1	Salida puerto	Se realiza por la mañana	2018-01-01 00:00:00.000	2
--2	Cambio de buque	Se realiza directo sin almacenaje en puerto	2018-01-05 00:00:00.000	2
--3	Llegada a puerto	Se descargará por la tarde	2018-01-11 00:00:00.000	2
--5	Cambio de buque	Se realiza directo sin almacenaje en puerto	2019-01-05 00:00:00.000	3
--6	Llegada a puerto	Se descargará por la tarde	2020-01-11 00:00:00.000	3


select name, create_date, value from sys.partition_functions f
inner join sys.partition_range_values rv
on f.function_id=rv.function_id
where f.name = 'fn_events_date'
gO


select p.partition_number, p.rows from sys.partitions p
inner join sys.tables t
on p.object_id=t.object_id and t.name = 'event_data'
GO

--partition_number	rows
--1	1
--2	3
--3	2

DECLARE @TableName NVARCHAR(200) = N'event_data'
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

--object	p#	filegroup	rows	pages	comparison	value	first_page
--dbo.event_data	1	filegrp_archivo	1	9	less than	2018-01-01 00:00:00.000	3:8
--dbo.event_data	2	filegrp_2018	3	9	less than	2019-01-01 00:00:00.000	4:8
--dbo.event_data	3	filegrp_2019	2	9	less than	NULL	6:8

--------------------
INSERT INTO event_data
	Values ('Desembarco puerto','Se realiza por turnos','2020-03-01'), ('Cambio de buque','Se realiza directo sin estancia en puerto','2020-03-05'), ('Desatraque de puerto','Se desamarra por la tarde','2020-03-11')
GO

SELECT *,$Partition.fn_events_date(fecha_evento)
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
	Values ('Llegada puerto','Se realiza por la tarde','2018-03-01'), ('Cambio de buque','Dos dias cuarentena y almacenaje en puerto','2018-05-05'), ('Salida de puerto','Se zarpa por la tarde','2018-06-11')
GO

SELECT *,$Partition.fn_events_date(fecha_evento)
FROM event_data
GO

SELECT *,$Partition.fn_events_date(fecha_evento) as PARTITION
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


-- SPLIT FROM YEAR 2020 january 1st

ALTER PARTITION FUNCTION fn_events_date()
	SPLIT RANGE ('2020-01-01');
GO

SELECT *,$Partition.fn_events_date(fecha_evento) as PARTITION
FROM event_data
GO

DECLARE @TableName NVARCHAR(200) = N'event_data'
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

--id_evento	nombre	info_extra	fecha_evento	PARTITION
--4	Salida puerto	Se realiza por la tarde	2015-03-01 00:00:00.000	1
--1	Salida puerto	Se realiza por la mañana	2018-01-01 00:00:00.000	2
--2	Cambio de buque	Se realiza directo sin almacenaje en puerto	2018-01-05 00:00:00.000	2
--3	Llegada a puerto	Se descargará por la tarde	2018-01-11 00:00:00.000	2
--10	Llegada puerto	Se realiza por la tarde	2018-03-01 00:00:00.000	2
--11	Cambio de buque	Dos dias cuarentena y almacenaje en puerto	2018-05-05 00:00:00.000	2
--12	Salida de puerto	Se zarpa por la tarde	2018-06-11 00:00:00.000	2
--5	Cambio de buque	Se realiza directo sin almacenaje en puerto	2019-01-05 00:00:00.000	3
--6	Llegada a puerto	Se descargará por la tarde	2020-01-11 00:00:00.000	4
--7	Desembarco puerto	Se realiza por turnos	2020-03-01 00:00:00.000	4
--8	Cambio de buque	Se realiza directo sin estancia en puerto	2020-03-05 00:00:00.000	4
--9	Desatraque de puerto	Se desamarra por la tarde	2020-03-11 00:00:00.000	4

-- MERGE two partitions with ranges on left and right of 2018-01-01

ALTER PARTITION FUNCTION fn_events_date ()
 MERGE RANGE ('2018-01-01');
 GO

SELECT *,$Partition.fn_events_date(fecha_evento)
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
ALTER DATABASE [caledario_eventos_ppd] REMOVE FILE eventos_2018
go

ALTER DATABASE [caledario_eventos_ppd] REMOVE FILEGROUP filegrp_2018
GO


--The file 'eventos_2018' has been removed.
--The filegroup 'filegrp_2018' has been removed.

USE caledario_eventos_ppd
GO

select * from sys.filegroups
GO
--name	data_space_id	type	type_desc	is_default	is_system	filegroup_guid	log_filegroup_id	is_read_only	is_autogrow_all_files
--PRIMARY	1	FG	ROWS_FILEGROUP	1	0	NULL	NULL	0	0
--filegrp_archivo	2	FG	ROWS_FILEGROUP	0	0	15AAA97F-E432-45CD-89FD-B94DB7479501	NULL	0	0
--filegrp_2019	4	FG	ROWS_FILEGROUP	0	0	E94E05F8-0A3C-42B6-9AC9-74281030B8DC	NULL	0	0
--filegrp_2020	5	FG	ROWS_FILEGROUP	0	0	7B5FB287-85DE-42E9-BC7C-34C16B1E27A0	NULL	0	0

select * from sys.database_files
GO

--file_id	file_guid	type	type_desc	data_space_id	name	physical_name	state	state_desc	size	max_size	growth	is_media_read_only	is_read_only	is_sparse	is_percent_growth	is_name_reserved	is_persistent_log_buffer	create_lsn	drop_lsn	read_only_lsn	read_write_lsn	differential_base_lsn	differential_base_guid	differential_base_time	redo_start_lsn	redo_start_fork_guid	redo_target_lsn	redo_target_fork_guid	backup_lsn
--1	A8F52378-EEA2-4EC2-91DB-AB18A065410D	0	ROWS	1	caledario_eventos_ppd	C:\Oficina\caledario_eventos_ppd_main.mdf	0	ONLINE	1920	-1	0	0	0	0	0	0	0	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL
--2	5B241335-6019-4036-8318-F94FBB15F020	1	LOG	0	caledario_eventos_ppd_log	C:\Oficina\caledario_eventos_ppd_log.ldf	0	ONLINE	1272	268435456	10	0	0	0	1	0	0	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL
--3	21BEB6BD-AF7D-42D8-8685-941F081335F6	0	ROWS	2	Eventos_Archivo	C:\Oficina\Eventos_Archivo.ndf	0	ONLINE	640	12800	256	0	0	0	0	0	0	36000000022100001	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL
--5	28C67A77-BE7E-464F-A869-7F5ADEBC06B0	0	ROWS	5	eventos_2020	C:\Oficina\eventos_2020.ndf	0	ONLINE	640	12800	256	0	0	0	0	0	0	36000000027500001	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL
--6	DF67C5C9-0951-4D86-AA5C-8DC2EAC2DA4A	0	ROWS	4	eventos_2019	C:\Oficina\eventos_2019.ndf	0	ONLINE	640	12800	256	0	0	0	0	0	0	36000000030200001	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL


-- SWITCH

USE caledario_eventos_ppd
go

SELECT *,$Partition.fn_events_date(fecha_evento)
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



CREATE TABLE Archivo_Eventos
	( id_evento int identity (1,1),
	nombre varchar(20),
	info_extra varchar (200),
	fecha_evento datetime )
	ON filegrp_archivo
go


ALTER TABLE event_data
	SWITCH Partition 1 to Archivo_Eventos
go


select * from event_data
go


--id_evento	nombre	info_extra	fecha_evento
--5	Cambio de buque	Se realiza directo sin almacenaje en puerto	2019-01-05 00:00:00.000
--6	Llegada a puerto	Se descargará por la tarde	2020-01-11 00:00:00.000
--7	Desembarco puerto	Se realiza por turnos	2020-03-01 00:00:00.000
--8	Cambio de buque	Se realiza directo sin estancia en puerto	2020-03-05 00:00:00.000
--9	Desatraque de puerto	Se desamarra por la tarde	2020-03-11 00:00:00.000


select * from Archivo_Eventos
go

--id_evento	nombre	info_extra	fecha_evento
--4	Salida puerto	Se realiza por la tarde	2015-03-01 00:00:00.000
--1	Salida puerto	Se realiza por la mañana	2018-01-01 00:00:00.000
--2	Cambio de buque	Se realiza directo sin almacenaje en puerto	2018-01-05 00:00:00.000
--3	Llegada a puerto	Se descargará por la tarde	2018-01-11 00:00:00.000
--10	Llegada puerto	Se realiza por la tarde	2018-03-01 00:00:00.000
--11	Cambio de buque	Dos dias cuarentena y almacenaje en puerto	2018-05-05 00:00:00.000
--12	Salida de puerto	Se zarpa por la tarde	2018-06-11 00:00:00.000



DECLARE @TableName NVARCHAR(200) = N'event_data' SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows
, au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO
-- 2018 and before there not here
--object	p#	filegroup	rows	pages	comparison	value	first_page
--dbo.event_data	1	filegrp_archivo	0	0	less than	2019-01-01 00:00:00.000	0:0
--dbo.event_data	2	filegrp_2019	1	9	less than	2020-01-01 00:00:00.000	6:8
--dbo.event_data	3	filegrp_2020	4	9	less than	NULL	5:8

-- TRUNCATE

TRUNCATE TABLE event_data
	WITH (PARTITIONS (3));
go

select * from event_data
GO

--id_evento	nombre	info_extra	fecha_evento
--5	Cambio de buque	Se realiza directo sin almacenaje en puerto	2019-01-05 00:00:00.000


DECLARE @TableName NVARCHAR(200) = N'event_data'
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

--object	p#	filegroup	rows	pages	comparison	value	first_page
--dbo.event_data	1	filegrp_archivo	0	0	less than	2019-01-01 00:00:00.000	0:0
--dbo.event_data	2	filegrp_2019	1	9	less than	2020-01-01 00:00:00.000	6:8
--dbo.event_data	3	filegrp_2020	0	0	less than	NULL	0:0
