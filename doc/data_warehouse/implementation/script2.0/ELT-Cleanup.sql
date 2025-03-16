-- Script to drop staging table
SET SERVEROUTPUT ON;
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- Drop staging table
DROP TABLE DW_SCHEMA.staging_trip;
-- Drop existing external table
DROP TABLE DW_SCHEMA.external_ridership;