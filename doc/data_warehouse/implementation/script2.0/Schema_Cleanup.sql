SET SERVEROUTPUT ON;
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- Drop existing objects
DROP INDEX DW_SCHEMA.index_dim_time_date;
DROP INDEX DW_SCHEMA.index_dim_station_station_name;
DROP INDEX DW_SCHEMA.index_dim_time_year_month;
DROP INDEX DW_SCHEMA.index_fact_trip_start_time;
DROP INDEX DW_SCHEMA.index_fact_trip_station_pair;
DROP INDEX DW_SCHEMA.index_fact_trip_user_type;

DROP TABLE DW_SCHEMA.fact_trip;
DROP TABLE DW_SCHEMA.dim_time;
DROP TABLE DW_SCHEMA.dim_station;
DROP TABLE DW_SCHEMA.dim_bike;
DROP TABLE DW_SCHEMA.dim_user_type;

DROP USER DW_SCHEMA CASCADE;
