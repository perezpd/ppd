USE [master]
GO

/****** Object:  Database [containers_ppd_v1]    Script Date: 26/01/2021 20:34:54 ******/
CREATE DATABASE [containers_ppd_v1]
 CONTAINMENT = NONE
 ON  PRIMARY
( NAME = N'containers_ppd_v1',
  FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\containers_ppd_v1.mdf' ,
  SIZE = 8192KB ,
  MAXSIZE = UNLIMITED,
  FILEGROWTH = 65536KB )
 LOG ON
( NAME = N'containers_ppd_v1_log',
  FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\containers_ppd_v1_log.ldf' ,
  SIZE = 8192KB,
  MAXSIZE = 2048GB,
  FILEGROWTH = 65536KB );
GO

USE [containers_ppd_v1];
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
