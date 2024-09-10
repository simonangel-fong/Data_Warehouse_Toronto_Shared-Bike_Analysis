SET SERVEROUTPUT ON;
ALTER SESSION SET container=toronto_shared_bike;

GRANT create table TO app_admin;

CREATE MATERIALIZED VIEW app_admin.mv_temporal_summary
BUILD IMMEDIATE
REFRESH COMPLETE
AS
SELECT 
    dt.year "YEAR"
    , dt.month "MONTH"
    , dt.hour "HOUR"
    , dt.quarter "QUARTER"
    , dt.weekday "WEEKDAY"
    , COUNT(trip_duration) AS "TOTAL_TRIP"
    , SUM(trip_duration) AS "TOTAL_DURATION"
FROM app_admin.fact_ridership f
JOIN app_admin.dim_time dt
ON f.start_time_id = dt.time_id
GROUP BY YEAR, MONTH, HOUR, QUARTER, WEEKDAY;

CREATE MATERIALIZED VIEW app_admin.mv_station_summary
BUILD IMMEDIATE
REFRESH COMPLETE
AS
SELECT
    START_STATION
    , END_STATION
    , SUM(duration) "TOTAL_DURATION"
    , COUNT(duration) "TOTAL_TRIP"
FROM (
    SELECT
        str.station_name "START_STATION"
        , estr.station_name "END_STATION"
        , f.trip_duration "DURATION"
    FROM app_admin.fact_ridership f
    JOIN app_admin.dim_station str
    ON f.start_station_id = str.station_id
    JOIN app_admin.dim_station estr
    ON f.end_station_id = estr.station_id
)
GROUP BY START_STATION, END_STATION;

CREATE MATERIALIZED VIEW app_admin.mv_user_summary
BUILD IMMEDIATE
REFRESH COMPLETE
AS
SELECT
    u.user_type
    , COUNT(trip_duration)
    , SUM(trip_duration)
    , ROUND(AVG(trip_duration))
FROM app_admin.fact_ridership f
JOIN app_admin.dim_user_type u
ON f.user_type_id = u.user_type_id
GROUP BY user_type;
