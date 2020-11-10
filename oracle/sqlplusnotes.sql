-- To connect open Cmd as administrator
-- >sqlplus
-- username:sys /as sysdba
-- pass: ********

-- comprobamos las conexiones dentro de oracle DB
SELECT name, con_id FROM v$pdbs;

-- the results are 2 databases
-- We select XEPDB1 with this command
ALTER SESSION SET CONTAINER = XEPDB1;

-- after changed the selected databas to use we select the opne modes

SELECT name, open_mode FROM v$pdbs;

-- after this command and after set this DB as container The DB is open
-- we can check anyway with this sentence
ALTER PLUGGABLE DATABASE open;

-- next time we will use those users:
-- >SYS
-- >HR
-- and another one -to connect to SQL server

-- (10/11/2020)
-- formato de columna para la terminal
COLUMN username format a25;

-- no está HR
SELECT username, account_status FROM dba_users;
/*
GGSYS                     EXPIRED & LOCKED
ANONYMOUS                 EXPIRED & LOCKED
HR                        EXPIRED & LOCKED
*/

ALTER user HR identified by HR account unlock;
-- deberia estar HR
SELECT username, account_status FROM dba_users;
/*
GGSYS                     EXPIRED & LOCKED
ANONYMOUS                 EXPIRED & LOCKED
HR                        OPEN
*/
