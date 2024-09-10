-- SQL script to Transform data.
-- User = dba, container = root

ALTER SESSION SET container=toronto_shared_bike;
show con_name;
show user;

-- Creation of staging tran table
CREATE TABLE app_admin.staging_tran_ridership (
    trip_id number primary key,
    trip_duration number,
    start_time TIMESTAMP,
    start_station_id number,
    start_station_name VARCHAR2(100),
    end_time TIMESTAMP,
    end_station_id number,
    end_station_name VARCHAR2(100),
    bike_id number,
    user_type VARCHAR2(50)
);

-------- Load data from source tb to stagging table --------
-- Remove duplicate
-- remove null
-- remove duration <=0
MERGE INTO app_admin.staging_tran_ridership tgt
USING (
    SELECT
        TO_NUMBER(trip_id) "TRIP_ID",
        TO_NUMBER(trip_duration) "TRIP_DURATION",
        TO_NUMBER(start_station_id) "START_STATION_ID",
        TO_TIMESTAMP(start_time, 'MM/DD/YYYY HH24:MI') "START_TIME",
        start_station_name "START_STATION_NAME",
        TO_NUMBER(end_station_id) "END_STATION_ID",
        TO_TIMESTAMP(end_time, 'MM/DD/YYYY HH24:MI') "END_TIME",
        end_station_name "END_STATION_NAME",
        TO_NUMBER(bike_id) "BIKE_ID",
        user_type "USER_TYPE"
    FROM app_admin.staging_ridership
    WHERE TO_NUMBER(trip_duration) > 0
    AND (trip_id IS NOT NULL AND trip_id <> 'NULL')
    AND (start_time IS NOT NULL AND start_time <> 'NULL')
    AND (start_station_id IS NOT NULL AND start_station_id <> 'NULL')
    AND (start_station_name IS NOT NULL AND start_station_name <> 'NULL')
    AND (end_time IS NOT NULL AND end_time <> 'NULL')
    AND (end_station_id IS NOT NULL AND end_station_id <> 'NULL')
    AND (end_station_name IS NOT NULL AND end_station_name <> 'NULL')
    AND (bike_id IS NOT NULL AND bike_id <> 'NULL')
    AND (user_type IS NOT NULL AND user_type <> 'NULL')
) src
ON (tgt.trip_id = src.trip_id)
WHEN MATCHED THEN
    UPDATE SET
        tgt.trip_duration = src.trip_duration,
        tgt.start_station_id = src.start_station_id,
        tgt.start_time = src.start_time,
        tgt.start_station_name = src.start_station_name,
        tgt.end_station_id = src.end_station_id,
        tgt.end_time = src.end_time,
        tgt.end_station_name = src.end_station_name,
        tgt.bike_id = src.bike_id,
        tgt.user_type = src.user_type
WHEN NOT MATCHED THEN
    INSERT (
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
    VALUES (
        src.trip_id,
        src.trip_duration,
        src.start_station_id,
        src.start_time,
        src.start_station_name,
        src.end_station_id,
        src.end_time,
        src.end_station_name,
        src.bike_id,
        src.user_type
    );

COMMIT;
