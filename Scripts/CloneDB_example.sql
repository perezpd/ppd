-------------------------------------------------------------------------------
--  When we want to have a full copy of our databse we can use this method
-- DBCC CLONEDATABASE

-- https://support.microsoft.com/en-us/help/3177838/how-to-use-dbcc-clonedatabase-to-generate-a-schema-and-statistics-only
-- https://docs.microsoft.com/es-es/sql/t-sql/database-console-commands/dbcc-clonedatabase-transact-sql?view=sql-server-2017

USE master;
GO

-- Generate the clone of Pubs database as a test.
DBCC CLONEDATABASE (Pubs, Pubs_Clone);
GO

-- Result
--Database cloning for 'pubs' has started with target as 'Pubs_Clone'.
--Database cloning for 'pubs' has finished. Cloned database is 'Pubs_Clone'.
--Database 'Pubs_Clone' is a cloned database. A cloned database should be used for diagnostic purposes only and is not supported for use in a production environment.
--DBCC execution completed. If DBCC printed error messages, contact your system administrator.


--Crear un clon de la base de datos de nuestro proyecto.
-- se comprueba para su uso en producción que incluye una copia de seguridad de la base de datos clonada.
--En el ejemplo siguiente se crea un clon de solo esquema de la base de datos [containers_ppd_test] 
-- sin datos de estadísticas ni de almacén de consultas que se comprueba para su uso como base de datos de producción.
-- También se creará una copia de seguridad comprobada de la base de datos clonada ( SQL Server 2016 (13.x) SP2 y versiones posteriores).

DBCC CLONEDATABASE (containers_ppd_test, containers_ppd_test_clone) WITH VERIFY_CLONEDB , BACKUP_CLONEDB;    
GO
-- we have an error
--Msg 195, Level 15, State 4, Line 43
--'VERIFY_CLONEDB' is not a recognized option

-- ohter people report that we need CU8 update to use this option
-- SEE: https://stackoverflow.com/questions/65785233/sql-server-2017-verify-clonedb-is-not-a-recognized-option


-- documentation says that we need a Cumulative Update 8 For Sql SERVER 2017 
-- https://support.microsoft.com/en-us/topic/kb4338363-cumulative-update-8-for-sql-server-2017-13614b96-ea3f-46ca-668b-5bcb5be84468

-- comprobamos compatibilidad
SELECT compatibility_level FROM sys.databases WHERE name = 'containers_ppd_test';

/*
compatibility_level
140
*/

SELECT @@version;
GO
/*
(No column name)
Microsoft SQL Server 2017 (RTM) - 14.0.1000.169 (X64)   Aug 22 2017 17:04:49   Copyright (C) 2017 Microsoft Corporation  Enterprise Evaluation Edition (64-bit) on Windows 10 Enterprise 10.0 <X64> (Build 19042: ) (Hypervisor) 
*/

DBCC CLONEDATABASE (containers_ppd_test, containers_ppd_test_clone) WITH BACKUP_CLONEDB;    
GO

--Msg 195, Level 15, State 4, Line 56
--'BACKUP_CLONEDB' is not a recognized option.

-- Same error.

--To avoid problems with other features, I will do abasic clone to clone my DB

DBCC CLONEDATABASE (containers_ppd_test, containers_ppd_test_clone);    
GO

/*
Database cloning for 'containers_ppd_test' has started with target as 'containers_ppd_test_clone'.
Database cloning for 'containers_ppd_test' has finished. Cloned database is 'containers_ppd_test_clone'.
Database 'containers_ppd_test_clone' is a cloned database. A cloned database should be used for diagnostic purposes only and is not supported for use in a production environment.
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
*/

-- check info of the new db
sp_helpdb containers_ppd_test_clone;
GO
/*
name	db_size	owner	dbid	created	status	compatibility_level
containers_ppd_test_clone	     16.00 MB	WPPD-01\ppd	25	Mar 11 2021	Status=ONLINE, Updateability=READ_ONLY, UserAccess=MULTI_USER, Recovery=FULL, Version=869, Collation=Latin1_General_CI_AS, SQLSortOrder=0, IsAutoCreateStatistics, IsAutoUpdateStatistics, IsFullTextEnabled	140

name	fileid	filename	filegroup	size	maxsize	growth	usage
containers_ppd_test	1	C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\containers_ppd_test_1687079550.mdf	PRIMARY	8192 KB	Unlimited	65536 KB	data only
containers_ppd_test_log	2	C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\containers_ppd_test_log_1334893396.ldf	NULL	8192 KB	2147483648 KB	65536 KB	log only
*/

-- CAREFUL
-- Updateability=READ_ONLY
