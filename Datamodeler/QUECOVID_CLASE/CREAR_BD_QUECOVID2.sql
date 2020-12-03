USE master
GO

DROP DATABASE IF EXISTS QUECOVID_CLASE
GO

CREATE DATABASE QUECOVID_CLASE
GO
USE QUECOVID_CLASE
GO
-- Generated by Oracle SQL Developer Data Modeler 20.3.0.283.0710
--   at:        2020-11-14 20:32:28 CET
--   site:      SQL Server 2012
--   type:      SQL Server 2012



CREATE TABLE CCAA 
    (
     COD_CCAA VARCHAR (2) NOT NULL , 
     NOMBRE_CCAA VARCHAR (400) NOT NULL 
    )
GO

ALTER TABLE CCAA ADD CONSTRAINT CCAA_PK PRIMARY KEY CLUSTERED (COD_CCAA)
     WITH (
     ALLOW_PAGE_LOCKS = ON , 
     ALLOW_ROW_LOCKS = ON )
GO

CREATE TABLE CODIGOPOSTAL 
    (
     CP VARCHAR (5) NOT NULL , 
     POBLACION VARCHAR (400) NOT NULL , 
     PROVINCIA_COD_PROVINCIA VARCHAR (2) NOT NULL 
    )
GO

ALTER TABLE CODIGOPOSTAL ADD CONSTRAINT CODIGOPOSTAL_PK PRIMARY KEY CLUSTERED (CP)
     WITH (
     ALLOW_PAGE_LOCKS = ON , 
     ALLOW_ROW_LOCKS = ON )
GO

CREATE TABLE ESTADO 
    (
     RESTRICCION_COD_RESTRICCION VARCHAR (3) NOT NULL , 
     COD_OBSERVACION VARCHAR (3) NOT NULL , 
     CODIGOPOSTAL_CP VARCHAR (5) NOT NULL 
    )
GO

ALTER TABLE ESTADO ADD CONSTRAINT ESTADO_PK PRIMARY KEY CLUSTERED (RESTRICCION_COD_RESTRICCION, COD_OBSERVACION, CODIGOPOSTAL_CP)
     WITH (
     ALLOW_PAGE_LOCKS = ON , 
     ALLOW_ROW_LOCKS = ON )
GO

CREATE TABLE OBSERVACION 
    (
     COD_OBSERVACION VARCHAR (3) NOT NULL , 
     RESTRICCION_COD_RESTRICCION VARCHAR (3) NOT NULL , 
     OBSERVACION VARCHAR (900) NOT NULL 
    )
GO

ALTER TABLE OBSERVACION ADD CONSTRAINT OBSERVACION_PK PRIMARY KEY CLUSTERED (COD_OBSERVACION, RESTRICCION_COD_RESTRICCION)
     WITH (
     ALLOW_PAGE_LOCKS = ON , 
     ALLOW_ROW_LOCKS = ON )
GO

CREATE TABLE PROVINCIA 
    (
     COD_PROVINCIA VARCHAR (2) NOT NULL , 
     NOMBRE_PROVINCIA VARCHAR (400) NOT NULL , 
     CCAA_COD_CCAA VARCHAR (2) NOT NULL 
    )
GO

ALTER TABLE PROVINCIA ADD CONSTRAINT PROVINCIA_PK PRIMARY KEY CLUSTERED (COD_PROVINCIA)
     WITH (
     ALLOW_PAGE_LOCKS = ON , 
     ALLOW_ROW_LOCKS = ON )
GO

CREATE TABLE RESTRICCION 
    (
     COD_RESTRICCION VARCHAR (3) NOT NULL , 
     TIPO_RESTRICCION VARCHAR (400) 
    )
GO

ALTER TABLE RESTRICCION ADD CONSTRAINT RESTRICCION_PK PRIMARY KEY CLUSTERED (COD_RESTRICCION)
     WITH (
     ALLOW_PAGE_LOCKS = ON , 
     ALLOW_ROW_LOCKS = ON )
GO

ALTER TABLE CODIGOPOSTAL 
    ADD CONSTRAINT CODIGOPOSTAL_PROVINCIA_FK FOREIGN KEY 
    ( 
     PROVINCIA_COD_PROVINCIA
    ) 
    REFERENCES PROVINCIA 
    ( 
     COD_PROVINCIA 
    ) 
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION 
GO

ALTER TABLE ESTADO 
    ADD CONSTRAINT ESTADO_CODIGOPOSTAL_FK FOREIGN KEY 
    ( 
     CODIGOPOSTAL_CP
    ) 
    REFERENCES CODIGOPOSTAL 
    ( 
     CP 
    ) 
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION 
GO

ALTER TABLE ESTADO 
    ADD CONSTRAINT ESTADO_RESTRICCION_FK FOREIGN KEY 
    ( 
     RESTRICCION_COD_RESTRICCION
    ) 
    REFERENCES RESTRICCION 
    ( 
     COD_RESTRICCION 
    ) 
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION 
GO

ALTER TABLE OBSERVACION 
    ADD CONSTRAINT OBSERVACION_RESTRICCION_FK FOREIGN KEY 
    ( 
     RESTRICCION_COD_RESTRICCION
    ) 
    REFERENCES RESTRICCION 
    ( 
     COD_RESTRICCION 
    ) 
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION 
GO

ALTER TABLE PROVINCIA 
    ADD CONSTRAINT PROVINCIA_CCAA_FK FOREIGN KEY 
    ( 
     CCAA_COD_CCAA
    ) 
    REFERENCES CCAA 
    ( 
     COD_CCAA 
    ) 
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION 
GO
