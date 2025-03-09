# Toronto Bike Share Data Warehouse Documentation - Logical Design

[Back](../../../../README.md)

- [Toronto Bike Share Data Warehouse Documentation - Logical Design](#toronto-bike-share-data-warehouse-documentation---logical-design)
  - [Data Modeling Approach](#data-modeling-approach)
  - [Entity Definitions](#entity-definitions)
    - [Fact Entity](#fact-entity)
    - [Dimension Entities](#dimension-entities)
      - [Dimension Table: `Time`](#dimension-table-time)
      - [Dimension Table: `Stations`](#dimension-table-stations)
      - [Dimension Table: `Users`](#dimension-table-users)
      - [Dimension Table: `Bikes`](#dimension-table-bikes)
    - [Granularity](#granularity)
    - [Relationships (ERD)](#relationships-erd)
  - [Data Transformation Rules](#data-transformation-rules)

---

## Data Modeling Approach

- **Objective**: Establish the data modeling framework for the Toronto bike share data warehouse to support efficient analytical queries.
- **Approach**:
  - Adopt a `star schema`, with a central fact table ("Trips") surrounded by dimension tables ("Time," "Stations," "Users," "Bikes").
- **Alternatives Considered**:
  - `Snowflake Schema`: Normalizes the "Time" dimension into separate tables (e.g., Year, Month) to reduce redundancy.
- **Rationale for Star Schema**:
  - Aligns with data warehouse best practices for scalability and usability given the dataset’s analytical focus.
  - Prioritizes query performance with a denormalized structure, enabling faster multi-dimensional analysis (e.g., trip volume by station and time) via fewer joins.
  - Accepts controlled redundancy (e.g., full Time attributes in one table) over the snowflake schema’s complex joins, optimizing for speed over storage efficiency.
  - Trade-off: denormalization increases storage but enhances query speed

---

## Entity Definitions

Define the fact and dimension entities, including their attributes, to structure the Toronto bike share data warehouse for efficient analytical queries.

### Fact Entity

The fact entity captures measurable data for each bike trip, supporting KPIs like trip volume and average duration.

- Fact Table: `Trips`

| Attribute Name     | Description                         | Data Type |
| ------------------ | ----------------------------------- | --------- |
| `Trip_ID`          | Unique identifier for each trip     | Integer   |
| `Trip_Duration`    | Length of the trip in seconds       | Integer   |
| `Start_Time_ID`    | Foreign key to Dim_Time (start)     | Integer   |
| `End_Time_ID`      | Foreign key to Dim_Time (end)       | Integer   |
| `Start_Station_ID` | Foreign key to Dim_Stations (start) | Integer   |
| `End_Station_ID`   | Foreign key to Dim_Stations (end)   | Integer   |
| `Bike_ID`          | Foreign key to Dim_Bikes            | Integer   |
| `User_Type_ID`     | Foreign key to Dim_Users            | Integer   |

- **Note**
  - `End_Time_ID`:
    - **Precision Consideration**: Start/End times are precise to minutes, while duration is in seconds; ensure consistency during transformation.
    - **Issue**: End time can be derived from Start Time and Trip Duration.
    - **Action**: Retain for query performance, enabling faster analysis despite redundancy.

---

### Dimension Entities

Dimension entities provide descriptive context for analysis, enabling multi-dimensional queries across time, location, user types, and bikes.

#### Dimension Table: `Time`

| Attribute Name  | Description                    | Data Type |
| --------------- | ------------------------------ | --------- |
| `Time_ID`       | Primary key for time records   | Integer   |
| `Date`          | Date of the trip (YYYY-MM-DD)  | Datetime  |
| `Year`          | Year of the trip               | Integer   |
| `Month`         | Month number (1-12)            | Integer   |
| `Month_Name`    | Month name (e.g., January)     | Varchar   |
| `Date_of_Month` | Day of the month (1-31)        | Integer   |
| `Week_of_Year`  | Week number in the year        | Integer   |
| `Day_of_Week`   | Day number (0-6)               | Integer   |
| `Weekday`       | Day of the week (e.g., Monday) | Varchar   |
| `Hour`          | Hour of the day (0-23)         | Integer   |

- **Note**:
  - Minute attribute omitted as data precision is at the minute level (per Data Profile);
  - Hoever, finer granularity is not required for analysis.

---

#### Dimension Table: `Stations`

| Attribute Name | Description                     | Data Type |
| -------------- | ------------------------------- | --------- |
| `Station_ID`   | Primary key for station records | Integer   |
| `Station_Name` | Name of the station             | Varchar   |

---

#### Dimension Table: `Users`

| Attribute Name | Description                           | Data Type |
| -------------- | ------------------------------------- | --------- |
| `User_Type_ID` | Primary key for user types            | Integer   |
| `User_Type`    | Rider category (e.g., Casual, Annual) | Varchar   |

---

#### Dimension Table: `Bikes`

| Attribute Name | Description                      | Data Type |
| -------------- | -------------------------------- | --------- |
| `Bike_ID`      | Primary key for bike records     | Integer   |
| `Bike_Model`   | Model of the bike (e.g., ICONIC) | Varchar   |

---

### Granularity

- **Definition**: The finest level of detail in the fact table is at the individual trip level, uniquely identified by `Trip_ID`.
- **Purpose**: Enables detailed analysis (e.g., trip volume by hour, station usage) while supporting aggregation for higher-level insights.

---

### Relationships (ERD)

![pic](./pic/Logical_design_ERD.png)

---

## Data Transformation Rules

- **Description**:
  - Define rules to clean and enrich raw trip data from the source dataset for consistency in the Toronto bike share data warehouse.
- **Focus**: Source dataset
- **Rules**:

1. **Standardize Timestamps**
   - **Issue**: Timestamps are in different formats.
   - **Action**: Convert to YYYY-MM-DD HH:MM:SS format, ensuring minute-level precision.
   - **Columns**:
     - `start_time`,
     - `end_time`
2. **Validate Duration Precision**
   - **Issue**: Negative or zero values in duration.
   - **Action**: Remove records with negative or zero `trip_duration`.
   - **Columns**:
     - `trip_duration`
3. **Normalize Station Name**
   - **Issue**: Station names may vary over time, assuming `station_id` remains consistent.
   - **Action**: Overwrite earlier `start_station_id/name` and `end_station_id/name` with the latest values for uniformity.
   - **Columns**:
     - `start_station_id/name`,
     - `end_station_id/name`
4. **Handle Null in Key Attributes**
   - **Issue**: Missing values in critical fields lead to non-meaningful outcomes (e.g., null `start_time` invalidates temporal analysis).
   - **Action**: Remove records with null or missing values.
   - **Columns**:
     - `start_time`,
     - `end_time`,
     - `start_station_id/name`,
     - `end_station_id/name`,
     - `trip_duration`
5. **Substitute Null in Non-Key Attributes**
   - **Issue**: Missing values in non-critical fields lead to non-precise but meaningful outcomes (e.g., null `bike_id` still allows trip analysis).
   - **Action**: Replace null/NA with dummy values.
   - **Columns**:
     - `end_time`: Replace with `start_time + trip_duration`.
     - `bike_id`: Replace with "Unknown".
     - `user_type`: Replace with "Unknown".
6. **Handle Bike Model Availability**
   - **Issue**: `model` data is not available before February 2024, and post-February 2024 nulls indicate an unknown model.
   - **Action**:
     - Set `model` to null for data before February 2024, reflecting unavailability.
     - Replace null/NA in `model` with "Unknown" for data from February 2024 onward, indicating an existing but unknown model.
   - **Columns**: `model`
