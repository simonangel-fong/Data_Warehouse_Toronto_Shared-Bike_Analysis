--access control
SET SERVEROUTPUT ON;
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- Create the DW_API role
CREATE ROLE DW_API;

-- Grant SELECT privileges on fact tables
GRANT SELECT ON DW_SCHEMA.fact_trip TO DW_API;

-- Grant SELECT privileges on dimension tables
GRANT SELECT ON DW_SCHEMA.dim_bike TO DW_API;
GRANT SELECT ON DW_SCHEMA.dim_station TO DW_API;
GRANT SELECT ON DW_SCHEMA.dim_time TO DW_API;
GRANT SELECT ON DW_SCHEMA.dim_user_type TO DW_API;

-- Grant SELECT privileges on materialized views
GRANT SELECT ON DW_SCHEMA.MV_TIME_TRIP TO DW_API;
GRANT SELECT ON DW_SCHEMA.MV_STATION_TRIP TO DW_API;
GRANT SELECT ON DW_SCHEMA.MV_STATION_ROUTE TO DW_API;
GRANT SELECT ON DW_SCHEMA.MV_BIKE_TRIP_DURATION TO DW_API;
GRANT SELECT ON DW_SCHEMA.MV_USER_SEGMENTATION TO DW_API;


-- Create the api_tester user with a password
CREATE USER api_tester IDENTIFIED BY "Welcome!234"  -- Replace with a secure password
--DEFAULT TABLESPACE USERS
DEFAULT TABLESPACE users
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON users;

-- Grant basic privileges to connect
GRANT CREATE SESSION TO api_tester;

-- Assign the DW_API role to api_tester
GRANT DW_API TO api_tester;

-- Optionally, set the role as default
ALTER USER api_tester DEFAULT ROLE DW_API;
