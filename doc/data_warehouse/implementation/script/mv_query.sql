ALTER SeSSION set container=toronto_shared_bike;
-- Yearly analysis
SELECT 
    year
    , SUM(total_trip)
    , ROUND(SUM(total_duration) / SUM(total_trip)) "AVG"
FROM app_admin.mv_temporal_summary
GROUP BY year
ORDER BY year;

-- Monthly analysis
SELECT 
    month
    , SUM(total_trip)
    , ROUND(SUM(total_duration) / SUM(total_trip)) "AVG"
FROM app_admin.mv_temporal_summary
GROUP BY month
ORDER BY month;

-- hourly analysis
SELECT 
    hour
    , SUM(total_trip) "TOTAL_TRIP"
    , ROUND(SUM(total_duration) / SUM(total_trip)) "AVG"
FROM app_admin.mv_temporal_summary
GROUP BY hour
ORDER BY hour;

-- station analysis
SELECT 
    start_station
    , SUM(total_trip) "TOTAL_TRIP"
    , ROUND(SUM(total_duration) / SUM(total_trip)) "AVG"
FROM app_admin.mv_station_summary
GROUP BY start_station
ORDER BY total_trip DESC;

-- user analysis
SELECT *
FROM app_admin.mv_user_summary;





