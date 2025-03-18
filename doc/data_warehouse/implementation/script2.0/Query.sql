SET SERVEROUTPUT ON;
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- Query external table
SELECT *
FROM DW_SCHEMA.external_ridership;

-- Query staging table
SELECT *
FROM DW_SCHEMA.staging_trip
ORDER BY start_time;

--TRUNCATE TABLE DW_SCHEMA.staging_trip;
-- Query data warehouse table
SELECT 
    fact_trip_duration                                          AS "Duration"
    , TO_CHAR(stt.dim_time_timestamp, 'MM/DD/YYYY HH24:MI')     AS "Start Time"
    , TO_CHAR(ent.dim_time_timestamp, 'MM/DD/YYYY HH24:MI')     AS "End Time"
    , stst.dim_station_name                                     AS "Start Station"
    , enst.dim_station_name                                     AS "End Station"
    , ustp.dim_user_type_name                                   AS "User Type"
    , bk.dim_bike_model                                         AS "Model"
FROM DW_SCHEMA.fact_trip f
JOIN DW_SCHEMA.dim_time stt
ON f.fact_trip_start_time_id = stt.dim_time_id
JOIN DW_SCHEMA.dim_time ent
ON f.fact_trip_end_time_id = ent.dim_time_id
JOIN DW_SCHEMA.dim_station stst
ON f.fact_trip_start_station_id = stst.dim_station_id
JOIN DW_SCHEMA.dim_station enst
ON f.fact_trip_end_station_id = stst.dim_station_id
JOIN DW_SCHEMA.dim_user_type ustp
ON f.fact_trip_user_type_id = ustp.dim_user_type_id
JOIN DW_SCHEMA.dim_bike bk
ON f.fact_trip_bike_id = bk.dim_bike_id
WHERE stt.dim_time_year = 2019
AND stt.dim_time_month = 1
ORDER BY stt.dim_time_timestamp
;

-- Query MV_TIME_TRIP
SELECT 
   SUM(trip_count)      AS "Total Trip"
   , dim_year           AS "Year"
FROM DW_SCHEMA.MV_TIME_TRIP
GROUP BY dim_year
ORDER BY dim_year;

-- Query MV_STATION_ROUTE
SELECT 
   start_station_name       AS "Start Station"
   , end_station_name       AS "End Station"
   , trip_count             AS "Total Count"
FROM DW_SCHEMA.MV_STATION_ROUTE
WHERE start_station_name != end_station_name
ORDER BY trip_count DESC
FETCH FIRST 10 ROWS ONLY;

-- Query MV_BIKE_TRIP_DURATION
SELECT 
   bike_id              AS "Bike ID"
   , trip_count         AS "Total Trip"
   , avg_trip_duration  AS "Average Duration"
FROM DW_SCHEMA.MV_BIKE_TRIP_DURATION
ORDER BY trip_count DESC
FETCH FIRST 10 ROWS ONLY;

-- Query MV_USER_SEGMENTATION
SELECT 
   user_type_name           AS "User Type"
   , dim_year               AS "Year"
   , trip_count             AS "Total Trip"
   , avg_trip_duration      AS "Average Duration"
FROM DW_SCHEMA.MV_USER_SEGMENTATION
ORDER BY dim_year, user_type_name;

