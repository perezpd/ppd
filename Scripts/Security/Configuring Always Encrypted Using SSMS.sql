
-- Configuring Always Encrypted Using SSMS
-- http://codingsight.devart.local/understanding-sql-server-always-encrypted/
-------------------------------

--Security is one of the most important requirements for a data-driven system. Encryption is one of the ways to secure the data. Wikipedia defines encryption as:

--“Encryption is the process of encoding a message or information in such a way that only authorized parties can access it and those who are not authorized cannot.”

--In SQL Server 2016, Microsoft introduced an encryption feature called Always Encrypted. In this article, we will see what Always Encrypted is, and how it can be used to encrypt and decrypt data, with the help of simple examples.


-- What is SQL Server Always Encrypted?

-- Always Encrypted is a security feature that allows the client application to manage the encryption 
-- and decryption keys, thus ensuring that only the client application can decrypt and use sensitive data.

--Several encryption techniques exist, however they are not as secure as Always Encrypted. 
-- For instance, symmetric key encryption is used to encrypt data on the database side. 
-- A drawback of this approach is that if any other database administrator has the decryption key, 
-- he can access the data.

-- On the other hand, in case of Always Encrypted, the data is encrypted on the client side and the database server 
-- receives a ciphered version of the data. 
-- Hence, the data cannot be deciphered at the database end. Only the client that encrypted the data can decrypt it.

--Key Types

--SQL Server Always Encrypted feature uses two types of keys:

--Column Encryption Key (CEK)

--It is always placed on the database server. The data is actually encrypted using column CEK. 
-- However, if someone on the database side has access to CEK, he can decrypt the data.

-- Column Master Key (CMK)

--This key is placed on the client side or any third party storage. 
-- CMK is used to protect the CEK, adding an additional layer of security. 
-- Whoever has access to CMK can actually decrypt the CEK which can then be used to decipher the actual data.

--Encryption Types

--Deterministic

--This type of encryption will always generate similar encrypted text for the same type of data. 
-- If you want to implement searching and grouping on a table column, use deterministic encryption for that column.

--Randomized

--Randomized Encryption will generate different encrypted text for the same type of data, 
-- whenever you try to encrypt the data. Use randomized encryption if the column is not used for grouping and searching.


----------------------------------------------

DROP DATABASE IF EXISTS School
GO
CREATE DATABASE School
GO
Use School
GO
DROP TABLE IF EXISTS Student
GO
CREATE TABLE Student  
(  
   StudentId int identity(1,1) primary key,  
   Name varchar(100),  
   Password varchar(100) COLLATE Latin1_General_BIN2 not null,  
   SSN varchar(20)  COLLATE Latin1_General_BIN2 not null
)
GO

insert into Student ( Name, Password, SSN)
VALUES ('John','abc123', '451236521478'),
		('Mike','xyz123', '789541239654')
GO

SELECT * FROM Student
GO

--Let’s now configure SSMS for to enable Always Encrypted. 
--As we said earlier, Always Encrypted creates column encryption keys and 
-- column master keys.

-- PASO 1  
-- Ver SECURITY -> ALWAYS ENCRYPTED KEYS          EMPTY

--To see the existing column encryption keys and column master keys, 
-- for the School Database, go to Databases -> School -> Security -> Always Encrypted Keys as shown in the following figure:

--Since you don’t have any encrypted record in the dataset, you won’t see any CEK or CMK in the list.

-- VACIAS

-- COLUMN MASTER KEYS
-- COLUMN ENCRYPTION KEYS

--

--Let’s now enable encryption on the Password and SSN columns of the Student table. 
-- PASO 2
-- To do so, Right Click on Databases -> School. 
-- From the dropdown menu, select 
				-- Encrypt Columns 
-- APARECE WIZARD

-- Click Next button on the Introduction window. 

-- From the Column Selection window, check Password and SSN columns.

-- For the Password column, select the encryption type as		Randomized. 

-- For      SSN column, choose			Deterministic. 


-- EN EL ASISTENTE (WIZARD) TODO SIGUIENTE

-- COMPROBACIÓN

SELECT * FROM Student
go

--StudentId	Name	Password	SSN
--1	John	0x01EAFA3AD5BFFD3A84566B0E4ED9636159E26B98BC636868F5A0836AA4E0F52B092515D5FA8D8CA7CEC0F5416764A70403E0DD1496AC12835F64594D10E8BEE1A6	0x01370D20F1B80B67A919A548B20B928E9699B526AD3F4F75074AAD461862EEEC5C425823C712CCC5D4EF781DB23ED0446D8146F2A75D93840D0A9488785D5209EF
--2	Mike	0x01ACB0780C3C0569DBC54E14E085DF8EEFB42DF71CDEDA2449DF01FEEC0C094B0A815E077C3EDEED70A69B26893392C2378CE62C4A956269BD2B4A9C9029C7E9F7	0x015BA6D56346C3CCABBCF19120D693A1B2CC2C7827388CD50A9BCDD420ADD6C8AFC903D5FDE9537745DFD4A5DE99B343554534122DC623A9579B7FFD9C047E5F70

-- Password	SSN ENCRIPTADOS


--Retrieving Decrypted Data
--The SELECT query returned encrypted data. 


--What if you want to retrieve data in decrypted form? 


-- PASO 3

-- To do so create a New Query Window in SSMS 
-- and then click the Change Connection icon 
-- at the top of Object Explorer 

-- From the window that appears, click on 

--			Additional Connection Parameters tab 

-- from the top left and enter

--			“Column Encryption Setting = Enabled” 

-- in the text box as shown in the following screenshot. 

-- Finally, click the Connect button.

-- Column Encryption Setting = Enabled

USE [School]
GO
SELECT * FROM Student
go

-- NOTA:
-- DESDE T-SQL NO DESENCRIPTA

-- USO SSMS
-- ACEPTO PANTALLA DE PARAMETRIZACIÓN


--StudentId	Name	Password		SSN
--1			John	abc123		451236521478
--2			Mike	xyz123		789541239654





