-- ELT-Extraction
SET SERVEROUTPUT ON;
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- Create directory
CREATE OR REPLACE DIRECTORY dir_target 
--AS '/data/toronto_shared_bike/2021';
AS '/tmp/2023';

-- Grant read permissions
GRANT READ ON DIRECTORY dir_target TO DW_SCHEMA;

-- alter dir
ALTER TABLE DW_SCHEMA.external_ridership
DEFAULT DIRECTORY dir_target;

-- confirm
SELECT *
FROM DW_SCHEMA.external_ridership
WHERE ROWNUM < 10;

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
