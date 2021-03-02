USE [containers_ppd_test];
GO



/* Add data to estado containers*/
DELETE [Mgmt].[estado_cont_ppd];
GO
INSERT INTO [Mgmt].[estado_cont_ppd]
           ([peso_neto]
           ,[desc_estado])
     VALUES
       (3456,'Seminuevo con rayaduras exteriores'), --20' DRY VAN
		   (6500,'Un poco de corrosión en los laterales'), -- 40' DRY VAN
		   (10000,'Imperfecciones en la superficie de asiento'), -- 40' DRY VAN HIGH CUBE
		   (6800,'Seminuevo con rayaduras exteriores y falta lona cobertura'), --20' OPEN TOP
		   (4850,'Seminuevo con rayaduras exteriores, puertas sellado perfecto'),--20' PALLET WIDE (14 EUROPALETS)
		   (8500,'Seminuevo con rayaduras en plataforma'), --20' PALLET WIDE HIGH CUBE (14 EUROPALETS)
		   (3485,'Deterioro en puertas y platafroma'), -- 40' OPEN TOP
		   (9860,'Seminuevo con una puerta bloqueada'),--40' PALLET WIDE (30 EUROPALETS)
		   (12240,'Seminuevo con pintadas en el exterior'),--40' PALLET WIDE HIGH CUBE (30 EUROPALETS)
		   (8675,'pintadas en el exterior, puerta bloqueda y perforaciones en lateral');  --45' PALLET WIDE HIGH CUBE (33 EUROPALETS)

GO
SELECT * FROM  [Mgmt].[estado_cont_ppd];
GO


/* Add data to dimension containers*/
--DELETE [Mgmt].[dimension_ppd]
--GO


INSERT INTO [Mgmt].[dimension_ppd]
           ([dim_desc] ,[ancho] ,[longitud] ,[altura] ,[volumen])
     VALUES
           ('Dimensiones internas DRY VAN',2352 ,5898,2393,33.20),
           ('Dimensiones externas DRY VAN',2438 ,6058,2591, null),
           ('Dimensiones puertas DRY VAN',2340 ,2280,null,null),
           ('Dimensiones internas OPEN TOP',2352 ,5940,2360,33.20),
           ('Dimensiones externas OPEN TOP',2484 ,6058,2591,null),
           ('Dimensiones puertas OPEN TOP',2340 ,2280,null,null),
           ('Dimensiones internas PALLET WIDE',2426 ,5898,2591,38.60),
           ('Dimensiones externas PALLET WIDE',2484 ,6058,2591,null),
           ('Dimensiones puertas PALLET WIDE',2374 ,2585,null,null),
           ('Dimensiones internas PALLET WIDE HIGH CUBE',2426 ,5898,2712,36.60),
           ('Dimensiones externas PALLET WIDE HIGH CUBE',2484 ,6058,2896,null),
           ('Dimensiones puertas PALLET WIDE HIGH CUBE',2374 ,2585,null,null),
		   ('Dimensiones internas 40 DRY VAN',2352 ,12032,2393,67.70),
           ('Dimensiones externas 40 DRY VAN',2438 ,12192,2591, null),
           ('Dimensiones puertas 40 DRY VAN',2340 ,2280,null,null),
		   ('Dimensiones internas 40 DRY VAN HIGH CUBE',2352 ,12064,2692,57.41),
           ('Dimensiones externas 40 DRY VAN HIGH CUBE',2438 ,12192,2896, null),
           ('Dimensiones puertas 40 DRY VAN HIGH CUBE',2340 ,2280,null,null),
		   ('Dimensiones internas 40 PALLET WIDE',2426 ,12100,2383,79.10),
           ('Dimensiones externas 40 PALLET WIDE',2484 ,12192,2591, null),
           ('Dimensiones puertas 40 PALLET WIDE',2360 ,2280,null,null),
		   ('Dimensiones internas 40 PALLET WIDE HIGH CUBE',2352 ,12100,2694,79.10),
           ('Dimensiones externas 40 PALLET WIDE HIGH CUBE',2438 ,12192,2896, null),
           ('Dimensiones puertas 40 PALLET WIDE HIGH CUBE',2340 ,2280,null,null)
GO

SELECT * FROM [Mgmt].[dimension_ppd];
GO

--DELETE [Mgmt].[[modelo_cont_ppd]]
--GO

/* no image yet*/
INSERT INTO [dbo].[modelo_cont_ppd]
           ([modelo]
           ,[carga_max]
           ,[mgw]
           ,[tara]
           ,[dimension_ppd_id_dimension]
           ,[dimension_ppd_id_dimension2]
           ,[dimension_ppd_id_dimension3])
     VALUES
		('20 FEET DRY VAN',28260,30480,2200,1000,1001,1002)
		,('20 FEET OPEN TOP',2400,27120,3120,1003,1004,1005)
		,('20 FEET PALLET WIDE',27990,30480,2490,1006,1007,1008)
		,('20 FEET PALLET WIDE HIGH CUBE',27990,30480,2490,1009,1010,1011)
		,('40 FEET DRY VAN',28650,32500,3850,1012,1013,1014)
		,('40 FEET DRY VAN HIGH CUBE',29870,35000,5130,1015,1016,1017)
		,('40 FEET PALLET WIDE',29850,34000,4150,1018,1019,1020)
		,('40 FEET PALLET WIDE HIGH CUBE',29850,34000,4150,1021,1022,1023)
GO



USE [containers_ppd_test]
GO

INSERT INTO [Mgmt].[contenedor_ppd]
           ([nserie] --347965
           ,[digitoctrl] --0
           ,[modelo_cont_ppd_id_modelo] --1001
           ,[estado_cont_ppd_id_estado] --1001
		   )
     VALUES
           ('347965',0,1000,1)
           ,('367905',1,1001,2)
           ,('245605',0,1006,3)
           ,('367905',1,1001,4)
           ,('135905',1,1001,5)
           ,('198975',1,1007,6)
           ,('534853',1,1004,7)
           ,('862342',1,1001,8)
           ,('23900875',1,1002,9)
           ,('213489',1,1006,10)
GO
