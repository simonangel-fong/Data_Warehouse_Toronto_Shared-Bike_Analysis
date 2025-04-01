-- Create PDB for Data Warehouse
SET SERVEROUTPUT ON;
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- Create pdb
CREATE PLUGGABLE DATABASE toronto_shared_bike 
    ADMIN USER pdb_adm IDENTIFIED BY PDBSecurePassword123
    ROLES = (DBA)
    DEFAULT TABLESPACE users 
    DATAFILE 
--        '/u02/oradata/CDB1/toronto_shared_bike/users01.dbf' SIZE 1M AUTOEXTEND ON NEXT 1M, 
--        '/u02/oradata/CDB1/toronto_shared_bike/users02.dbf' SIZE 1M AUTOEXTEND ON NEXT 1M
        '/opt/oracle/oradata/ORCLCDB/toronto_shared_bike/users01.dbf' SIZE 1M AUTOEXTEND ON NEXT 1M
        , '/opt/oracle/oradata/ORCLCDB/toronto_shared_bike/users02.dbf' SIZE 1M AUTOEXTEND ON NEXT 1M
    FILE_NAME_CONVERT=(
--        '/u02/oradata/CDB1/pdbseed/'
--        ,'/u02/oradata/CDB1/toronto_shared_bike/');
        '/opt/oracle/oradata/ORCLCDB/pdbseed'
        ,'/opt/oracle/oradata/ORCLCDB/toronto_shared_bike/');



ALTER PLUGGABLE DATABASE toronto_shared_bike OPEN;
ALTER PLUGGABLE DATABASE toronto_shared_bike SAVE STATE;

SHOW PDBS;


