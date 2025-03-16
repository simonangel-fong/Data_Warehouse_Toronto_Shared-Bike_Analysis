-- Create Tablespace for fact, dimension, and index.
SET SERVEROUTPUT ON;
ALTER SESSION SET CONTAINER=toronto_shared_bike;

-- Create FACT_TBSP tablespace for storing the fact table, specify block size as 32k.
CREATE TABLESPACE FACT_TBSP
DATAFILE '/u02/oradata/CDB1/toronto_shared_bike/fact_tbsp01.dbf'
SIZE 100M                 -- Initial allocation
AUTOEXTEND ON NEXT 1G    -- Auto-extend in 1GB increments, reducing extend frequency for a growing fact table.
MAXSIZE 50G              -- Prevent excessive growth
BLOCKSIZE 32K            -- Optimized for data warehouse queries
EXTENT MANAGEMENT LOCAL AUTOALLOCATE  -- Efficient space allocation
SEGMENT SPACE MANAGEMENT AUTO  -- Automatic segment space management
LOGGING                -- Ensures data integrity with redo logging
ONLINE;                -- Makes the tablespace available immediately

-- Create DIM_TBSP for dimension table storage
CREATE TABLESPACE DIM_TBSP
  DATAFILE '/u02/oradata/CDB1/toronto_shared_bike/dim_tbsp01.dbf'
    SIZE 50M 
    AUTOEXTEND ON NEXT 25M
    MAXSIZE 5G     
  BLOCKSIZE 8K     
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE
  SEGMENT SPACE MANAGEMENT AUTO
  LOGGING
  ONLINE;  

-- Create INDEX_TBSP for index storage
CREATE TABLESPACE INDEX_TBSP
  DATAFILE '/u02/oradata/CDB1/toronto_shared_bike/index_tbsp01.dbf'
    SIZE 50M 
    AUTOEXTEND ON NEXT 25M 
    MAXSIZE 5G
  BLOCKSIZE 8K 
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE 
  SEGMENT SPACE MANAGEMENT AUTO 
  LOGGING 
  ONLINE; 
  
-- Create STAGE_TBSP for staging table storage
CREATE TABLESPACE STAGING_TBSP
  DATAFILE '/u02/oradata/CDB1/toronto_shared_bike/stage01.dbf'
  SIZE 1G AUTOEXTEND ON NEXT 500M MAXSIZE 10G
  ONLINE;

  