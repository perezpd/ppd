-- Inicio Encriptar una columna 

USE [master]
GO
CREATE LOGIN BankManagerLogin WITH PASSWORD='abcd1234.'
GO
CREATE DATABASE MiBanco
GO
USE MiBanco
GO
CREATE USER BankManagerUser FOR LOGIN BankManagerLogin
GO
CREATE TABLE Customers
	(customer_id INT PRIMARY KEY,
	first_name varchar(50) NOT NULL,
	last_name varchar(50) NOT NULL,
	social_security_number varbinary(100) NOT NULL)
GO
GRANT SELECT, INSERT, UPDATE, DELETE ON Customers TO BankManagerUser
GO
CREATE SYMMETRIC KEY BankManager_User_Key
AUTHORIZATION BankManagerUser
WITH ALGORITHM=AES_256 
ENCRYPTION BY PASSWORD='abcd1234.'
GO
EXECUTE AS USER='BankManagerUser'
GO
OPEN SYMMETRIC KEY [BankManager_User_Key] DECRYPTION BY PASSWORD='abcd1234.'
GO
INSERT INTO Customers VALUES (1,'Howard','Stern',
EncryptByKey(Key_GUID('BankManager_User_Key'),'042-32-1324'))
INSERT INTO Customers VALUES (2,'Donald','Trump',
EncryptByKey(Key_GUID('BankManager_User_Key'),'035-13-6564'))
INSERT INTO Customers VALUES (3,'Bill','Gates',
EncryptByKey(Key_GUID('BankManager_User_Key'),'533-13-5784'))
GO
-- Comprobar Encriptado
select * from dbo.Customers
go

-- Resultados

--customer_id	first_name	last_name	social_security_number
--1	Howard	Stern	0x0059FB12933E0040B8D7BEE21562886601000000E5F0AB62B6AF9320994029D7D290D4B4A649E7BB9CCFEC558854D88F1464B728
--2	Donald	Trump	0x0059FB12933E0040B8D7BEE21562886601000000F43686C69F2F636D6DE225774DEF99A000D40C13538479E41EBAA5D0BE9863B3
--3	Bill	Gates	0x0059FB12933E0040B8D7BEE21562886601000000C8EEE60368DD73A7B083B0B1F0447F276FD2CA97A00EDE6791912C5EDD34D15B

CLOSE ALL SYMMETRIC KEYS
GO

-- Vamos a Desencriptar

OPEN SYMMETRIC KEY [BankManager_User_Key] DECRYPTION BY PASSWORD='abcd1234.'
GO

SELECT customer_id,first_name + ' ' + last_name AS [Nombre Cliente],
CONVERT(VARCHAR,DecryptByKey(social_security_number)) as 'Número Seguridad Social'
FROM Customers
GO

-- Resultados despues de Desencriptar

--customer_id	Name	Social Security Number
--1	Howard Stern	042-32-1324
--2	Donald Trump	035-13-6564
--3	Bill Gates	533-13-5784

CLOSE ALL SYMMETRIC KEYS
GO
REVERT
GO
USE master
DROP DATABASE MiBanco
GO

-- Fin Encriptar una columna 