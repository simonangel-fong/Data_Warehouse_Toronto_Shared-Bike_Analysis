-- Set PDB context
SET SERVEROUTPUT ON;
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

-- Load dim_station
DECLARE
    CURSOR station_cur is
        SELECT DISTINCT
            start_station_id        "STATION_ID"
            , start_station_name    "STATION_NAME"
        FROM dw_schema.staging_trip
        WHERE start_station_name != 'NULL'
        UNION
        SELECT DISTINCT
            end_station_id          "STATION_ID"
            , end_station_name      "STATION_NAME"
        FROM dw_schema.staging_trip
        WHERE start_station_name != 'NULL'
        ORDER BY STATION_ID;
        
    v_station_id    NUMBER;
    v_station_name  VARCHAR2(100);
    v_count NUMBER := 0;
BEGIN
    OPEN station_cur; 
    LOOP
        FETCH station_cur INTO v_station_id, v_station_name;
        EXIT WHEN station_cur%notfound;
        
        v_count := 0;
        SELECT count(*) INTO v_count
        FROM dw_schema.dim_station
        WHERE dim_station_id = v_station_id;
        
        IF v_count > 0 THEN
            -- if exist
            UPDATE dw_schema.dim_station SET
                dim_station_name = v_station_name
            WHERE dim_station_id = v_station_id;
        ELSE
            INSERT INTO dw_schema.dim_station(dim_station_id, dim_station_name)
            VALUES (v_station_id, v_station_name);
        END IF;
        
    END LOOP; 
    CLOSE station_cur;
    
    COMMIT;
END;
/

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

-- Merge into dim_user_type
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

-- Merge into fact_trip
MERGE /*+ APPEND */ INTO DW_SCHEMA.fact_trip tgt
USING (
  SELECT 
    TO_NUMBER(trip_id)                                                                                                  "FACT_TRIP_SOURCE_ID",
    TO_NUMBER(trip_duration)                                                                                            "FACT_TRIP_DURATION",
    (SELECT dim_time_id FROM dw_schema.dim_time WHERE dim_time_timestamp = TO_DATE(start_time,'MM/DD/YYYY HH24:MI'))    "FACT_TRIP_START_TIME_ID",
    (SELECT dim_time_id FROM dw_schema.dim_time WHERE dim_time_timestamp = TO_DATE(end_time,'MM/DD/YYYY HH24:MI'))      "FACT_TRIP_END_TIME_ID",
    TO_NUMBER(start_station_id)                                                                                         "FACT_TRIP_START_STATION_ID",
    TO_NUMBER(end_station_id)                                                                                           "FACT_TRIP_END_STATION_ID",
    TO_NUMBER(bike_id)                                                                                                  "FACT_TRIP_BIKE_ID",
    (SELECT dim_user_type_id FROM dw_schema.dim_user_type WHERE dim_user_type_name = user_type)                         "FACT_TRIP_USER_TYPE_ID"
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

-- Query data warehouse table
--SELECT 
--    fact_trip_duration                                          AS "Duration"
--    , TO_CHAR(stt.dim_time_timestamp, 'MM/DD/YYYY HH24:MI')     AS "Start Time"
--    , TO_CHAR(ent.dim_time_timestamp, 'MM/DD/YYYY HH24:MI')     AS "End Time"
--    , stst.dim_station_name                                     AS "Start Station"
--    , enst.dim_station_name                                     AS "End Station"
--    , ustp.dim_user_type_name                                   AS "User Type"
--    , bk.dim_bike_model                                         AS "Model"
--FROM DW_SCHEMA.fact_trip f
--JOIN DW_SCHEMA.dim_time stt
--ON f.fact_trip_start_time_id = stt.dim_time_id
--JOIN DW_SCHEMA.dim_time ent
--ON f.fact_trip_end_time_id = ent.dim_time_id
--JOIN DW_SCHEMA.dim_station stst
--ON f.fact_trip_start_station_id = stst.dim_station_id
--JOIN DW_SCHEMA.dim_station enst
--ON f.fact_trip_end_station_id = stst.dim_station_id
--JOIN DW_SCHEMA.dim_user_type ustp
--ON f.fact_trip_user_type_id = ustp.dim_user_type_id
--JOIN DW_SCHEMA.dim_bike bk
--ON f.fact_trip_bike_id = bk.dim_bike_id
--WHERE ROWNUM < 10;