-- Create Tablespace for fact, dimension, and index.
ALTER SESSION SET CONTAINER=toronto_shared_bike;
show con_name
show user

-- Create FACT_TBSP tablespace for storing the fact table, specify block size as 32k.
CREATE TABLESPACE FACT_TBSP
DATAFILE 
    '/opt/oracle/oradata/ORCLCDB/fact_tbsp01.dbf' SIZE 100M AUTOEXTEND ON NEXT 1G MAXSIZE 50G
    , '/opt/oracle/oradata/ORCLCDB/fact_tbsp02.dbf' SIZE 100M AUTOEXTEND ON NEXT 1G MAXSIZE 50G
BLOCKSIZE 32K
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
SEGMENT SPACE MANAGEMENT AUTO
LOGGING
ONLINE;

-- Create DIM_TBSP for dimension table storage
CREATE TABLESPACE DIM_TBSP
DATAFILE 
    '/opt/oracle/oradata/ORCLCDB/toronto_shared_bike/dim_tbsp01.dbf' SIZE 50M AUTOEXTEND ON NEXT 25M MAXSIZE 5G
    , '/opt/oracle/oradata/ORCLCDB/toronto_shared_bike/dim_tbsp02.dbf' SIZE 50M AUTOEXTEND ON NEXT 25M MAXSIZE 5G
BLOCKSIZE 8K     
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
SEGMENT SPACE MANAGEMENT AUTO
LOGGING
ONLINE;  

-- Create INDEX_TBSP for index storage
CREATE TABLESPACE INDEX_TBSP
DATAFILE 
    '/opt/oracle/oradata/ORCLCDB/toronto_shared_bike/index_tbsp01.dbf' SIZE 50M AUTOEXTEND ON NEXT 25M MAXSIZE 5G
    , '/opt/oracle/oradata/ORCLCDB/toronto_shared_bike/index_tbsp02.dbf' SIZE 50M AUTOEXTEND ON NEXT 25M MAXSIZE 5G
BLOCKSIZE 8K 
EXTENT MANAGEMENT LOCAL AUTOALLOCATE 
SEGMENT SPACE MANAGEMENT AUTO 
LOGGING 
ONLINE; 
  
-- Create STAGE_TBSP for staging table storage
CREATE TABLESPACE STAGING_TBSP
DATAFILE 
    '/opt/oracle/oradata/ORCLCDB/toronto_shared_bike/stage01.dbf' SIZE 1G AUTOEXTEND ON NEXT 500M MAXSIZE 10G
    , '/opt/oracle/oradata/ORCLCDB/toronto_shared_bike/stage02.dbf' SIZE 1G AUTOEXTEND ON NEXT 500M MAXSIZE 10G
BLOCKSIZE 8K 
EXTENT MANAGEMENT LOCAL AUTOALLOCATE 
SEGMENT SPACE MANAGEMENT AUTO 
LOGGING 
ONLINE;

-- Create MV_TBSP tablespace
CREATE TABLESPACE MV_TBSP
DATAFILE 
    '/opt/oracle/oradata/ORCLCDB/toronto_shared_bike/MV_TBSP01.dbf' SIZE 100M AUTOEXTEND ON NEXT 50M MAXSIZE 2G
    , '/opt/oracle/oradata/ORCLCDB/toronto_shared_bike/MV_TBSP02.dbf' SIZE 100M AUTOEXTEND ON NEXT 50M MAXSIZE 2G
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

-- confirm
SELECT 
    tablespace_name
FROM DBA_tablespaces
WHERE tablespace_name LIKE '%_TBSP';
  