# Toronto Bike Share Data Warehouse Documentation - Materialized Design

[Back](../../../../README.md)

- [Toronto Bike Share Data Warehouse Documentation - Materialized Design](#toronto-bike-share-data-warehouse-documentation---materialized-design)
  - [Materialized Design](#materialized-design)
    - [General](#general)
  - [KPI: Trip Volume Trends](#kpi-trip-volume-trends)
    - [KPI: Trip Duration Metrics](#kpi-trip-duration-metrics)
    - [KPI: Station Usage](#kpi-station-usage)
    - [KPI: Route Popularity](#kpi-route-popularity)
    - [KPI: Bike Utilization Rate](#kpi-bike-utilization-rate)
    - [KPI: User Segmentation](#kpi-user-segmentation)

---

## Materialized Design

### General

- **Storage**:

  - `MV_TBSP`
  - separated tablespace from `FACT_TBSP`, optimizes I/O.

- **Schema**:

  - `DW_SCHEMA`

- KPIs in the design require materialized views to improve query performance.

---

## KPI: Trip Volume Trends

- **Goal**:

  - Precompute the total number of trips to analyze temporal usage patterns across the bike-sharing system.

- **View Structure**: `MV_TIME_TRIP`

| Column        | Granularity | Description               |
| ------------- | ----------- | ------------------------- |
| `trip_count`  | -           | Total trip volume         |
| `dim_year`    | Year        | Long-term annual trends   |
| `dim_quarter` | Quarter     | Seasonal quarterly trends |
| `dim_month`   | Month       | Monthly usage patterns    |
| `dim_day`     | Day         | Daily trip fluctuations   |
| `dim_week`    | Week        | Weekly cycle trends       |
| `dim_weekday` | Weekday     | Weekday-specific trends   |
| `dim_hour`    | Hour        | Hourly peak trends        |

- Source query:

```sql
SELECT
    COUNT(*) AS trip_count,              -- Total trip volume
    t.dim_time_year AS dim_year,         -- Year (e.g., 2025)
    t.dim_time_quarter AS dim_quarter,   -- Quarter (1-4)
    t.dim_time_month AS dim_month,       -- Month (1-12)
    t.dim_time_day AS dim_day,           -- Day (1-31)
    t.dim_time_week AS dim_week,         -- Week (1-53, ISO)
    t.dim_time_weekday AS dim_weekday,   -- Weekday (1-7)
    t.dim_time_hour AS dim_hour          -- Hour (0-23)
FROM DW_SCHEMA.fact_trip f
JOIN DW_SCHEMA.dim_time t
    ON f.fact_trip_start_time_id = t.dim_time_id
GROUP BY
    t.dim_time_year,
    t.dim_time_quarter,
    t.dim_time_month,
    t.dim_time_day,
    t.dim_time_week,
    t.dim_time_weekday,
    t.dim_time_hour;
```

- **Refresh Strategy**:

  - `Fast refresh`
  - leverages materialized view logs on `fact_trip` and `dim_time` for incremental updates, ensuring ongoing temporal analysis with minimal overhead.

- **Tablespace**
  - `MV_TBSP`
- **Schema**
  - `DW_SCHEMA`
- **Partitioning**
  - `dim_year`
  - for Yearly query optimization.
- **Indexing**
  - Tablespace: `MV_TBSP`
  - Column: (`dim_year`, `dim_month`)
    - Type: Composite B-tree
    - Purpose: Speed up year-month-based queries
  - Column: `(dim_year, dim_hour)`
    - Type: Composite B-tree
    - Purpose: Speeds up hourly duration queries

---

### KPI: Trip Duration Metrics

- **Goal**:
  - Precompute the mean trip duration to analyze temporal usage patterns across the bike-sharing system.
- **View Structure**: `MV_TIME_DURATION`

| Column              | Granularity | Description                  |
| ------------------- | ----------- | ---------------------------- |
| `avg_trip_duration` | -           | Mean trip duration (seconds) |
| `dim_year`          | Year        | Long-term annual trends      |
| `dim_quarter`       | Quarter     | Seasonal quarterly trends    |
| `dim_month`         | Month       | Monthly usage patterns       |
| `dim_day`           | Day         | Daily duration fluctuations  |
| `dim_week`          | Week        | Weekly cycle trends          |
| `dim_weekday`       | Weekday     | Weekday-specific trends      |
| `dim_hour`          | Hour        | Hourly duration trends       |

- Source Query:

```sql
SELECT
    ROUND(AVG(f.fact_trip_duration),2) AS avg_trip_duration,  -- Mean trip duration (seconds)
    t.dim_time_year AS dim_year,                     -- Year (e.g., 2025)
    t.dim_time_quarter AS dim_quarter,               -- Quarter (1-4)
    t.dim_time_month AS dim_month,                   -- Month (1-12)
    t.dim_time_day AS dim_day,                       -- Day (1-31)
    t.dim_time_week AS dim_week,                     -- Week (1-53, ISO)
    t.dim_time_weekday AS dim_weekday,               -- Weekday (1-7)
    t.dim_time_hour AS dim_hour                      -- Hour (0-23)
FROM DW_SCHEMA.fact_trip f
JOIN DW_SCHEMA.dim_time t
    ON f.fact_trip_start_time_id = t.dim_time_id
GROUP BY
    t.dim_time_year,
    t.dim_time_quarter,
    t.dim_time_month,
    t.dim_time_day,
    t.dim_time_week,
    t.dim_time_weekday,
    t.dim_time_hour;
```

- **Refresh Strategy**:

  - `Complete refresh`
  - mean calculations require full recomputation; refreshed post-load for ongoing temporal analysis.

- **Tablespace**:
  - `MV_TBSP`
- **Schema**:
  - `DW_SCHEMA`
- **Partitioning**:
  - `dim_year`
  - optimizes yearly query performance and scalability.
- **Indexing**:
  - Tablespace: `MV_TBSP`
  - Column: `(dim_year, dim_month)`
    - Type: Composite B-tree
    - Purpose: Speeds up year-month-based duration queries
  - Column: `(dim_year, dim_hour)`
    - Type: Composite B-tree
    - Purpose: Speeds up hourly duration queries

---

### KPI: Station Usage

- **Goal**:

  - Precompute trip counts per station to identify the most and least busy stations in the bike-sharing system.

- **View Structure**: `MV_STATION_TRIP`

| Column              | Description                |
| ------------------- | -------------------------- |
| station_id          | Unique station identifier  |
| station_name        | Station name for reporting |
| trip_count_by_start | Trips starting at station  |
| trip_count_by_end   | Trips ending at station    |

- **Source Query**:

```sql
SELECT
    s.dim_station_id AS station_id,                  -- Unique station identifier
    s.dim_station_name AS station_name,              -- Station name for reporting
    COUNT(CASE WHEN f.fact_trip_start_station_id = s.dim_station_id THEN 1 END) AS trip_count_by_start,  -- Trips starting at station
    COUNT(CASE WHEN f.fact_trip_end_station_id = s.dim_station_id THEN 1 END) AS trip_count_by_end       -- Trips ending at station
FROM DW_SCHEMA.fact_trip f
JOIN DW_SCHEMA.dim_station s
    ON s.dim_station_id IN (f.fact_trip_start_station_id, f.fact_trip_end_station_id)
GROUP BY
    s.dim_station_id,
    s.dim_station_name;
```

- **Refresh Strategy**:
  - `Fast refresh`
  - leverages materialized view logs on `fact_trip` and `dim_station` for incremental updates, supporting ongoing station usage analysis.
- **Tablespace**:
  - `MV_TBSP`
- **Schema**:
  - `DW_SCHEMA`
- **Partitioning**:
  - None
- **Indexing**:
  - None

---

### KPI: Route Popularity

- **Goal**:
  - Precompute trip counts between station pairs to identify the popular routes in the bike-sharing system.
- **View Structure**: `MV_ROUTE`

| Column               | Description                 |
| -------------------- | --------------------------- |
| `start_station_id`   | Starting station identifier |
| `start_station_name` | Starting station name       |
| `end_station_id`     | Ending station identifier   |
| `end_station_name`   | Ending station name         |
| `trip_count`         | Number of trips on route    |

- **Source Query**:

```sql
SELECT
    s_start.dim_station_id AS start_station_id,         -- Starting station identifier
    s_start.dim_station_name AS start_station_name,     -- Starting station name
    s_end.dim_station_id AS end_station_id,             -- Ending station identifier
    s_end.dim_station_name AS end_station_name,         -- Ending station name
    COUNT(*) AS trip_count                              -- Number of trips on route
FROM DW_SCHEMA.fact_trip f
JOIN DW_SCHEMA.dim_station s_start
    ON f.fact_trip_start_station_id = s_start.dim_station_id
JOIN DW_SCHEMA.dim_station s_end
    ON f.fact_trip_end_station_id = s_end.dim_station_id
GROUP BY
    s_start.dim_station_id,
    s_start.dim_station_name,
    s_end.dim_station_id,
    s_end.dim_station_name;
```

- **Refresh Strategy**:
  - `Fast refresh`
  - leverages materialized view logs on `fact_trip` and `dim_station` for incremental updates, supporting ongoing route popularity analysis.
- **Tablespace**:
  - `MV_TBSP`
- **Schema**:
  - `DW_SCHEMA`
- **Partitioning**:
  - None
- **Indexing**:
  - None

---

### KPI: Bike Utilization Rate

- **Goal**:

  - Precompute total trips and mean duration per bike to evaluate utilization rates in the bike-sharing system.

- **View Structure**: `MV_BIKE_TRIP_DURATION`

| Column              | Description                  |
| ------------------- | ---------------------------- |
| `bike_id`           | Unique bike identifier       |
| `trip_count`        | Total trips per bike         |
| `avg_trip_duration` | Mean trip duration (seconds) |

- **Source Query**:

```sql
SELECT
    b.dim_bike_id AS bike_id,                    -- Unique bike identifier
    COUNT(*) AS trip_count,                      -- Total trips per bike
    ROUND(AVG(f.fact_trip_duration),2) AS avg_trip_duration  -- Mean trip duration (seconds)
FROM DW_SCHEMA.fact_trip f
JOIN DW_SCHEMA.dim_bike b
    ON f.fact_trip_bike_id = b.dim_bike_id
GROUP BY
    b.dim_bike_id;
```

- **Refresh Strategy**:
  - `Complete refresh`
  - averages (AVG) require full recomputation; refreshed post-load for ongoing utilization analysis.
- **Tablespace**:
  - `MV_TBSP`
- **Schema**:
  - `DW_SCHEMA`
- **Partitioning**:
  - None
- **Indexing**:
  - None

---

### KPI: User Segmentation

- **Goal**:

  - Precompute total trips and mean duration by user type to evaluate user segmentation in the bike-sharing system.

- **View Structure**: `MV_USER_SEGMENTATION`

| Column              | Description                           |
| ------------------- | ------------------------------------- |
| `user_type_id`      | Unique user type identifier           |
| `user_type_name`    | User type name (e.g., Casual, Member) |
| `year`              | Year of trips (e.g., 2025)            |
| `trip_count`        | Total trips per user type             |
| `avg_trip_duration` | Mean trip duration (seconds)          |

- **Source Query**:

```sql
SELECT
    u.dim_user_type_id AS user_type_id,           -- Unique user type identifier
    u.dim_user_type_name AS user_type_name,       -- User type name (e.g., Casual, Member)
    t.dim_time_year AS year,                      -- Year of trips (e.g., 2025)
    COUNT(*) AS trip_count,                       -- Total trips per user type and year
    AVG(f.fact_trip_duration) AS avg_trip_duration  -- Mean trip duration (seconds)
FROM DW_SCHEMA.fact_trip f
JOIN DW_SCHEMA.dim_user_type u
    ON f.fact_trip_user_type_id = u.dim_user_type_id
JOIN DW_SCHEMA.dim_time t
    ON f.fact_trip_start_time_id = t.dim_time_id
GROUP BY
    u.dim_user_type_id,
    u.dim_user_type_name,
    t.dim_time_year;
```

- **Refresh Strategy**:

  - `Complete refresh`
  - averages (AVG) require full recomputation; refreshed post-load for ongoing segmentation analysis.

- **Tablespace**:
  - `MV_TBSP`
- **Schema**:
  - `DW_SCHEMA`
- **Partitioning**:
  - None
- **Indexing**:
  - None
