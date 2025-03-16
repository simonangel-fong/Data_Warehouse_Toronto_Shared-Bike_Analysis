-- Create PDB for Data Warehouse
SET SERVEROUTPUT ON;
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- Create pdb
CREATE PLUGGABLE DATABASE toronto_shared_bike
  ADMIN USER pdb_admin IDENTIFIED BY PDBSecurePassword123
  ROLES = (DBA)
  FILE_NAME_CONVERT = (
    '/u02/oradata/CDB1/pdbseed/',
    '/u02/oradata/CDB1/toronto_shared_bike/');

ALTER PLUGGABLE DATABASE toronto_shared_bike OPEN;
ALTER PLUGGABLE DATABASE toronto_shared_bike SAVE STATE;

SHOW PDBS;