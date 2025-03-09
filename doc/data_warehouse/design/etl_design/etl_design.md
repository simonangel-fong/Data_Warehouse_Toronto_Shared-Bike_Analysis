# Toronto Bike Share Data Warehouse Documentation - ELT Design

[Back](../../../../README.md)

- [Toronto Bike Share Data Warehouse Documentation - ELT Design](#toronto-bike-share-data-warehouse-documentation---elt-design)
  - [Extraction (E)](#extraction-e)
  - [Load (L)](#load-l)
  - [Transformation (T)](#transformation-t)

---

## Extraction (E)

- Source:

  - /data/share_bike_trip/YYYY/Rider-\*.csv
  - CSV files are stored in a dedicated path.
  - Ensure appropriate read permissions for the database user.

- External Table: ext_ridership

| Column Name          | Data Type     | Description                                    |
| -------------------- | ------------- | ---------------------------------------------- |
| `trip_id`            | NUMBER        | Unique trip identifier (only used in raw data) |
| `trip_duration`      | NUMBER        | Trip duration in seconds                       |
| `start_station_id`   | NUMBER        | Start station reference                        |
| `start_time`         | DATE          | Raw trip start timestamp                       |
| `start_station_name` | VARCHAR2(100) | Start station name                             |
| `end_station_id`     | NUMBER        | End station reference                          |
| `end_time`           | DATE          | Raw trip end timestamp                         |
| `end_station_name`   | VARCHAR2(100) | End station name                               |
| `bike_id`            | VARCHAR2(50)  | Bike identifier                                |
| `user_type`          | VARCHAR2(20)  | User classification                            |

---

## Load (L)

- Staging Table: ridership_staging
  - Temporary storage with minimal transformations
- Table Structure:

| Column Name          | Data Type     | Description                                       |
| -------------------- | ------------- | ------------------------------------------------- |
| `trip_id`            | NUMBER        | Unique trip identifier (if retained for tracking) |
| `trip_duration`      | NUMBER        | Trip duration in seconds                          |
| `start_station_id`   | NUMBER        | Start station reference                           |
| `start_time`         | TIMESTAMP     | Standardized trip start timestamp                 |
| `start_station_name` | VARCHAR2(100) | Start station name                                |
| `end_station_id`     | NUMBER        | End station reference                             |
| `end_time`           | TIMESTAMP     | Standardized trip end timestamp                   |
| `end_station_name`   | VARCHAR2(100) | End station name                                  |
| `bike_id`            | VARCHAR2(50)  | Bike identifier                                   |
| `user_type`          | VARCHAR2(20)  | User classification                               |

- Basic Validation: Filtering Invalid Records
  - Exclude rows where critical values are NULL: `trip_duration`, `start_time`, `end_time`, `start_station_id`, `end_station_id`.
  - Ensure `trip_duration` > 0.

---

## Transformation (T)

- Data Quality Checks:

  - Table: ridership_staging
  - Rules:
    - Timestamp Standardization: Convert `start_time` and `end_time` to `YYYYMMDDHH24MI`.
    - Null Handling in Non-Critical Fields:
      - `bike_id`: Replace NULL with "Unknown".
      - `user_type`: Replace NULL with "Unknown".
      - `end_time`: If NULL, compute as start_time + trip_duration.
      - `model`:
        - Set NULL for records before February 2024.
        - Replace NULL with "Unknown" for records from February 2024 onward.

- Merge Strategy
  - Load validated data from ridership_staging into:
    - `fact_trip`
    - `dim_time`
    - `dim_station`
    - `dim_user_type`
    - `dim_bike`
  - Use `MERGE` or `INSERT INTO … SELECT` statement.
  - Performance Considerations: Ensure proper indexing on foreign keys and commonly queried columns for efficient joins.
