/*     CREATE NEW USER with its roles, tablespace and connection*/
SELECT name, open_mode FROM v$pdbs;//
-- We select XEPDB1 with this command
ALTER SESSION SET CONTAINER = XEPDB1;

select name, open_mode FROM v$pdbs;

/*NAME
--------------------------------------------------------------------------------
OPEN_MODE
----------
XEPDB1
READ WRITE*/
-- crear espacio de tabla
CREATE SMALLFILE TABLESPACE SAMPLETAB DATAFILE 'C:\OracleXE18c\oradata\XE\XEPDB1\SAMPLETAB.DBF'
SIZE 200M LOGGING EXTENT MANAGEMENT LOCAL SEGMENT SPACE MANAGEMENT AUTO;
-- Tablespace created.


-- crear usuario con el espacio de tabla anterior
CREATE USER PPD PROFILE DEFAULT IDENTIFIED BY oracle DEFAULT tablespace SAMPLETAB
TEMPORARY TABLESPACE TEMP ACCOUNT UNLOCK quota unlimited on SAMPLETAB;
-- User created.
-- pass oracle 


GRANT CONNECT TO PPD;
-- Grant succeeded.
GRANT RESOURCE TO PPD;
-- Grant succeeded.

GRANT INSERT ANY TABLE TO PPD;
-- Grant succeeded.


-- NOS MOVEMOS A NUESTRO SCHEMA
ALTER SESSION SET CURRENT_SCHEMA = PPD;
-- Session altered.

-- nos conectamos como PPD
conn PPD/oracle@//localhost:1521/xepdb1
show user;
select table_name from user_tables;

/* -- RESULTS
SQL> conn PPD/oracle@//localhost:1521/xepdb1
Connected.
SQL> show user;
USER is "PPD"
SQL> select table_name from user_tables;

no rows selected

SQL>
*/
