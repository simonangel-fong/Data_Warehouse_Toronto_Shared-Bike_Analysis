# Toronto Bike Share Data Warehouse Documentation - ELT Pipeline Implementation

[Back](../../../../README.md)

- [Toronto Bike Share Data Warehouse Documentation - ELT Pipeline Implementation](#toronto-bike-share-data-warehouse-documentation---elt-pipeline-implementation)
  - [ELT Pipeline Implementation](#elt-pipeline-implementation)
  - [Upload Flat Files](#upload-flat-files)
  - [Extraction](#extraction)
  - [Transform](#transform)
  - [Load](#load)

---

## ELT Pipeline Implementation

## Upload Flat Files

```sh
scp -r local_path/data homeadmin@192.168.128.50:~

# login as root
mkdir -pv /data/toronto_shared_bike
mv -v /home/homeadmin/data/* /data/toronto_shared_bike
# change ownership; otherwise external table cannot load the data
chown -R oracle:oinstall /data
ll /data/toronto_shared_bike/
# total 20
# drwx------. 2 homeadmin homeadmin  122 Mar  9 19:03 2019
# drwx------. 2 homeadmin homeadmin 4096 Mar  9 19:03 2020
# drwx------. 2 homeadmin homeadmin 4096 Mar  9 19:03 2021
# drwx------. 2 homeadmin homeadmin 4096 Mar  9 19:03 2022
# drwx------. 2 homeadmin homeadmin 4096 Mar  9 19:03 2023
# drwx------. 2 homeadmin homeadmin 4096 Mar  9 19:04 2024
```

---

## Extraction

```sql
ALTER SESSION set container=toronto_shared_bike;
-- Create directory
CREATE OR REPLACE DIRECTORY dir_share_bike_2019
AS '/data/toronto_shared_bike/2019/';

-- Grant read permissions
GRANT READ ON DIRECTORY dir_2019 TO DW_SCHEMA;

-- Drop existing external table
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE DW_SCHEMA.external_ridership';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

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


SELECT *
FROM DW_SCHEMA.external_ridership;
```

- Load to staging table

```sql
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- Create STAGE_TBSP for staging table storage
CREATE TABLESPACE STAGING_TBSP
  DATAFILE '/u02/oradata/CDB1/toronto_shared_bike/stage01.dbf'
  SIZE 1G AUTOEXTEND ON NEXT 500M MAXSIZE 10G
  ONLINE;

-- grant quota
ALTER USER DW_SCHEMA QUOTA UNLIMITED ON STAGING_TBSP;

-- Drop staging table
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE DW_SCHEMA.staging_trip';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

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
NOLOGGING       -- Reduces redo logging—speeds up bulk INSERT
PCTFREE 0;      -- Minimizes space waste—staging data is write-once, rarely updated

-- Extract to Staging
INSERT /*+ APPEND */ INTO DW_SCHEMA.staging_trip
SELECT * FROM DW_SCHEMA.external_ridership;

COMMIT;

SELECT *
FROM DW_SCHEMA.staging_trip;

```

## Transform

```sql
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- REMOVE_NULL_KEYCOL
DELETE FROM DW_SCHEMA.staging_trip
WHERE trip_id IS NULL
OR trip_duration IS NULL
OR start_time IS NULL
OR start_station_id IS NULL
OR end_station_id IS NULL;

COMMIT;

-- REMOVE_VALID_TYPE
DELETE FROM DW_SCHEMA.staging_trip
WHERE
  -- Confirm trip_id to NUMBER(10)
  NOT REGEXP_LIKE(trip_id, '^[0-9]+$')
  -- Confirm trip_duration to NUMBER(8)
  OR NOT REGEXP_LIKE(trip_duration, '^[0-9]+(\.[0-9]+)?$')
  -- Confirm start_time to the standard format
  OR NOT REGEXP_LIKE(start_time, '^[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}$')
  -- Confirm start_time to date type
  OR TO_DATE(start_time, 'MM/DD/YYYY HH24:MI', 'NLS_DATE_LANGUAGE = AMERICAN') IS NULL
  -- Confirm start_station_id to NUMBER(6)
  OR NOT REGEXP_LIKE(start_station_id, '^[0-9]+$')
  -- Confirm end_station_id to NUMBER(6)
  OR NOT REGEXP_LIKE(end_station_id, '^[0-9]+$')
;

COMMIT;

-- REMOVE_INVALID_DURATION
DELETE FROM DW_SCHEMA.staging_trip
WHERE TO_NUMBER(trip_duration) <= 0;

COMMIT;

------ Non-Critical Columns
-- SUB_ENDTIME
UPDATE DW_SCHEMA.staging_trip
SET end_time = TO_CHAR(
  TO_DATE(start_time, 'MM/DD/YYYY HH24:MI') + (TO_NUMBER(trip_duration) / 86400), 'MM/DD/YYYY HH24:MI'
)
WHERE
    end_time IS NULL
OR
    (NOT REGEXP_LIKE(end_time, '^[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}$')
    OR TO_DATE(end_time, 'MM/DD/YYYY HH24:MI', 'NLS_DATE_LANGUAGE = AMERICAN') IS NULL)
;

COMMIT;

-- SUB_STATIONNAME
UPDATE DW_SCHEMA.staging_trip
SET start_station_name = 'UNKNOWN',
    end_station_name = 'UNKNOWN'
WHERE
  start_station_name IS NULL
  OR end_station_name IS NULL;

COMMIT;

-- SUB_USERTYPE
UPDATE DW_SCHEMA.staging_trip
SET user_type = 'UNKNOWN'
WHERE user_type IS NULL;

COMMIT;

-- SUB_BIKEID
UPDATE DW_SCHEMA.staging_trip
SET bike_id = '-1'
WHERE bike_id IS NULL
OR (NOT REGEXP_LIKE(bike_id, '^[0-9]+$') AND bike_id != '-1');

COMMIT;

-- SUB_BIKEMODEL
UPDATE DW_SCHEMA.staging_trip
SET model = 'UNKNOWN'
WHERE model IS NULL;

COMMIT;
```

---

## Load

```sql
-- Set PDB context
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- Merge into dim_time
MERGE /*+ APPEND */ INTO DW_SCHEMA.dim_time tgt
USING (
  -- Union start_time and end_time to capture all timestamps
  SELECT DISTINCT
    TO_DATE(time_value, 'MM/DD/YYYY HH24:MI') AS timestamp_value
  FROM (
    SELECT start_time AS time_value FROM DW_SCHEMA.staging_trip
    UNION
    SELECT end_time AS time_value FROM DW_SCHEMA.staging_trip
    WHERE end_time IS NOT NULL
  )
) src
ON (tgt.dim_time_timestamp = src.timestamp_value)
WHEN NOT MATCHED THEN
  INSERT (
    dim_time_id,
    dim_time_timestamp,
    dim_time_year,
    dim_time_quarter,
    dim_time_month,
    dim_time_day,
    dim_time_week,
    dim_time_weekday,
    dim_time_hour,
    dim_time_minute
  )
  VALUES (
    TO_NUMBER(TO_CHAR(src.timestamp_value, 'YYYYMMDDHH24MI')), -- YYYYMMDDHHMI
    src.timestamp_value,                                       -- DATE
    TO_NUMBER(TO_CHAR(src.timestamp_value, 'YYYY')),           -- Year
    TO_NUMBER(TO_CHAR(src.timestamp_value, 'Q')),              -- Quarter (1-4)
    TO_NUMBER(TO_CHAR(src.timestamp_value, 'MM')),             -- Month (1-12)
    TO_NUMBER(TO_CHAR(src.timestamp_value, 'DD')),             -- Day (1-31)
    TO_NUMBER(TO_CHAR(src.timestamp_value, 'IW')),             -- ISO Week (1-53)
    TO_NUMBER(TO_CHAR(src.timestamp_value, 'D')),              -- Weekday (1-7, Sunday=1)
    TO_NUMBER(TO_CHAR(src.timestamp_value, 'HH24')),           -- Hour (0-23)
    TO_NUMBER(TO_CHAR(src.timestamp_value, 'MI'))              -- Minute (0-59)
  );

COMMIT;

-- Merge into dim_station
MERGE /*+ APPEND */ INTO DW_SCHEMA.dim_station tgt
USING (
  -- Combine start and end stations, prioritize latest name by row order (assuming staging_trip reflects latest data)
  SELECT 
    TO_NUMBER(station_id) AS station_id,
    station_name
  FROM (
    SELECT start_station_id AS station_id, start_station_name AS station_name
    FROM DW_SCHEMA.staging_trip
    WHERE start_station_id IS NOT NULL
    UNION
    SELECT end_station_id AS station_id, end_station_name AS station_name
    FROM DW_SCHEMA.staging_trip
    WHERE end_station_id IS NOT NULL
  )
) src
ON (tgt.dim_station_id = src.station_id)
WHEN MATCHED THEN
  UPDATE SET 
    tgt.dim_station_name = src.station_name
  WHERE tgt.dim_station_name != src.station_name  -- Update only if name differs
WHEN NOT MATCHED THEN
  INSERT (
    dim_station_id,
    dim_station_name
  )
  VALUES (
    src.station_id,
    src.station_name
  );
  
COMMIT;


-- Set PDB context
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- Merge into dim_bike
MERGE /*+ APPEND */ INTO DW_SCHEMA.dim_bike tgt
USING (
  SELECT DISTINCT
    TO_NUMBER(bike_id) AS bike_id,
    model AS bike_model
  FROM DW_SCHEMA.staging_trip
) src
ON (tgt.dim_bike_id = src.bike_id)
WHEN MATCHED THEN
  UPDATE SET 
    tgt.dim_bike_model = src.bike_model
  WHERE tgt.dim_bike_model != src.bike_model  -- Update only if model differs
WHEN NOT MATCHED THEN
  INSERT (
    dim_bike_id,
    dim_bike_model
  )
  VALUES (
    src.bike_id,
    src.bike_model
  );

COMMIT;


-- Set PDB context
ALTER SESSION SET CONTAINER = toronto_shared_bike;

MERGE /*+ APPEND */ INTO DW_SCHEMA.dim_user_type tgt
USING (
  SELECT DISTINCT user_type AS user_type_name
  FROM DW_SCHEMA.staging_trip
  WHERE user_type IS NOT NULL  -- Post-transformation, no nulls expected
) src
ON (tgt.dim_user_type_name = src.user_type_name)
WHEN NOT MATCHED THEN
  INSERT (
    dim_user_type_name
  )
  VALUES (
    src.user_type_name
  );
  
COMMIT;


-- Set PDB context
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- Merge into fact_trip

-- Merge into fact_trip
MERGE /*+ APPEND */ INTO DW_SCHEMA.fact_trip tgt
USING (
  SELECT 
    TO_NUMBER(trip_id) "FACT_TRIP_SOURCE_ID",
    TO_NUMBER(trip_duration) "FACT_TRIP_DURATION",
    (SELECT dim_time_id FROM dw_schema.dim_time WHERE dim_time_timestamp = TO_DATE(start_time,'MM/DD/YYYY HH24:MI')) "FACT_TRIP_START_TIME_ID",
    (SELECT dim_time_id FROM dw_schema.dim_time WHERE dim_time_timestamp = TO_DATE(end_time,'MM/DD/YYYY HH24:MI')) "FACT_TRIP_END_TIME_ID",
    TO_NUMBER(start_station_id) "FACT_TRIP_START_STATION_ID",
    TO_NUMBER(end_station_id) "FACT_TRIP_END_STATION_ID",
    TO_NUMBER(bike_id) "FACT_TRIP_BIKE_ID",
    (SELECT dim_user_type_id FROM dw_schema.dim_user_type WHERE dim_user_type_name = user_type) "FACT_TRIP_USER_TYPE_ID"
  FROM dw_schema.staging_trip
) src
ON (tgt.fact_trip_source_id = src.FACT_TRIP_SOURCE_ID)
WHEN MATCHED THEN
  UPDATE SET 
    tgt.fact_trip_duration = src.FACT_TRIP_DURATION,
    tgt.fact_trip_start_time_id = src.FACT_TRIP_START_TIME_ID,
    tgt.fact_trip_end_time_id = src.FACT_TRIP_END_TIME_ID,
    tgt.fact_trip_start_station_id = src.FACT_TRIP_START_STATION_ID,
    tgt.fact_trip_end_station_id = src.FACT_TRIP_END_STATION_ID,
    tgt.fact_trip_bike_id = src.FACT_TRIP_BIKE_ID,
    tgt.fact_trip_user_type_id = src.FACT_TRIP_USER_TYPE_ID
  WHERE tgt.fact_trip_duration != src.FACT_TRIP_DURATION 
     OR tgt.fact_trip_start_time_id != src.FACT_TRIP_START_TIME_ID 
     OR tgt.fact_trip_end_time_id != src.FACT_TRIP_END_TIME_ID 
     OR tgt.fact_trip_start_station_id != src.FACT_TRIP_START_STATION_ID 
     OR tgt.fact_trip_end_station_id != src.FACT_TRIP_END_STATION_ID 
     OR tgt.fact_trip_bike_id != src.FACT_TRIP_BIKE_ID 
     OR tgt.fact_trip_user_type_id != src.FACT_TRIP_USER_TYPE_ID
WHEN NOT MATCHED THEN
  INSERT (
    fact_trip_source_id,
    fact_trip_duration,
    fact_trip_start_time_id,
    fact_trip_end_time_id,
    fact_trip_start_station_id,
    fact_trip_end_station_id,
    fact_trip_bike_id,
    fact_trip_user_type_id
  )
  VALUES (
    src.FACT_TRIP_SOURCE_ID,
    src.FACT_TRIP_DURATION,
    src.FACT_TRIP_START_TIME_ID,
    src.FACT_TRIP_END_TIME_ID,
    src.FACT_TRIP_START_STATION_ID,
    src.FACT_TRIP_END_STATION_ID,
    src.FACT_TRIP_BIKE_ID,
    src.FACT_TRIP_USER_TYPE_ID
  );
  
COMMIT;

```