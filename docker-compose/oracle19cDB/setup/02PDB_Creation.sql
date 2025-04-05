-- Create PDB for Data Warehouse
SET SERVEROUTPUT ON;
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- Create pdb
CREATE PLUGGABLE DATABASE toronto_shared_bike 
    ADMIN USER pdb_adm IDENTIFIED BY PDBSecurePassword123
    ROLES = (DBA)
    DEFAULT TABLESPACE users 
    DATAFILE 
        '/opt/oracle/oradata/ORCLCDB/toronto_shared_bike/users01.dbf' SIZE 1M AUTOEXTEND ON NEXT 1M
    FILE_NAME_CONVERT=(
        '/opt/oracle/oradata/ORCLCDB/pdbseed'
        ,'/opt/oracle/oradata/ORCLCDB/toronto_shared_bike/');



ALTER PLUGGABLE DATABASE toronto_shared_bike OPEN;
ALTER PLUGGABLE DATABASE toronto_shared_bike SAVE STATE;

SHOW PDBS;


