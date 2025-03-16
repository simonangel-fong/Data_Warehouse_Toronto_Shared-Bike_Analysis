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

| Column Name                  | Data Type  | Constraints                                  |
| ---------------------------- | ---------- | -------------------------------------------- |
| `fact_trip_id`               | NUMBER(10) | PK, GENERATED ALWAYS AS IDENTITY             |
| `fact_trip_source_id`        | NUMBER(10) | NOT NULL                                     |
| `fact_trip_duration`         | NUMBER(8)  | NOT NULL                                     |
| `fact_trip_start_time_id`    | NUMBER(12) | FK → `dim_time(time_id)`, NOT NULL           |
| `fact_trip_end_time_id`      | NUMBER(12) | FK → `dim_time(time_id)`, NOT NULL           |
| `fact_trip_start_station_id` | NUMBER(6)  | FK → `dim_station(station_id)`, NOT NULL     |
| `fact_trip_end_station_id`   | NUMBER(6)  | FK → `dim_station(station_id)`, NOT NULL     |
| `fact_trip_bike_id`          | NUMBER(6)  | FK → `dim_bike(bike_id)`, NOT NULL           |
| `fact_trip_user_type_id`     | NUMBER(3)  | FK → `dim_user_type(user_type_id)`, NOT NULL |

- Note:

  - `fact_trip_id`: surrogate key
  - `fact_trip_source_id`: the trip id in the source dataset, used for merge statement match condigtion.

- **Tablespace**

  - `FACT_TBSP`

- **Compression**

  - **Advanced Row Compression**:
    - `ROW STORE COMPRESS ADVANCED`
    - for read-heavy warehouses with rare updates.

- **Partitioning**

  - `fact_start_time_id`:
    - Partitioning: for Yearly query optimization.
    - Subpartitioning: by month for monthly query optimization.

- **Indexing**
  - Tablespace: `INDEX_TBSP`
  - Column: `fact_trip_start_time_id`
    - Type: Local B-tree
    - Purpose: Speed up time-based queries
  - Column: `fact_trip_start_station_id, fact_trip_end_station_id`
    - Type: Composite Index
    - Purpose: Speed up trip origins and destinations queries
  - Column: `fact_trip_user_type_id`
    - Tablespace: `INDEX_TBSP`
    - Type: Bitmap Index
    - Purpose: Speed up user-type-based queries
  - Column: `fact_trip_source_id`
    - Tablespace: `INDEX_TBSP`
    - Type: Bitmap Index
    - Purpose: Speed up source trip id query while merging new records.

---

## Dimension Table: `dim_time`

| Column Name          | Data Type  | Constraints                                 | Description                           |
| -------------------- | ---------- | ------------------------------------------- | ------------------------------------- |
| `dim_time_id`        | NUMBER(12) | PK                                          | Unique time identifier (YYYYMMDDHHMI) |
| `dim_time_timestamp` | DATE       | NOT NULL                                    | Canonical date representation         |
| `dim_time_year`      | NUMBER(4)  | NOT NULL                                    | Year (e.g., 2024)                     |
| `dim_time_quarter`   | NUMBER(1)  | NOT NULL, CHECK (`quarter` BETWEEN 1 AND 4) | Quarter of the year (1-4)             |
| `dim_time_month`     | NUMBER(2)  | NOT NULL, CHECK (`month` BETWEEN 1 AND 12)  | Month of the year (1-12)              |
| `dim_time_day`       | NUMBER(2)  | NOT NULL, CHECK (`day` BETWEEN 1 AND 31)    | Day of the month (1-31)               |
| `dim_time_week`      | NUMBER(2)  | NOT NULL, CHECK (`week` BETWEEN 1 AND 53)   | Week of the year (1-53)               |
| `dim_time_weekday`   | NUMBER(1)  | NOT NULL, CHECK (`weekday` BETWEEN 1 AND 7) | Day of the week                       |
| `dim_time_hour`      | NUMBER(2)  | NOT NULL, CHECK (`hour` BETWEEN 0 AND 23)   | Hour of the day (0-23)                |
| `dim_time_minute`    | NUMBER(2)  | NOT NULL, CHECK (`minute` BETWEEN 0 AND 59) | Minute of the hour (0-59)             |

- **Tablespace**
  - `DIM_TBSP`
- **Partitioning**
  - No Partitioning
- **Indexing**
  - Tablespace: `INDEX_TBSP`
  - Column: `dim_time_id`
    - Type: B-tree, pk index
    - Purpose:For PK lookups and joins.
  - Column: `dim_time_timestamp`
    - Type: B-tree
    - Purpose:Speed up date-based queries
  - Column: (`dim_time_year`, `dim_time_month`)
    - Type: Composite B-tree
    - Purpose:Speed up year-month-based queries

---

## Dimension Table: `dim_station`

| Column Name        | Data Type     | Constraints | Description                        |
| ------------------ | ------------- | ----------- | ---------------------------------- |
| `dim_station_id`   | NUMBER(6)     | PK          | Unique identifier for each station |
| `dim_station_name` | VARCHAR2(100) | NOT NULL    | Name of the bike station           |

- **Tablespace**:
  - `DIM_TBSP`
- **Partitioning**:
  - No Partitioning
- **Indexing**:
  - Tablespace: `INDEX_TBSP`
  - Column: `dim_station_id`
    - Type: B-tree, pk index
    - Purpose:For PK lookups and joins.
  - Column: `dim_station_name`
    - Type: B-tree
    - Purpose: Speed up station-name-based queries

---

## Dimension Table: `dim_bike`

| Column Name      | Data Type    | Constraints | Description            |
| ---------------- | ------------ | ----------- | ---------------------- |
| `dim_bike_id`    | NUMBER(6)    | PK          | Unique bike identifier |
| `dim_bike_model` | VARCHAR2(50) | NOT NULL    | Model/type of the bike |

- **Tablespace**:
  - `DIM_TBSP`
- **Partitioning**:
  - No Partitioning
- **Indexing**:
  - Tablespace: `INDEX_TBSP`
  - Column: `dim_bike_id`
    - Type: B-tree
    - Purpose: For PK lookups and joins.

---

## Dimension Table: `dim_user_type`

| Column Name          | Data Type    | Constraints                      |
| -------------------- | ------------ | -------------------------------- |
| `dim_user_type_id`   | NUMBER(3)    | PK, GENERATED ALWAYS AS IDENTITY |
| `dim_user_type_name` | VARCHAR2(50) | UNIQUE, NOT NULL                 |

- **Tablespace**:
  - `DIM_TBSP`
- **Partitioning**:
  - No Partitioning
- **Indexing**:
  - Tablespace: `INDEX_TBSP`
  - Column: `dim_user_type_id`
    - Type: B-tree
    - Purpose: For PK lookups and joins.

---

# Security & Access Control

- **Guiding Principles**
  **Least Privilege**: Grant only the permissions required for each role’s tasks.
  **Separation of Duties**: Distinct roles for administration, development/ETL, and querying to prevent overlap and reduce risk.
  **Granularity**: Apply privileges at schema or table level, avoiding overly broad access.
  **Auditability**: Enable tracking of critical actions (e.g., DDL, DML) for security and compliance.
  **Scalability**: Design roles to accommodate growth (e.g., new tables, users, or applications).
  **Warehouse-Specific**: Prioritize read-heavy access for analytics, write access for ETL, and full control for admins.

---

- **Roles and Privileges**

| Role          | Scope                                         | Privileges                                                                                           | Description                                         |
| ------------- | --------------------------------------------- | ---------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| `dw_admin`    | All warehouse objects                         | `CREATE`, `ALTER`, `DROP`, `GRANT`, `SELECT`, `INSERT`, `UPDATE`, `DELETE`, system privileges        | Manages warehouse structure and permissions.        |
| `dw_etl`      | Staging & fact tables, dimensions (read-only) | `SELECT`, `INSERT`, `UPDATE`, `DELETE` (staging & fact), `SELECT` (dimensions), `READ` (directories) | Executes ETL processes to load and transform data.  |
| `dw_analyst`  | Fact & dimension tables                       | `SELECT`                                                                                             | Performs ad-hoc queries and reporting for analysis. |
| `dw_app`      | Fact & dimension tables                       | `SELECT`                                                                                             | Provides data access for API/web applications.      |
| `dw_readonly` | Curated views                                 | `SELECT`                                                                                             | Grants safe, limited access for external users.     |

---

# Backup Strategy

- Backup Plan

| Component            | Strategy                         | Frequency                          | Retention              | Description                                         |
| -------------------- | -------------------------------- | ---------------------------------- | ---------------------- | --------------------------------------------------- |
| Full Backup          | Database-level backup            | Weekly                             | 1 month                | Captures entire warehouse for baseline recovery.    |
| Incremental Backup   | Cumulative incremental (Level 1) | Daily                              | 1 week                 | Backs up changes since last full backup.            |
| Archive Log Backup   | Redo log archiving               | Continuous (as generated)          | 2 weeks                | Enables point-in-time recovery for ETL updates.     |
| Export Backup        | Logical backup (Data Pump)       | Monthly                            | 3 months               | Exports key tables for offsite or granular restore. |
| Configuration Backup | Metadata & scripts               | Weekly or on change                | Indefinite (versioned) | Saves DDL, roles, and ETL scripts.                  |
| Offsite Storage      | Remote copy of backups           | Weekly (full), daily (incremental) | Same as primary        | Protects against site-level disasters.              |
