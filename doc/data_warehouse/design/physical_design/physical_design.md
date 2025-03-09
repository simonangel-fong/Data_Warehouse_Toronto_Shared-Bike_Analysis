# Toronto Bike Share Data Warehouse Documentation - Physical Design

[Back](../../../../README.md)

- [Toronto Bike Share Data Warehouse Documentation - Physical Design](#toronto-bike-share-data-warehouse-documentation---physical-design)
- [Database Platform](#database-platform)
- [Physical Schema Design](#physical-schema-design)
  - [General Considerations](#general-considerations)
  - [Fact Table: `fact_trip`](#fact-table-fact_trip)
  - [Dimension Table: `dim_time`](#dimension-table-dim_time)
  - [Dimension Table: `dim_station`](#dimension-table-dim_station)
  - [Dimension Table: `dim_bike`](#dimension-table-dim_bike)
  - [Dimension Table: `dim_user_type`](#dimension-table-dim_user_type)
- [Security \& Access Control](#security--access-control)
- [Backup Strategy](#backup-strategy)

---

# Database Platform

- Chosen Platform: `Oracle 19c`

- Reason
  - **Cost Efficiency**: Aligns with budget constraints by leveraging existing old machine, avoiding cloud subscription costs.
  - **Performance**: Offers robust query optimization and indexing capabilities, suitable for the star schema’s analytical workload.
  - **Reliability**: Provides proven stability and data integrity features, ensuring dependable operation for the Toronto bike share data warehouse.
  - **Local Control**: Enables full administrative oversight and data governance within the organization, enhancing security and compliance.

---

# Physical Schema Design

Define the physical schema for the Toronto bike share data warehouse in Oracle 19c, optimizing for analytical performance and scalability, based on a star schema in the logical design.

## General Considerations

- **Project dedicated PDB**:
  - `toronto_shared_bike`
  - isolating the data warehouse for resource control and backup efficiency.
- **Storage management**:
  - `FACT_TBSP`:
    - Tablespace for fact table
    - Block size: 32k
  - `DIM_TBSP`:
    - Tablespace for dimension tables
    - Block size: 8k
  - `INDEX_TBSP`:
    - Tablespace for indexes
    - Block size: 8k

---

## Fact Table: `fact_trip`

| Column Name        | Data Type  | Constraints                                  |
| ------------------ | ---------- | -------------------------------------------- |
| `trip_id`          | NUMBER(10) | PK, NOT NULL, GENERATED ALWAYS AS IDENTITY   |
| `trip_duration`    | NUMBER(8)  | NOT NULL                                     |
| `start_time_id`    | NUMBER(12) | FK → `dim_time(time_id)`, NOT NULL           |
| `end_time_id`      | NUMBER(12) | FK → `dim_time(time_id)`, NOT NULL           |
| `start_station_id` | NUMBER(6)  | FK → `dim_station(station_id)`, NOT NULL     |
| `end_station_id`   | NUMBER(6)  | FK → `dim_station(station_id)`, NOT NULL     |
| `bike_id`          | NUMBER(6)  | FK → `dim_bike(bike_id)`, NOT NULL           |
| `user_type_id`     | NUMBER(3)  | FK → `dim_user_type(user_type_id)`, NOT NULL |

- **Tablespace**

  - `FACT_TBSP`

- **Compression**

  - **Advanced Row Compression**:
    - `COMPRESS FOR OLTP`
    - Optimizing storage for large fact data while supporting potential updates.

- **Partitioning**

  - `start_time_id`:
    - Partitioning: **Range partitioning** for Yearly query optimization.
    - Subpartitioning: **List Subpartitioning** by month for monthly query optimization.

- **Indexing**
  - `Index_fact_trip_start_time_id`:
    - Column: `start_time_id`
    - Tablespace: `INDEX_TBSP`
    - Type: Local B-tree
    - Purpose: Speed up time-based queries
  - `Index_fact_trip_station_pair`:
    - Column: `start_station_id, end_station_id`
    - Tablespace: `INDEX_TBSP`
    - Type: Composite Index
    - Purpose: Speed up trip origins and destinations queries
  - `index_fact_trip_user_type_id`:
    - Column: `user_type_id`
    - Tablespace: `INDEX_TBSP`
    - Type: Bitmap Index
    - Purpose: Speed up user-type-based queries

---

## Dimension Table: `dim_time`

| Column Name     | Data Type    | Constraints                              | Description                           |
| --------------- | ------------ | ---------------------------------------- | ------------------------------------- |
| `time_id`       | NUMBER(12)   | PK                                       | Unique time identifier (YYYYMMDDHHMI) |
| `date`          | DATE         | NOT NULL                                 | Date of the trip                      |
| `year`          | NUMBER(4)    | NOT NULL                                 | Year (e.g., 2024)                     |
| `month`         | NUMBER(2)    | CHECK (`month` BETWEEN 1 AND 12)         | Month (1-12)                          |
| `month_name`    | VARCHAR2(10) | NOT NULL                                 | Month name (e.g., January)            |
| `date_of_month` | NUMBER(2)    | CHECK (`date_of_month` BETWEEN 1 AND 31) | Date (1-31)                           |
| `week_of_year`  | NUMBER(2)    | CHECK (`week_of_year` BETWEEN 1 AND 53)  | Week number                           |
| `day_of_week`   | NUMBER(1)    | CHECK (`day_of_week` BETWEEN 0 AND 6)    | Day number (0=Sunday, 6=Saturday)     |
| `weekday`       | VARCHAR2(10) | NOT NULL                                 | Day of the week (Monday-Sunday)       |
| `hour`          | NUMBER(2)    | CHECK (`hour` BETWEEN 0 AND 23)          | Hour of the day (0-23)                |
| `minute`        | NUMBER(2)    | CHECK (`minute` BETWEEN 0 AND 59)        | Minute of the hour (0-59)             |

- **Tablespace**
  - `DIM_TBSP`
- **Partitioning**
  - No Partitioning
- **Indexing**
  - `index_dim_time_time_id`:
    - Column: `time_id`
    - Tablespace: `INDEX_TBSP`
    - Type: B-tree
    - Purpose:Index for pk
  - `index_dim_time_date`:
    - Column: `date`
    - Tablespace: `INDEX_TBSP`
    - Type: B-tree
    - Purpose:Speed up date-based queries
  - `index_dim_time_year_month`:
    - Column: (`year`, `month`)
    - Tablespace: `INDEX_TBSP`
    - Type: Composite Index
    - Purpose:Speed up year-month-based queries
  - `index_dim_time_hour`:
    - Column: `hour`
    - Tablespace: `INDEX_TBSP`
    - Type: Bitmap
    - Purpose: Speed up hour-based queries

---

## Dimension Table: `dim_station`

| Column Name    | Data Type     | Constraints  | Description                        |
| -------------- | ------------- | ------------ | ---------------------------------- |
| `station_id`   | NUMBER(6)     | PK, NOT NULL | Unique identifier for each station |
| `station_name` | VARCHAR2(100) | NOT NULL     | Name of the bike station           |

- **Tablespace**:
  - `DIM_TBSP`
- **Partitioning**:
  - No Partitioning
- **Indexing**:
  - `index_dim_station_station_id`:
    - Column: `station_id`
    - Tablespace: `INDEX_TBSP`
    - Type: B-tree
    - Purpose: Index for pk
  - `index_dim_station_station_name`:
    - Column: `station_name`
    - Tablespace: `INDEX_TBSP`
    - Type: B-tree
    - Purpose: Speed up station-name-based queries

---

## Dimension Table: `dim_bike`

| Column Name  | Data Type    | Constraints  | Description            |
| ------------ | ------------ | ------------ | ---------------------- |
| `bike_id`    | NUMBER(6)    | PK, NOT NULL | Unique bike identifier |
| `bike_model` | VARCHAR2(50) | NOT NULL     | Model/type of the bike |

- **Tablespace**:
  - `DIM_TBSP`
- **Partitioning**:
  - No Partitioning
- **Indexing**:
  - `index_dim_bike_bike_id`:
    - Column: `bike_id`
    - Tablespace: `INDEX_TBSP`
    - Type: B-tree
    - Purpose: Index for pk

---

## Dimension Table: `dim_user_type`

| Column Name    | Data Type    | Constraints      |
| -------------- | ------------ | ---------------- |
| `user_type_id` | NUMBER(3)    | PK, NOT NULL     |
| `user_type`    | VARCHAR2(50) | UNIQUE, NOT NULL |

- **Tablespace**:
  - `DIM_TBSP`
- **Partitioning**:
  - No Partitioning
- **Indexing**:
  - `index_dim_user_type_user_type_id`:
    - Column: `user_type_id`
    - Tablespace: `INDEX_TBSP`
    - Type: bitmap
    - Purpose: Index for pk

---

# Security & Access Control

- User Roles & Privileges

| Role       | Purpose              | Privileges                                  |
| ---------- | -------------------- | ------------------------------------------- |
| `app_dba`  | Database Admin       | Full DBA privileges                         |
| `app_dev`  | Developers           | Limited DML access to staging & fact tables |
| `api_user` | API/Web Query Access | Read-only access to fact & dimension tables |

---

# Backup Strategy

- Backup Plan

| Frequency | Type             | Details                              |
| --------- | ---------------- | ------------------------------------ |
| Daily     | Incremental      | Backup only changed data at midnight |
| Weekly    | Full Backup      | Full database backup every Sunday    |
| Monthly   | Archive Old Data | Move old CSVs to `/data/archive/`    |
| On Demand | Ad-hoc           | Before schema changes or large loads |
