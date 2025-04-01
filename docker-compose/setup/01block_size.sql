-- At the CDB Level, enable 32k block size for fact tablespace.
-- start with cdb
SET SERVEROUTPUT ON;
ALTER SESSION SET CONTAINER = CDB$ROOT;

ALTER SYSTEM SET DB_32K_CACHE_SIZE = 256M SCOPE = SPFILE;

SHUTDOWN IMMEDIATE;
STARTUP;

SHOW PARAMETER db_32k_cache_size;
