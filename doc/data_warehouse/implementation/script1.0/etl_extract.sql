-- SQL script to extract data from flat files to staging table.
-- User = dba, container = root

SET SERVEROUTPUT ON;
ALTER SESSION SET container=toronto_shared_bike;
show con_name;
show user;

----CREATE OR REPLACE DIRECTORY load_dir AS '/home/oracle/toronto_shared_bike/load';
--CREATE OR REPLACE DIRECTORY load_dir AS '/home/oracle/data/2019';
--GRANT READ, WRITE ON DIRECTORY load_dir TO app_admin;

-- Creation of external table
CREATE TABLE app_admin.external_ridership (
    trip_id VARCHAR2(15),
    trip_duration VARCHAR2(15),
    start_station_id VARCHAR2(15),
    start_time VARCHAR2(20),
    start_station_name VARCHAR2(100),
    end_station_id VARCHAR2(15),
    end_time VARCHAR2(20),
    end_station_name VARCHAR2(100),
    bike_id VARCHAR2(15),
    user_type VARCHAR2(50)
)
ORGANIZATION EXTERNAL (
    TYPE ORACLE_LOADER
    DEFAULT DIRECTORY load_dir
    ACCESS PARAMETERS (
        RECORDS DELIMITED BY NEWLINE SKIP 1
        FIELDS TERMINATED BY ','
        OPTIONALLY ENCLOSED BY '"'
        MISSING FIELD VALUES ARE NULL
        (
            trip_id,
            trip_duration,
            start_station_id,
            start_time CHAR(50),
            start_station_name,
            end_station_id,
            end_time CHAR(50),
            end_station_name,
            bike_id,
            user_type
        )
    )
    LOCATION ('*.csv')
)
--parallel 5
REJECT LIMIT UNLIMITED;

-- Creation of staging table for extraction
CREATE TABLE app_admin.staging_ridership (
    trip_id VARCHAR2(15),
    trip_duration VARCHAR2(15),
    start_station_id VARCHAR2(15),
    start_time VARCHAR2(50),
    start_station_name VARCHAR2(100),
    end_station_id VARCHAR2(15),
    end_time VARCHAR2(50),
    end_station_name VARCHAR2(100),
    bike_id VARCHAR2(15),
    user_type VARCHAR2(50)
);

-------- Load data from source tb to stagging table --------
INSERT INTO app_admin.staging_ridership (
    trip_id,
    trip_duration,
    start_station_id,
    start_time,
    start_station_name,
    end_station_id,
    end_time,
    end_station_name,
    bike_id,
    user_type
)
SELECT 
    trip_id,
    trip_duration,
    start_station_id,
    start_time,
    start_station_name,
    end_station_id,
    end_time,
    end_station_name,
    bike_id,
    user_type
FROM app_admin.external_ridership;

COMMIT;
