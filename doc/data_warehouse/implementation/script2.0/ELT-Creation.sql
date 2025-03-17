-- ELT-Extraction
SET SERVEROUTPUT ON;
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- Create directory
CREATE OR REPLACE DIRECTORY dir_2019 
AS '/data/toronto_shared_bike/2019';

-- Grant read permissions
GRANT READ ON DIRECTORY dir_2019 TO DW_SCHEMA;

-- Create the external table ext_ridership
CREATE TABLE DW_SCHEMA.external_ridership (
    trip_id                 VARCHAR2(15)
    , trip_duration         VARCHAR2(15)
    , start_time            VARCHAR2(50)
    , start_station_id      VARCHAR2(15)
    , start_station_name    VARCHAR2(100)
    , end_time              VARCHAR2(50)
    , end_station_id        VARCHAR2(15)
    , end_station_name      VARCHAR2(100)
    , bike_id               VARCHAR2(15)
    , user_type             VARCHAR2(50)
    , model                 VARCHAR2(50)
)
ORGANIZATION EXTERNAL (
    TYPE ORACLE_LOADER
    DEFAULT DIRECTORY dir_2019
    ACCESS PARAMETERS (
        RECORDS DELIMITED BY NEWLINE SKIP 1
        FIELDS TERMINATED BY ','
        OPTIONALLY ENCLOSED BY '"'
        MISSING FIELD VALUES ARE NULL
        (
            trip_id
            , trip_duration
            , start_station_id
            , start_time CHAR(50)
            , start_station_name
            , end_station_id
            , end_time CHAR(50)
            , end_station_name
            , bike_id
            , user_type
            , model
        )
    )
    LOCATION ('Ridership*.csv')
)
parallel 5
REJECT LIMIT UNLIMITED;

ALTER USER DW_SCHEMA QUOTA UNLIMITED ON STAGING_TBSP;

-- Create staging table (run as DW_SCHEMA)
CREATE TABLE DW_SCHEMA.staging_trip (
  trip_id               VARCHAR2(15)
  , trip_duration       VARCHAR2(15)
  , start_time          VARCHAR2(50)
  , start_station_id    VARCHAR2(15)
  , start_station_name  VARCHAR2(100)
  , end_time            VARCHAR2(50)
  , end_station_id      VARCHAR2(15)
  , end_station_name    VARCHAR2(100)
  , bike_id             VARCHAR2(15)
  , user_type           VARCHAR2(50)
  , model               VARCHAR2(50)
)
TABLESPACE STAGING_TBSP
NOLOGGING
PCTFREE 0;