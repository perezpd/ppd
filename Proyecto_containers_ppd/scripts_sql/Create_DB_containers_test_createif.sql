USE [master]
GO
IF DB_ID('containers_ppd_test') IS NOT NULL
	BEGIN 
		DECLARE @dbname char(128);
		SET @dbname='containers_ppd_test';
		PRINT 'DB EXISTS then SET OFFLINE '+@dbname;
		ALTER DATABASE [@dbname] SET OFFLINE WITH ROLLBACK IMMEDIATE;

		DROP DATABASE IF EXISTS [@dbname];

		--/****** Object:  Database [containers_ppd_v1]    Script Date: 26/01/2021 20:34:54 ******/
		 CREATE DATABASE [@dbname]
		 CONTAINMENT = NONE
		 ON  PRIMARY
		 ( NAME =  'containers_ppd_test_dat',
		  FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\containers_ppd_test.mdf' ,
		  SIZE = 8192KB ,
		  MAXSIZE = UNLIMITED,
		  FILEGROWTH = 65536KB )
		 LOG ON
		 ( NAME = 'containers_ppd_test_log',
		  FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\containers_ppd_test_log.ldf' ,
		  SIZE = 8192KB,
		  MAXSIZE = 2048GB,
		  FILEGROWTH = 65536KB );


	END
ELSE 
	BEGIN
		USE [master]
		PRINT 'CREAMOS';
		 CREATE DATABASE [containers_ppd_test] 
		 CONTAINMENT = NONE
		 ON  PRIMARY
		 ( NAME =  'containers_ppd_test_dat',
		  FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\containers_ppd_test.mdf' ,
		  SIZE = 8192KB ,
		  MAXSIZE = UNLIMITED,
		  FILEGROWTH = 65536KB )
		 LOG ON
		 ( NAME = 'containers_ppd_test_log',
		  FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\containers_ppd_test_log.ldf' ,
		  SIZE = 8192KB,
		  MAXSIZE = 2048GB,
		  FILEGROWTH = 65536KB );
		
	END
GO
USE [containers_ppd_test];
GO
-- create SCHEMAS after check existence
DROP SCHEMA IF EXISTS Mgmt
GO

CREATE SCHEMA Mgmt;
GO

-- Sales
DROP SCHEMA IF EXISTS Sales
GO

CREATE SCHEMA Sales;
GO

-- Import
DROP SCHEMA IF EXISTS Import
GO

CREATE SCHEMA Import;
GO


-- SERVER ROLES and USER ROLES
-- we add users to role and then user inherit the permissions and access
DROP ROLE IF EXISTS OfficeMgmt;
GO
CREATE ROLE OfficeMgmt;
GO

GRANT SELECT ON  SCHEMA::Mgmt TO OfficeMgmt;
GO

DROP ROLE IF EXISTS Personal;
GO
CREATE ROLE Personal;
GO

GRANT SELECT ON  SCHEMA::Sales TO Personal;
GO

GRANT SELECT ON  SCHEMA::Import TO Personal;
GO


-- users
-- creating an user with no login to avoid errors
DROP USER IF EXISTS EncargadoLuis
GO
CREATE USER EncargadoLuis WITHOUT LOGIN;
GO
-- adding user EncargadoLuis to ROLE OfficeMgmt
ALTER ROLE OfficeMgmt
	ADD MEMBER EncargadoLuis;
GO

-- creating an user with no login to avoid errors
DROP USER IF EXISTS VendedorAngel
GO
CREATE USER VendedorAngel WITHOUT LOGIN;
GO
-- adding user EncargadoLuis to ROLE OfficeMgmt
ALTER ROLE Personal
	ADD MEMBER VendedorAngel;
GO

-- Create Containers DB admin user with login called Containers_Admin
USE [master]
GO
CREATE LOGIN [Containers_Admin] WITH PASSWORD='Abcd1234.', 
DEFAULT_DATABASE=[containers_ppd_test], 
CHECK_EXPIRATION=OFF, 
CHECK_POLICY=OFF
GO
use [containers_ppd_test]

GO
use [master]

GO
USE [containers_ppd_test]
GO
CREATE USER [Containers_Admin] FOR LOGIN [Containers_Admin] WITH DEFAULT_SCHEMA=[dbo]
GO


