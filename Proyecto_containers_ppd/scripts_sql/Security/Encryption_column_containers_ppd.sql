/* OWNER PEREZ PONTE DIEGO*/

/*********************************************************************************************/
/*******************************     ENCRYPTION        ***************************************/
/******************** Encrypt column using certificate and master key ************************/
/*******************    TEST SELECTING THE TABLE by another user    **************************/
/*********************************************************************************************/
use master
go
-- 20/04/2021
-- ======= SECURE the column Nserie from containers db with encryption ========
USE [containers_ppd_test];
GO

--Check data in teh original table
SELECT TOP 5 * FROM [Mgmt].[contenedor_ppd];
--id_contenedor	nserie	digitoctrl	modelo_cont_ppd_id_modelo	estado_cont_ppd_id_estado
--1000			347965	0			1000						1
--1001			367905	1			1001						2
--1002			245605	0			1006						3
--1003			367905	1			1001						4
--1004			135905	1			1001						5

-- create a new table for this example
SELECT TOP 5 * INTO containers_to_encrypt_ppd 
FROM [Mgmt].[contenedor_ppd];
GO

--(5 rows affected)
SELECT count(*) as rows FROM containers_to_encrypt_ppd 
-- rows 
-- 5

