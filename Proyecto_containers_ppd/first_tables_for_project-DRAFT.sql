/*******

This is not a final script

********/

USE containers_1;
GO


CREATE TABLE container
    (
     id_contenedor INTEGER NOT NULL ,
     modelo VARCHAR (100) NOT NULL ,
     carga_max FLOAT NOT NULL ,
     mgw FLOAT ,
     tara FLOAT NOT NULL ,
     dimension_interna INTEGER NOT NULL
    )
GO





CREATE UNIQUE NONCLUSTERED INDEX
    container__IDX ON container
    (
     dimension_interna
    )
GO

ALTER TABLE container ADD CONSTRAINT container_PK PRIMARY KEY CLUSTERED (id_contenedor)
     WITH (
     ALLOW_PAGE_LOCKS = ON ,
     ALLOW_ROW_LOCKS = ON )
GO

CREATE TABLE dimension_ppd
    (
     id_dimension INTEGER NOT NULL ,
     ancho FLOAT ,
     altura FLOAT ,
     longitud FLOAT ,
     volumen FLOAT
    )
GO

ALTER TABLE dimension_ppd ADD CONSTRAINT dimension_ppd_PK PRIMARY KEY CLUSTERED (id_dimension)
     WITH (
     ALLOW_PAGE_LOCKS = ON ,
     ALLOW_ROW_LOCKS = ON )
GO

ALTER TABLE container
    ADD CONSTRAINT container_dimension_ppd_FK FOREIGN KEY
    (
     dimension_interna
    )
    REFERENCES dimension_ppd
    (
     id_dimension
    )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
GO
