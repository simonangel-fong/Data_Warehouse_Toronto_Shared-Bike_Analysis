-- SQL script to create PDB, user
-- User = dba, container = root

set serveroutput on;
ALTER SESSION set container=cdb$root;

CREATE PLUGGABLE DATABASE toronto_shared_bike
ADMIN USER pdb_admin IDENTIFIED BY welcome
ROLES=(DBA) DEFAULT TABLESPACE users
DATAFILE '/u01/app/oracle/oradata/ORCL/toronto_shared_bike/users01.dbf'
SIZE 1M AUTOEXTEND ON NEXT 1M
FILE_NAME_CONVERT=(
    '/u01/app/oracle/oradata/ORCL/pdbseed/', 
    '/u01/app/oracle/oradata/ORCL/toronto_shared_bike/');
        
ALTER PLUGGABLE DATABASE toronto_shared_bike OPEN;
ALTER PLUGGABLE DATABASE toronto_shared_bike SAVE STATE;

ALTER SESSION SET container=toronto_shared_bike;

CREATE USER app_admin IDENTIFIED BY welcome
DEFAULT TABLESPACE users
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON users;

GRANT CONNECT, RESOURCE TO app_admin;
