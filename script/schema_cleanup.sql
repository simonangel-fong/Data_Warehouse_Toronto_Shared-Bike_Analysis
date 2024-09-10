ALTER SESSION SET container=toronto_shared_bike;

DROP TABLE app_admin.fact_ridership;
DROP TABLE app_admin.dim_time;
DROP TABLE app_admin.dim_station;
DROP TABLE app_admin.dim_bike;
DROP TABLE app_admin.dim_user_type;