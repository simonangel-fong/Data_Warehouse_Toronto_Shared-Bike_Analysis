# Toronto Bike Share Data Warehouse Documentation - Materialized View

[Back](../../../../README.md)

- [Toronto Bike Share Data Warehouse Documentation - Materialized View](#toronto-bike-share-data-warehouse-documentation---materialized-view)
  - [Materialized View](#materialized-view)
    - [DBA Jobs](#dba-jobs)
    - [Materialized View Logs](#materialized-view-logs)
    - [Materialized Views](#materialized-views)

---

## Materialized View

### DBA Jobs

```sql
-- Set PDB context
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- Create MV_TBSP tablespace
CREATE TABLESPACE MV_TBSP
DATAFILE '/u02/oradata/CDB1/toronto_shared_bike/MV_TBSP01.dbf'
SIZE 100M
AUTOEXTEND ON
NEXT 50M
MAXSIZE 2G
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;
```

---

### Materialized View Logs

-- Enable logs on the base tables to enable fast refresh

```sql
-- Set PDB context
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- MV log on fact_trip
DROP MATERIALIZED VIEW LOG ON DW_SCHEMA.fact_trip;
CREATE MATERIALIZED VIEW LOG ON DW_SCHEMA.fact_trip
TABLESPACE MV_TBSP
WITH ROWID, SEQUENCE (
    fact_trip_start_time_id
    , fact_trip_start_station_id
    , fact_trip_end_station_id
    )
INCLUDING NEW VALUES
;


-- MV log on dim_time
DROP MATERIALIZED VIEW LOG ON DW_SCHEMA.dim_time;
CREATE MATERIALIZED VIEW LOG ON DW_SCHEMA.dim_time
TABLESPACE MV_TBSP
WITH ROWID, SEQUENCE (
    dim_time_id
    , dim_time_year
    , dim_time_quarter
    , dim_time_month
    , dim_time_day
    , dim_time_week
    , dim_time_weekday
    , dim_time_hour
    )
INCLUDING NEW VALUES;

-- MV log on dim_station (though typically static, included for completeness)
DROP MATERIALIZED VIEW LOG ON DW_SCHEMA.dim_station;
CREATE MATERIALIZED VIEW LOG ON DW_SCHEMA.dim_station
TABLESPACE MV_TBSP
WITH ROWID, SEQUENCE (
    dim_station_id
    , dim_station_name
    )
INCLUDING NEW VALUES;

```

---

### Materialized Views

```sql
-- Create MV_TIME_TRIP
CREATE MATERIALIZED VIEW DW_SCHEMA.MV_TIME_TRIP
TABLESPACE MV_TBSP
PARTITION BY RANGE (dim_year) (
    PARTITION p_before  VALUES LESS THAN (2019)
    , PARTITION p_2020  VALUES LESS THAN (2020)
    , PARTITION p_2021  VALUES LESS THAN (2021)
    , PARTITION p_2022  VALUES LESS THAN (2022)
    , PARTITION p_2023  VALUES LESS THAN (2023)
    , PARTITION p_2024  VALUES LESS THAN (2024)
    , PARTITION p_2025  VALUES LESS THAN (2025)
    , PARTITION p_max   VALUES LESS THAN (MAXVALUE)
)
BUILD IMMEDIATE
REFRESH FAST ON DEMAND      -- for incremental updates
ENABLE QUERY REWRITE
AS
SELECT
    COUNT(*)                AS trip_count
    , t.dim_time_year       AS dim_year
    , t.dim_time_quarter    AS dim_quarter
    , t.dim_time_month      AS dim_month
    , t.dim_time_day        AS dim_day
    , t.dim_time_week       AS dim_week
    , t.dim_time_weekday    AS dim_weekday
    , t.dim_time_hour       AS dim_hour
FROM DW_SCHEMA.fact_trip f
JOIN DW_SCHEMA.dim_time t
    ON f.fact_trip_start_time_id = t.dim_time_id
GROUP BY
    t.dim_time_year
    , t.dim_time_quarter
    , t.dim_time_month
    , t.dim_time_day
    , t.dim_time_week
    , t.dim_time_weekday
    , t.dim_time_hour;

-- Composite B-tree index for year-month queries
CREATE INDEX DW_SCHEMA.idx_mv_time_trip_year_month
ON DW_SCHEMA.MV_TIME_TRIP (dim_year, dim_month)
TABLESPACE MV_TBSP;

-- Composite B-tree index for year-hour queries
CREATE INDEX DW_SCHEMA.idx_mv_time_trip_year_hour
ON DW_SCHEMA.MV_TIME_TRIP (dim_year, dim_hour)
TABLESPACE MV_TBSP;

-- confirm
SELECT *
FROM DW_SCHEMA.MV_TIME_TRIP
ORDER BY dim_year, dim_quarter, dim_month, dim_day, dim_week, dim_weekday, dim_hour;


-- Create MV_STATION_TRIP
CREATE MATERIALIZED VIEW DW_SCHEMA.MV_STATION_TRIP
TABLESPACE MV_TBSP
BUILD IMMEDIATE
REFRESH FAST ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT
    s.dim_station_id                                                                AS station_id
    , s.dim_station_name                                                            AS station_name
    , COUNT(CASE WHEN f.fact_trip_start_station_id = s.dim_station_id THEN 1 END)   AS trip_count_by_start
    , COUNT(CASE WHEN f.fact_trip_end_station_id = s.dim_station_id THEN 1 END)     AS trip_count_by_end
FROM DW_SCHEMA.fact_trip f
JOIN DW_SCHEMA.dim_station s
    ON s.dim_station_id IN (f.fact_trip_start_station_id, f.fact_trip_end_station_id)
GROUP BY
    s.dim_station_id
    , s.dim_station_name;


-- Create MV_ROUTE
CREATE MATERIALIZED VIEW DW_SCHEMA.MV_ROUTE
TABLESPACE MV_TBSP
BUILD IMMEDIATE
REFRESH FAST ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT
    s_start.dim_station_id      AS start_station_id
    , s_start.dim_station_name  AS start_station_name
    , s_end.dim_station_id      AS end_station_id
    , s_end.dim_station_name    AS end_station_name
    , COUNT(*)                  AS trip_count
FROM DW_SCHEMA.fact_trip f
JOIN DW_SCHEMA.dim_station s_start
    ON f.fact_trip_start_station_id = s_start.dim_station_id
JOIN DW_SCHEMA.dim_station s_end
    ON f.fact_trip_end_station_id = s_end.dim_station_id
GROUP BY
    s_start.dim_station_id
    , s_start.dim_station_name
    , s_end.dim_station_id
    , s_end.dim_station_name;

-- confirm
SELECT 
    start_station_name
    , end_station_name
    , trip_count
FROM DW_SCHEMA.MV_ROUTE
ORDER BY trip_count DESC
FETCH FIRST 10 ROWS ONLY;


-- Create MV_BIKE_TRIP_DURATION
CREATE MATERIALIZED VIEW DW_SCHEMA.MV_BIKE_TRIP_DURATION
TABLESPACE MV_TBSP
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT
    b.dim_bike_id                           AS bike_id
    , COUNT(*)                              AS trip_count
    , ROUND(AVG(f.fact_trip_duration), 2)   AS avg_trip_duration
FROM DW_SCHEMA.fact_trip f
JOIN DW_SCHEMA.dim_bike b
    ON f.fact_trip_bike_id = b.dim_bike_id
GROUP BY
    b.dim_bike_id;

-- confirm
SELECT 
    bike_id
    , trip_count
    , avg_trip_duration
FROM DW_SCHEMA.MV_BIKE_TRIP_DURATION
ORDER BY trip_count DESC
FETCH FIRST 10 ROWS ONLY;


-- Create MV_USER_SEGMENTATION
DROP MATERIALIZED VIEW DW_SCHEMA.MV_USER_SEGMENTATION;
CREATE MATERIALIZED VIEW DW_SCHEMA.MV_USER_SEGMENTATION
TABLESPACE MV_TBSP
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT
    u.dim_user_type_id                      AS user_type_id
    , u.dim_user_type_name                  AS user_type_name
    , t.dim_time_year                       AS dim_year
    , COUNT(*)                              AS trip_count
    , ROUND(AVG(f.fact_trip_duration),2)    AS avg_trip_duration
FROM DW_SCHEMA.fact_trip f
JOIN DW_SCHEMA.dim_user_type u
    ON f.fact_trip_user_type_id = u.dim_user_type_id
JOIN DW_SCHEMA.dim_time t
    ON f.fact_trip_start_time_id = t.dim_time_id
GROUP BY
    u.dim_user_type_id
    , u.dim_user_type_name
    , t.dim_time_year;

-- confirm
SELECT 
    user_type_name
    , year
    , trip_count
    , avg_trip_duration
FROM DW_SCHEMA.MV_USER_SEGMENTATION
WHERE year = 2019
ORDER BY trip_count DESC;
```
