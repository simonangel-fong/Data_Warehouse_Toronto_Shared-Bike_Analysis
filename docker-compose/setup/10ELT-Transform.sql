-- Script to transform
SET SERVEROUTPUT ON;
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- REMOVE_NULL_KEYCOL
DELETE FROM DW_SCHEMA.staging_trip
WHERE trip_id IS NULL
OR trip_duration IS NULL
OR start_time IS NULL
OR start_station_id IS NULL
OR end_station_id IS NULL;

-- REMOVE ALL station_id is string "NULL"
DELETE FROM DW_SCHEMA.staging_trip
WHERE start_station_id = 'NULL'
OR end_station_id = 'NULL';

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