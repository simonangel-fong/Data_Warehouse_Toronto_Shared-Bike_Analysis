-- SQL script to create PDB, user
-- User = dba, container = root

SET SERVEROUTPUT ON;
ALTER SESSION SET CONTAINER = CDB$ROOT;

CREATE PLUGGABLE DATABASE toronto_shared_bike
  ADMIN USER pdb_admin IDENTIFIED BY YourSecurePassword123
  ROLES = (DBA)
  FILE_NAME_CONVERT = (
    '/u02/oradata/CDB1/pdbseed/',
    '/u02/oradata/CDB1/toronto_shared_bike/');

ALTER PLUGGABLE DATABASE toronto_shared_bike OPEN;
ALTER PLUGGABLE DATABASE toronto_shared_bike SAVE STATE;

-- Switch to the newly created PDB
ALTER SESSION SET CONTAINER=toronto_shared_bike;

-- Create FACT_TBSP tablespace for storing the fact table
CREATE TABLESPACE FACT_TBSP
DATAFILE '/u02/oradata/CDB1/toronto_shared_bike/fact_tbsp01.dbf'
SIZE 100M                 -- Initial allocation
AUTOEXTEND ON NEXT 1G    -- Auto-extend in 1GB increments, reducing extend frequency for a growing fact table.
MAXSIZE 50G              -- Prevent excessive growth
BLOCKSIZE 32K            -- Optimized for data warehouse queries
EXTENT MANAGEMENT LOCAL AUTOALLOCATE  -- Efficient space allocation
SEGMENT SPACE MANAGEMENT AUTO  -- Automatic segment space management
LOGGING                -- Ensures data integrity with redo logging
ONLINE;                -- Makes the tablespace available immediately

CREATE TABLESPACE DIM_TBSP
  DATAFILE '/u02/oradata/CDB1/toronto_shared_bike/dim_tbsp01.dbf'
    SIZE 50M              -- Initial size for dimension data
    AUTOEXTEND ON NEXT 25M  -- 25M increments for moderate growth
    MAXSIZE 5G            -- Cap suitable for small dimension tables
  BLOCKSIZE 8K            -- 8k block size for random access
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE  -- Efficient space allocation
  SEGMENT SPACE MANAGEMENT AUTO         -- Automatic space management
  LOGGING                 -- Ensures recoverability
  ONLINE;                  -- Immediate availability

CREATE TABLESPACE INDEX_TBSP
  DATAFILE '/u02/oradata/CDB1/toronto_shared_bike/index_tbsp01.dbf'
    SIZE 50M              -- Initial size for indexes
    AUTOEXTEND ON NEXT 25M  -- 25M increments for moderate growth
    MAXSIZE 5G            -- Cap suitable for index growth
  BLOCKSIZE 8K            -- 8k block size for index efficiency
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE  -- Efficient space allocation
  SEGMENT SPACE MANAGEMENT AUTO         -- Automatic space management
  LOGGING                 -- Ensures recoverability
  ONLINE;                  -- Immediate availability

-- Ensure creation in the toronto_shared_bike PDB
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- Create dim_time dimension table
CREATE TABLE dim_time (
  time_id   NUMBER(12) NOT NULL,                    -- Unique time identifier (YYYYMMDDHHMI)
  timestamp      DATE NOT NULL,                          -- Canonical date representation
  year      NUMBER(4) NOT NULL,                     -- Year (e.g., 2024)
  quarter   NUMBER(1) NOT NULL CONSTRAINT chk_quarter CHECK (quarter BETWEEN 1 AND 4),  -- Quarter (1-4)
  month     NUMBER(2) NOT NULL CONSTRAINT chk_month CHECK (month BETWEEN 1 AND 12),    -- Month (1-12)
  day       NUMBER(2) NOT NULL CONSTRAINT chk_day CHECK (day BETWEEN 1 AND 31),      -- Day (1-31)
  week      NUMBER(2) NOT NULL CONSTRAINT chk_week CHECK (week BETWEEN 1 AND 53),    -- Week (1-53)
  weekday   NUMBER(1) NOT NULL CONSTRAINT chk_weekday CHECK (weekday BETWEEN 0 AND 6), -- Day of week (0=Sun, 6=Sat)
  hour      NUMBER(2) NOT NULL CONSTRAINT chk_hour CHECK (hour BETWEEN 0 AND 23),            -- Hour (0-23)
  minute    NUMBER(2) NOT NULL CONSTRAINT chk_minute CHECK (minute BETWEEN 0 AND 59),        -- Minute (0-59)
  CONSTRAINT pk_dim_time PRIMARY KEY (time_id) USING INDEX TABLESPACE INDEX_TBSP   -- PK with B-tree index
)
TABLESPACE DIM_TBSP;  -- Store in dimension tablespace, no partitioning

CREATE INDEX index_dim_time_date
  ON dim_time (timestamp)
  TABLESPACE INDEX_TBSP;  -- Index for date-based queries

CREATE INDEX index_dim_time_year_month
  ON dim_time (year, month)
  TABLESPACE INDEX_TBSP;  -- Index for year-month queries

CREATE TABLE dim_station (
  station_id   NUMBER(6) NOT NULL,
  station_name VARCHAR2(100) NOT NULL,
  CONSTRAINT pk_dim_station PRIMARY KEY (station_id) USING INDEX TABLESPACE INDEX_TBSP
)
TABLESPACE DIM_TBSP;

CREATE INDEX index_dim_station_station_name
ON dim_station (station_name)
TABLESPACE INDEX_TBSP;-- Create dim_bike dimension table

CREATE TABLE dim_bike (
  bike_id     NUMBER(6) NOT NULL,                    -- Unique bike identifier
  bike_model  VARCHAR2(50) NOT NULL,                -- Model/type of the bike
  CONSTRAINT pk_dim_bike PRIMARY KEY (bike_id) USING INDEX TABLESPACE INDEX_TBSP  -- PK with B-tree index
)
TABLESPACE DIM_TBSP;  -- Store in dimension tablespace, no partitioning

CREATE TABLE dim_user_type (
  user_type_id  NUMBER(3) NOT NULL,                    -- Unique identifier for user type
  user_type     VARCHAR2(50) NOT NULL,                -- User type description (e.g., Member, Casual)
  CONSTRAINT pk_dim_user_type PRIMARY KEY (user_type_id) USING INDEX TABLESPACE INDEX_TBSP,  -- PK with B-tree index
  CONSTRAINT uk_dim_user_type UNIQUE (user_type) USING INDEX TABLESPACE INDEX_TBSP           -- Unique constraint on user_type
)
TABLESPACE DIM_TBSP;  -- Store in dimension tablespace, no partitioning

-- Ensure creation in the toronto_shared_bike PDB
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- Create fact_trip fact table with range-range partitioning
CREATE TABLE fact_trip (
  trip_id          NUMBER(10) GENERATED ALWAYS AS IDENTITY,
  trip_duration    NUMBER(8) NOT NULL,
  start_time_id    NUMBER(12) NOT NULL,
  end_time_id      NUMBER(12) NOT NULL,
  start_station_id NUMBER(6) NOT NULL,
  end_station_id   NUMBER(6) NOT NULL,
  bike_id          NUMBER(6) NOT NULL,
  user_type_id     NUMBER(3) NOT NULL,
  CONSTRAINT pk_fact_trip PRIMARY KEY (trip_id) USING INDEX TABLESPACE INDEX_TBSP,
  CONSTRAINT fk_fact_trip_start_time FOREIGN KEY (start_time_id) REFERENCES dim_time (time_id),
  CONSTRAINT fk_fact_trip_end_time FOREIGN KEY (end_time_id) REFERENCES dim_time (time_id),
  CONSTRAINT fk_fact_trip_start_station FOREIGN KEY (start_station_id) REFERENCES dim_station (station_id),
  CONSTRAINT fk_fact_trip_end_station FOREIGN KEY (end_station_id) REFERENCES dim_station (station_id),
  CONSTRAINT fk_fact_trip_bike FOREIGN KEY (bike_id) REFERENCES dim_bike (bike_id),
  CONSTRAINT fk_fact_trip_user_type FOREIGN KEY (user_type_id) REFERENCES dim_user_type (user_type_id)
)
TABLESPACE FACT_TBSP
ROW STORE COMPRESS ADVANCED
PARTITION BY RANGE (start_time_id)
SUBPARTITION BY RANGE (start_time_id)
(
  PARTITION p_before_2019 VALUES LESS THAN (201901010000),  -- Catch-all for pre-2019 data (expected empty)
  PARTITION p_2019 VALUES LESS THAN (202000000000)
  (
    SUBPARTITION p_2019_jan VALUES LESS THAN (201902010000),  -- Jan: >= 201901010000, < 201902010000
    SUBPARTITION p_2019_feb VALUES LESS THAN (201903010000),  -- Feb: >= 201902010000, < 201903010000
    SUBPARTITION p_2019_mar VALUES LESS THAN (201904010000),  -- Mar: >= 201903010000, < 201904010000
    SUBPARTITION p_2019_apr VALUES LESS THAN (201905010000),  -- Apr: >= 201904010000, < 201905010000
    SUBPARTITION p_2019_may VALUES LESS THAN (201906010000),  -- May: >= 201905010000, < 201906010000
    SUBPARTITION p_2019_jun VALUES LESS THAN (201907010000),  -- Jun: >= 201906010000, < 201907010000
    SUBPARTITION p_2019_jul VALUES LESS THAN (201908010000),  -- Jul: >= 201907010000, < 201908010000
    SUBPARTITION p_2019_aug VALUES LESS THAN (201909010000),  -- Aug: >= 201908010000, < 201909010000
    SUBPARTITION p_2019_sep VALUES LESS THAN (201910010000),  -- Sep: >= 201909010000, < 201910010000
    SUBPARTITION p_2019_oct VALUES LESS THAN (201911010000),  -- Oct: >= 201910010000, < 201911010000
    SUBPARTITION p_2019_nov VALUES LESS THAN (201912010000),  -- Nov: >= 201911010000, < 201912010000
    SUBPARTITION p_2019_dec VALUES LESS THAN (202000000000)   -- Dec: >= 201912010000, < 202000000000
  ),
  PARTITION p_2020 VALUES LESS THAN (202100000000)
  (
    SUBPARTITION p_2020_jan VALUES LESS THAN (202002010000),
    SUBPARTITION p_2020_feb VALUES LESS THAN (202003010000),
    SUBPARTITION p_2020_mar VALUES LESS THAN (202004010000),
    SUBPARTITION p_2020_apr VALUES LESS THAN (202005010000),
    SUBPARTITION p_2020_may VALUES LESS THAN (202006010000),
    SUBPARTITION p_2020_jun VALUES LESS THAN (202007010000),
    SUBPARTITION p_2020_jul VALUES LESS THAN (202008010000),
    SUBPARTITION p_2020_aug VALUES LESS THAN (202009010000),
    SUBPARTITION p_2020_sep VALUES LESS THAN (202010010000),
    SUBPARTITION p_2020_oct VALUES LESS THAN (202011010000),
    SUBPARTITION p_2020_nov VALUES LESS THAN (202012010000),
    SUBPARTITION p_2020_dec VALUES LESS THAN (202100000000)
  ),
  PARTITION p_2021 VALUES LESS THAN (202200000000)
  (
    SUBPARTITION p_2021_jan VALUES LESS THAN (202102010000),
    SUBPARTITION p_2021_feb VALUES LESS THAN (202103010000),
    SUBPARTITION p_2021_mar VALUES LESS THAN (202104010000),
    SUBPARTITION p_2021_apr VALUES LESS THAN (202105010000),
    SUBPARTITION p_2021_may VALUES LESS THAN (202106010000),
    SUBPARTITION p_2021_jun VALUES LESS THAN (202107010000),
    SUBPARTITION p_2021_jul VALUES LESS THAN (202108010000),
    SUBPARTITION p_2021_aug VALUES LESS THAN (202109010000),
    SUBPARTITION p_2021_sep VALUES LESS THAN (202110010000),
    SUBPARTITION p_2021_oct VALUES LESS THAN (202111010000),
    SUBPARTITION p_2021_nov VALUES LESS THAN (202112010000),
    SUBPARTITION p_2021_dec VALUES LESS THAN (202200000000)
  ),
  PARTITION p_2022 VALUES LESS THAN (202300000000)
  (
    SUBPARTITION p_2022_jan VALUES LESS THAN (202202010000),
    SUBPARTITION p_2022_feb VALUES LESS THAN (202203010000),
    SUBPARTITION p_2022_mar VALUES LESS THAN (202204010000),
    SUBPARTITION p_2022_apr VALUES LESS THAN (202205010000),
    SUBPARTITION p_2022_may VALUES LESS THAN (202206010000),
    SUBPARTITION p_2022_jun VALUES LESS THAN (202207010000),
    SUBPARTITION p_2022_jul VALUES LESS THAN (202208010000),
    SUBPARTITION p_2022_aug VALUES LESS THAN (202209010000),
    SUBPARTITION p_2022_sep VALUES LESS THAN (202210010000),
    SUBPARTITION p_2022_oct VALUES LESS THAN (202211010000),
    SUBPARTITION p_2022_nov VALUES LESS THAN (202212010000),
    SUBPARTITION p_2022_dec VALUES LESS THAN (202300000000)
  ),
  PARTITION p_2023 VALUES LESS THAN (202400000000)
  (
    SUBPARTITION p_2023_jan VALUES LESS THAN (202302010000),
    SUBPARTITION p_2023_feb VALUES LESS THAN (202303010000),
    SUBPARTITION p_2023_mar VALUES LESS THAN (202304010000),
    SUBPARTITION p_2023_apr VALUES LESS THAN (202305010000),
    SUBPARTITION p_2023_may VALUES LESS THAN (202306010000),
    SUBPARTITION p_2023_jun VALUES LESS THAN (202307010000),
    SUBPARTITION p_2023_jul VALUES LESS THAN (202308010000),
    SUBPARTITION p_2023_aug VALUES LESS THAN (202309010000),
    SUBPARTITION p_2023_sep VALUES LESS THAN (202310010000),
    SUBPARTITION p_2023_oct VALUES LESS THAN (202311010000),
    SUBPARTITION p_2023_nov VALUES LESS THAN (202312010000),
    SUBPARTITION p_2023_dec VALUES LESS THAN (202400000000)
  ),
  PARTITION p_2024 VALUES LESS THAN (202500000000)
  (
    SUBPARTITION p_2024_jan VALUES LESS THAN (202402010000),
    SUBPARTITION p_2024_feb VALUES LESS THAN (202403010000),
    SUBPARTITION p_2024_mar VALUES LESS THAN (202404010000),
    SUBPARTITION p_2024_apr VALUES LESS THAN (202405010000),
    SUBPARTITION p_2024_may VALUES LESS THAN (202406010000),
    SUBPARTITION p_2024_jun VALUES LESS THAN (202407010000),
    SUBPARTITION p_2024_jul VALUES LESS THAN (202408010000),
    SUBPARTITION p_2024_aug VALUES LESS THAN (202409010000),
    SUBPARTITION p_2024_sep VALUES LESS THAN (202410010000),
    SUBPARTITION p_2024_oct VALUES LESS THAN (202411010000),
    SUBPARTITION p_2024_nov VALUES LESS THAN (202412010000),
    SUBPARTITION p_2024_dec VALUES LESS THAN (202500000000)
  ),
  PARTITION p_future VALUES LESS THAN (MAXVALUE)
  (
    SUBPARTITION p_future_default VALUES LESS THAN (MAXVALUE) TABLESPACE FACT_TBSP
  )
);

CREATE INDEX index_fact_trip_start_time
  ON fact_trip (start_time_id)
  LOCAL
  TABLESPACE INDEX_TBSP;

CREATE INDEX index_fact_trip_stations
  ON fact_trip (start_station_id, end_station_id)
  TABLESPACE INDEX_TBSP;

CREATE BITMAP INDEX index_fact_trip_user_type
  ON fact_trip (user_type_id)
  LOCAL     -- Creates a bitmap index for each partition
  TABLESPACE INDEX_TBSP;

