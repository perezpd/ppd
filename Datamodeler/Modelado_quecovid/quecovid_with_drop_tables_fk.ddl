-- Generated by Oracle SQL Developer Data Modeler 20.3.0.283.0710
--   at:        2020-11-20 18:10:54 GMT
--   site:      SQL Server 2008
--   type:      SQL Server 2008



ALTER TABLE datos_counidades 
    DROP CONSTRAINT datos_counidades_comunidad_autonoma_FK 
GO

ALTER TABLE Provincia 
    DROP CONSTRAINT Provincia_comunidad_autonoma_FK 
GO

DROP TABLE comunidad_autonoma
GO

ALTER TABLE datos_counidades 
    DROP CONSTRAINT datos_counidades_Datos_comunidad_FK 
GO

DROP TABLE Datos_comunidad
GO

DROP TABLE datos_counidades
GO

ALTER TABLE Restricciones_actuales 
    DROP CONSTRAINT Restricciones_actuales_Fuentes_FK 
GO

DROP TABLE Fuentes
GO

ALTER TABLE restricciones_cp 
    DROP CONSTRAINT restricciones_cp_Localidad_cp_FK 
GO

DROP TABLE Localidad_cp
GO

ALTER TABLE Localidad_cp 
    DROP CONSTRAINT Localidad_cp_Municipio_FK 
GO

DROP TABLE Municipio
GO

ALTER TABLE Municipio 
    DROP CONSTRAINT Municipio_Provincia_FK 
GO

DROP TABLE Provincia
GO

ALTER TABLE restricciones_cp 
    DROP CONSTRAINT restricciones_cp_Restricciones_actuales_FK 
GO

DROP TABLE Restricciones_actuales
GO

DROP TABLE restricciones_cp
GO

CREATE TABLE comunidad_autonoma 
    (
     PK_ca INTEGER NOT NULL 
    )
GO

ALTER TABLE comunidad_autonoma ADD CONSTRAINT comunidad_autonoma_PK PRIMARY KEY CLUSTERED (PK_ca)
     WITH (
     ALLOW_PAGE_LOCKS = ON , 
     ALLOW_ROW_LOCKS = ON )
GO

CREATE TABLE Datos_comunidad 
    (
     PK_datos INTEGER NOT NULL , 
     casos_nuevos INTEGER , 
     casos_totales INTEGER , 
     fallecidos_totales INTEGER , 
     pacientes_uci INTEGER , 
     hospitalizados_totales INTEGER 
    )
GO

ALTER TABLE Datos_comunidad ADD CONSTRAINT Datos_comunidad_PK PRIMARY KEY CLUSTERED (PK_datos)
     WITH (
     ALLOW_PAGE_LOCKS = ON , 
     ALLOW_ROW_LOCKS = ON )
GO

CREATE TABLE datos_counidades 
    (
     comunidad_autonoma_PK_ca INTEGER NOT NULL , 
     Datos_comunidad_PK_datos INTEGER NOT NULL 
    )
GO

ALTER TABLE datos_counidades ADD CONSTRAINT datos_counidades_PK PRIMARY KEY CLUSTERED (comunidad_autonoma_PK_ca, Datos_comunidad_PK_datos)
     WITH (
     ALLOW_PAGE_LOCKS = ON , 
     ALLOW_ROW_LOCKS = ON )
GO

CREATE TABLE Fuentes 
    (
     PK_boletin INTEGER NOT NULL , 
     fecha_boletin DATE , 
     tipo TEXT 
    )
GO

ALTER TABLE Fuentes ADD CONSTRAINT Fuentes_PK PRIMARY KEY CLUSTERED (PK_boletin)
     WITH (
     ALLOW_PAGE_LOCKS = ON , 
     ALLOW_ROW_LOCKS = ON )
GO

CREATE TABLE Localidad_cp 
    (
     PK_localidad INTEGER NOT NULL , 
     Municipio_PK_municipio INTEGER NOT NULL , 
     Codigo_postal INTEGER NOT NULL , 
     Poblacion VARCHAR (100) , 
     Municipio_PK_provincia INTEGER NOT NULL 
    )
GO

ALTER TABLE Localidad_cp ADD CONSTRAINT Localidad_cp_PK PRIMARY KEY CLUSTERED (PK_localidad, Municipio_PK_provincia)
     WITH (
     ALLOW_PAGE_LOCKS = ON , 
     ALLOW_ROW_LOCKS = ON )
GO

CREATE TABLE Municipio 
    (
     PK_municipio INTEGER NOT NULL , 
     Provincia_PK_provincia INTEGER NOT NULL , 
     nombre_mun VARCHAR (100) 
    )
GO

ALTER TABLE Municipio ADD CONSTRAINT Municipio_PK PRIMARY KEY CLUSTERED (PK_municipio, Provincia_PK_provincia)
     WITH (
     ALLOW_PAGE_LOCKS = ON , 
     ALLOW_ROW_LOCKS = ON )
GO

CREATE TABLE Provincia 
    (
     PK_provincia INTEGER NOT NULL , 
     comunidad_autonoma_PK_ca INTEGER NOT NULL , 
     nombre_prov VARCHAR (100) 
    )
GO

ALTER TABLE Provincia ADD CONSTRAINT Provincia_PK PRIMARY KEY CLUSTERED (PK_provincia)
     WITH (
     ALLOW_PAGE_LOCKS = ON , 
     ALLOW_ROW_LOCKS = ON )
GO

CREATE TABLE Restricciones_actuales 
    (
     PK_restric_espacios INTEGER NOT NULL , 
     concepto_restriccion TEXT NOT NULL , 
     fecha_inicio DATE , 
     fecha_fin DATE , 
     Fuentes_PK_boletin INTEGER NOT NULL , 
     fecha_actualizacion DATETIME 
    )
GO

ALTER TABLE Restricciones_actuales ADD CONSTRAINT Restricciones_actuales_PK PRIMARY KEY CLUSTERED (PK_restric_espacios)
     WITH (
     ALLOW_PAGE_LOCKS = ON , 
     ALLOW_ROW_LOCKS = ON )
GO

CREATE TABLE restricciones_cp 
    (
     Restricciones_actuales_PK_restric_espacios INTEGER NOT NULL , 
     Localidad_cp_PK_localidad INTEGER NOT NULL , 
     Localidad_cp_Municipio_PK_provincia INTEGER NOT NULL 
    )
GO

ALTER TABLE restricciones_cp ADD CONSTRAINT restricciones_cp_PK PRIMARY KEY CLUSTERED (Restricciones_actuales_PK_restric_espacios, Localidad_cp_PK_localidad, Localidad_cp_Municipio_PK_provincia)
     WITH (
     ALLOW_PAGE_LOCKS = ON , 
     ALLOW_ROW_LOCKS = ON )
GO

ALTER TABLE datos_counidades 
    ADD CONSTRAINT datos_counidades_comunidad_autonoma_FK FOREIGN KEY 
    ( 
     comunidad_autonoma_PK_ca
    ) 
    REFERENCES comunidad_autonoma 
    ( 
     PK_ca 
    ) 
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION 
GO

ALTER TABLE datos_counidades 
    ADD CONSTRAINT datos_counidades_Datos_comunidad_FK FOREIGN KEY 
    ( 
     Datos_comunidad_PK_datos
    ) 
    REFERENCES Datos_comunidad 
    ( 
     PK_datos 
    ) 
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION 
GO

ALTER TABLE Localidad_cp 
    ADD CONSTRAINT Localidad_cp_Municipio_FK FOREIGN KEY 
    ( 
     Municipio_PK_municipio, 
     Municipio_PK_provincia
    ) 
    REFERENCES Municipio 
    ( 
     PK_municipio , 
     Provincia_PK_provincia 
    ) 
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION 
GO

ALTER TABLE Municipio 
    ADD CONSTRAINT Municipio_Provincia_FK FOREIGN KEY 
    ( 
     Provincia_PK_provincia
    ) 
    REFERENCES Provincia 
    ( 
     PK_provincia 
    ) 
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION 
GO

ALTER TABLE Provincia 
    ADD CONSTRAINT Provincia_comunidad_autonoma_FK FOREIGN KEY 
    ( 
     comunidad_autonoma_PK_ca
    ) 
    REFERENCES comunidad_autonoma 
    ( 
     PK_ca 
    ) 
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION 
GO

ALTER TABLE Restricciones_actuales 
    ADD CONSTRAINT Restricciones_actuales_Fuentes_FK FOREIGN KEY 
    ( 
     Fuentes_PK_boletin
    ) 
    REFERENCES Fuentes 
    ( 
     PK_boletin 
    ) 
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION 
GO

ALTER TABLE restricciones_cp 
    ADD CONSTRAINT restricciones_cp_Localidad_cp_FK FOREIGN KEY 
    ( 
     Localidad_cp_PK_localidad, 
     Localidad_cp_Municipio_PK_provincia
    ) 
    REFERENCES Localidad_cp 
    ( 
     PK_localidad , 
     Municipio_PK_provincia 
    ) 
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION 
GO

ALTER TABLE restricciones_cp 
    ADD CONSTRAINT restricciones_cp_Restricciones_actuales_FK FOREIGN KEY 
    ( 
     Restricciones_actuales_PK_restric_espacios
    ) 
    REFERENCES Restricciones_actuales 
    ( 
     PK_restric_espacios 
    ) 
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION 
GO



-- Oracle SQL Developer Data Modeler Summary Report: 
-- 
-- CREATE TABLE                             9
-- CREATE INDEX                             0
-- ALTER TABLE                             25
-- CREATE VIEW                              0
-- ALTER VIEW                               0
-- CREATE PACKAGE                           0
-- CREATE PACKAGE BODY                      0
-- CREATE PROCEDURE                         0
-- CREATE FUNCTION                          0
-- CREATE TRIGGER                           0
-- ALTER TRIGGER                            0
-- CREATE DATABASE                          0
-- CREATE DEFAULT                           0
-- CREATE INDEX ON VIEW                     0
-- CREATE ROLLBACK SEGMENT                  0
-- CREATE ROLE                              0
-- CREATE RULE                              0
-- CREATE SCHEMA                            0
-- CREATE PARTITION FUNCTION                0
-- CREATE PARTITION SCHEME                  0
-- 
-- DROP DATABASE                            0
-- 
-- ERRORS                                   0
-- WARNINGS                                 0
