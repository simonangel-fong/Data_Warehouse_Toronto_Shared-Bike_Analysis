WITH station_times AS (
    -- Start station records
    SELECT 
        start_station_id AS station_id,
        start_station_name AS station_name,
        TO_DATE(start_time, 'MM/DD/YYYY HH24:MI') AS trip_datetime
    FROM DW_SCHEMA.staging_trip
    WHERE start_time IS NOT NULL
    UNION ALL
    -- End station records
    SELECT 
        end_station_id AS station_id,
        end_station_name AS station_name,
        TO_DATE(end_time, 'MM/DD/YYYY HH24:MI') AS trip_datetime
    FROM DW_SCHEMA.staging_trip
    WHERE end_time IS NOT NULL
),
ranked_stations AS (
    SELECT 
        station_id,
        station_name,
        trip_datetime,
        ROW_NUMBER() OVER (PARTITION BY station_id ORDER BY trip_datetime DESC) AS rn
    FROM station_times
)
SELECT 
    station_id,
    station_name,
    trip_datetime AS latest_datetime
FROM ranked_stations
WHERE rn = 1
ORDER BY latest_datetime DESC;


MERGE INTO DW_SCHEMA.dim_station ds
USING (
    WITH station_times AS (
        -- Start station records
        SELECT 
            start_station_id AS station_id,
            start_station_name AS station_name,
            TO_DATE(start_time, 'MM/DD/YYYY HH24:MI') AS trip_datetime
        FROM DW_SCHEMA.staging_trip
        WHERE start_station_id IS NOT NULL AND start_station_name IS NOT NULL
        UNION ALL
        -- End station records
        SELECT 
            end_station_id AS station_id,
            end_station_name AS station_name,
            TO_DATE(end_time, 'MM/DD/YYYY HH24:MI') AS trip_datetime
        FROM DW_SCHEMA.staging_trip
        WHERE end_station_id IS NOT NULL AND end_station_name IS NOT NULL
    ),
    latest_stations AS (
        SELECT 
            station_id,
            station_name,
            ROW_NUMBER() OVER (PARTITION BY station_id ORDER BY trip_datetime DESC) AS rn
        FROM station_times
    )
    SELECT 
        station_id AS dim_station_id,
        station_name AS dim_station_name
    FROM latest_stations
    WHERE rn = 1
) src
ON (ds.dim_station_id = src.dim_station_id)
WHEN MATCHED THEN
    UPDATE SET ds.dim_station_name = src.dim_station_name
WHEN NOT MATCHED THEN
    INSERT (ds.dim_station_id, ds.dim_station_name)
    VALUES (src.dim_station_id, src.dim_station_name);
    
SELECT *
FROM dw_schema.staging_trip;
