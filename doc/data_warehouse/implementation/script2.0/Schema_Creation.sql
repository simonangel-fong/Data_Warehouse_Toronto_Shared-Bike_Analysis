-- Create Dedicated schema in the PDB
SET SERVEROUTPUT ON;
ALTER SESSION SET CONTAINER = toronto_shared_bike;

-- Create the DW_SCHEMA user
CREATE USER DW_SCHEMA
  IDENTIFIED BY "DwSchemaSecurePass123"
  DEFAULT TABLESPACE FACT_TBSP
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON FACT_TBSP
  QUOTA UNLIMITED ON INDEX_TBSP;

-- Grant necessary privileges to DW_SCHEMA
GRANT CREATE SESSION TO DW_SCHEMA;           -- Allow login
GRANT CREATE TABLE TO DW_SCHEMA;             -- Create tables (fact, dim, staging)
ALTER USER DW_SCHEMA QUOTA UNLIMITED ON FACT_TBSP;
ALTER USER DW_SCHEMA QUOTA UNLIMITED ON DIM_TBSP;

-- Create dim_time
CREATE TABLE DW_SCHEMA.dim_time (
  dim_time_id           NUMBER(12)  NOT NULL  -- Unique time identifier (YYYYMMDDHHMI)
  , dim_time_timestamp  DATE        NOT NULL  -- Canonical date representation
  , dim_time_year       NUMBER(4)   NOT NULL  -- Year (e.g., 2024)
  , dim_time_quarter    NUMBER(1)   NOT NULL  -- Quarter
  , dim_time_month      NUMBER(2)   NOT NULL  -- Month
  , dim_time_day        NUMBER(2)   NOT NULL  -- Day
  , dim_time_week       NUMBER(2)   NOT NULL  -- Week
  , dim_time_weekday    NUMBER(1)   NOT NULL  -- Day of week
  , dim_time_hour       NUMBER(2)   NOT NULL  -- Hour
  , dim_time_minute     NUMBER(2)   NOT NULL  -- Minute
  , CONSTRAINT pk_dim_time  PRIMARY KEY (dim_time_id) USING INDEX TABLESPACE INDEX_TBSP   -- PK with B-tree index
  , CONSTRAINT chk_quarter  CHECK (dim_time_quarter BETWEEN 1 AND 4)                      -- Quarter (1-4)
  , CONSTRAINT chk_month    CHECK (dim_time_month BETWEEN 1 AND 12)                       -- Month (1-12)
  , CONSTRAINT chk_day      CHECK (dim_time_day BETWEEN 1 AND 31)                         -- Day (1-31)
  , CONSTRAINT chk_week     CHECK (dim_time_week BETWEEN 1 AND 53)                        -- Week (1-53)
  , CONSTRAINT chk_weekday  CHECK (dim_time_weekday BETWEEN 1 AND 7)                      -- Day of week
  , CONSTRAINT chk_hour     CHECK (dim_time_hour BETWEEN 0 AND 23)                        -- Hour (0-23)
  , CONSTRAINT chk_minute   CHECK (dim_time_minute BETWEEN 0 AND 59)                      -- Minute (0-59)

)
TABLESPACE DIM_TBSP;

-- Create B-tree index on date
CREATE INDEX DW_SCHEMA.index_dim_time_date
  ON DW_SCHEMA.dim_time (dim_time_timestamp)
  TABLESPACE INDEX_TBSP;  -- Index for date-based queries

-- Create composite B-tree index on year and month
CREATE INDEX DW_SCHEMA.index_dim_time_year_month
  ON DW_SCHEMA.dim_time (dim_time_year, dim_time_month)
  TABLESPACE INDEX_TBSP;  -- Index for year-month queries
---------

-- Create dim_station dimension table
CREATE TABLE DW_SCHEMA.dim_station (
  dim_station_id      NUMBER(6)       NOT NULL
  , dim_station_name  VARCHAR2(100)   NOT NULL
  , CONSTRAINT pk_dim_station PRIMARY KEY (dim_station_id) USING INDEX TABLESPACE INDEX_TBSP
)
TABLESPACE DIM_TBSP;

-- B-tree index on station_name
CREATE INDEX DW_SCHEMA.index_dim_station_station_name
ON DW_SCHEMA.dim_station (dim_station_name)
TABLESPACE INDEX_TBSP;-- Create dim_bike dimension table

-- Create dim_bike dimension table
CREATE TABLE DW_SCHEMA.dim_bike (
  dim_bike_id       NUMBER(6)     NOT NULL
  , dim_bike_model  VARCHAR2(50)  NOT NULL
  , CONSTRAINT pk_dim_bike PRIMARY KEY (dim_bike_id) USING INDEX TABLESPACE INDEX_TBSP
)
TABLESPACE DIM_TBSP;  -- Store in dimension tablespace, no partitioning

-- Create dim_user_type dimension table
CREATE TABLE DW_SCHEMA.dim_user_type (
  dim_user_type_id        NUMBER(3)     GENERATED ALWAYS AS IDENTITY
  , dim_user_type_name    VARCHAR2(50)  NOT NULL
  , CONSTRAINT pk_dim_user_type PRIMARY KEY (dim_user_type_id) USING INDEX TABLESPACE INDEX_TBSP    -- PK with B-tree index
  , CONSTRAINT uk_dim_user_type_name UNIQUE (dim_user_type_name) USING INDEX TABLESPACE INDEX_TBSP  -- Unique constraint on user_type
)
TABLESPACE DIM_TBSP;  -- Store in dimension tablespace, no partitioning

-- Create fact_trip fact table with range-range partitioning
CREATE TABLE DW_SCHEMA.fact_trip (
    fact_trip_id                  NUMBER(10)  GENERATED ALWAYS AS IDENTITY
    , fact_trip_source_id         NUMBER(10)  NOT NULL
    , fact_trip_duration          NUMBER(8)   NOT NULL
    , fact_trip_start_time_id     NUMBER(12)  NOT NULL
    , fact_trip_end_time_id       NUMBER(12)  NOT NULL
    , fact_trip_start_station_id  NUMBER(6)   NOT NULL
    , fact_trip_end_station_id    NUMBER(6)   NOT NULL
    , fact_trip_bike_id           NUMBER(6)   NOT NULL
    , fact_trip_user_type_id      NUMBER(3)   NOT NULL
    , CONSTRAINT pk_fact_trip                 PRIMARY KEY (fact_trip_id)                USING INDEX TABLESPACE INDEX_TBSP
    , CONSTRAINT fk_fact_trip_start_time      FOREIGN KEY (fact_trip_start_time_id)     REFERENCES DW_SCHEMA.dim_time (dim_time_id)
    , CONSTRAINT fk_fact_trip_end_time        FOREIGN KEY (fact_trip_end_time_id)       REFERENCES DW_SCHEMA.dim_time (dim_time_id)
    , CONSTRAINT fk_fact_trip_start_station   FOREIGN KEY (fact_trip_start_station_id)  REFERENCES DW_SCHEMA.dim_station (dim_station_id)
    , CONSTRAINT fk_fact_trip_end_station     FOREIGN KEY (fact_trip_end_station_id)    REFERENCES DW_SCHEMA.dim_station (dim_station_id)
    , CONSTRAINT fk_fact_trip_bike            FOREIGN KEY (fact_trip_bike_id)           REFERENCES DW_SCHEMA.dim_bike (dim_bike_id)
    , CONSTRAINT fk_fact_trip_user_type       FOREIGN KEY (fact_trip_user_type_id)      REFERENCES DW_SCHEMA.dim_user_type (dim_user_type_id)
)
TABLESPACE FACT_TBSP
ROW STORE COMPRESS ADVANCED
PARTITION BY RANGE (fact_trip_start_time_id)
SUBPARTITION BY RANGE (fact_trip_start_time_id)
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
-- Table FACT_TRIP created.

-- Create local B-tree index on start_time_id
CREATE INDEX DW_SCHEMA.index_fact_trip_start_time
  ON DW_SCHEMA.fact_trip (fact_trip_start_time_id)
  LOCAL
  TABLESPACE INDEX_TBSP;
-- Index INDEX_FACT_TRIP_START_TIME created.

-- Create composite B-tree index on start_station_id and end_station_id
CREATE INDEX DW_SCHEMA.index_fact_trip_station_pair
  ON DW_SCHEMA.fact_trip (fact_trip_start_station_id, fact_trip_end_station_id)
  TABLESPACE INDEX_TBSP;
-- Index INDEX_FACT_TRIP_STATIONS created.

-- Create local bitmap index on user_type_id
CREATE BITMAP INDEX DW_SCHEMA.index_fact_trip_user_type
  ON DW_SCHEMA.fact_trip (fact_trip_user_type_id)
  LOCAL     -- Creates a bitmap index for each partition
  TABLESPACE INDEX_TBSP;

