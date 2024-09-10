-- SQL script to clean up PDB
-- User = dba, container = root

set serveroutput on;
ALTER SESSION set container=cdb$root;
        
ALTER PLUGGABLE DATABASE toronto_shared_bike CLOSE IMMEDIATE;
DROP PLUGGABLE DATABASE toronto_shared_bike INCLUDING DATAFILES;
