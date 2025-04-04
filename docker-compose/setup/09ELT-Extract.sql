-- ELT-Extraction
SET SERVEROUTPUT ON;
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- Create directory
CREATE OR REPLACE DIRECTORY dir_target 
AS '/tmp/2019';

-- Grant read permissions
GRANT READ ON DIRECTORY dir_target TO DW_SCHEMA;

-- alter dir
ALTER TABLE DW_SCHEMA.external_ridership
DEFAULT DIRECTORY dir_target;

-- confirm
SELECT COUNT(*) 
FROM DW_SCHEMA.external_ridership;

-- Truncate the staging table
TRUNCATE TABLE DW_SCHEMA.staging_trip;

-- Extract to Staging
INSERT /*+ APPEND */ INTO DW_SCHEMA.staging_trip
SELECT * FROM DW_SCHEMA.external_ridership;

COMMIT;

---- confirm
--SELECT *
--FROM DW_SCHEMA.staging_trip
--ORDER BY start_time;
