-- SQL script to create user
-- User = sysdba, container = TORONTO_SHARED_BIKE
set serveroutput on;
ALTER SESSION SET container=toronto_shared_bike;
show user
show con_name

CREATE TABLE app_admin.dim_time(
    time_id             INT             PRIMARY KEY
    , full_time         TIMESTAMP
    , year              INT
    , month             INT
    , day               INT
    , hour              INT
    , minute            INT
    , quarter           INT
    , weekday           INT
);

CREATE TABLE app_admin.dim_station (
    station_id          INT             PRIMARY KEY
    , station_name      VARCHAR2(100)   Not NULL
)
PARTITION BY HASH(station_id);

CREATE TABLE app_admin.dim_bike (
    bike_id NUMBER PRIMARY KEY
);

CREATE TABLE app_admin.dim_user_type (
    user_type_id NUMBER PRIMARY KEY
    , user_type VARCHAR2(50) NOT NULL
);

CREATE TABLE app_admin.fact_ridership (
    trip_id NUMBER PRIMARY KEY
    , trip_duration NUMBER
    , start_time_id NUMBER
    , end_time_id NUMBER
    , start_station_id NUMBER
    , end_station_id NUMBER
    , bike_id NUMBER
    , user_type_id NUMBER
    , FOREIGN KEY (start_time_id) REFERENCES app_admin.dim_time(time_id)
    , FOREIGN KEY (end_time_id) REFERENCES app_admin.dim_time(time_id)
    , FOREIGN KEY (start_station_id) REFERENCES app_admin.dim_station(station_id)
    , FOREIGN KEY (end_station_id) REFERENCES app_admin.dim_station(station_id)
    , FOREIGN KEY (bike_id) REFERENCES app_admin.dim_bike(bike_id)
    , FOREIGN KEY (user_type_id) REFERENCES app_admin.dim_user_type(user_type_id)
);
--PARTITION BY RANGE (start_time_id)
--SUBPARTITION BY RANGE (start_time_id)
--SUBPARTITION TEMPLATE
--(
--    SUBPARTITION jan VALUES LESS THAN (202001000000),
--    SUBPARTITION feb VALUES LESS THAN (202002000000),
--    SUBPARTITION mar VALUES LESS THAN (202003000000),
--    SUBPARTITION apr VALUES LESS THAN (202004000000),
--    SUBPARTITION may VALUES LESS THAN (202005000000),
--    SUBPARTITION jun VALUES LESS THAN (202006000000),
--    SUBPARTITION jul VALUES LESS THAN (202007000000),
--    SUBPARTITION aug VALUES LESS THAN (202008000000),
--    SUBPARTITION sep VALUES LESS THAN (202009000000),
--    SUBPARTITION oct VALUES LESS THAN (202010000000),
--    SUBPARTITION nov VALUES LESS THAN (202011000000),
--    SUBPARTITION dec VALUES LESS THAN (202012000000)
--)
--(
--    PARTITION p_2019 VALUES LESS THAN (202000000000),
--    PARTITION p_2020 VALUES LESS THAN (202100000000),
--    PARTITION p_2021 VALUES LESS THAN (202200000000),
--    PARTITION p_2022 VALUES LESS THAN (202300000000),
--    PARTITION p_2023 VALUES LESS THAN (202400000000),
--    PARTITION p_2024 VALUES LESS THAN (202500000000),
--    PARTITION p_2025 VALUES LESS THAN (202600000000),
--    PARTITION p_future VALUES LESS THAN (MAXVALUE)
--);

CREATE INDEX idx_fact_ridership_start_time 
ON app_admin.fact_ridership(start_time_id);

CREATE INDEX idx_fact_ridership_end_time 
ON app_admin.fact_ridership(end_time_id);

CREATE INDEX idx_fact_ridership_start_station 
ON app_admin.fact_ridership(start_station_id);

CREATE INDEX idx_fact_ridership_end_station 
ON app_admin.fact_ridership(end_station_id);