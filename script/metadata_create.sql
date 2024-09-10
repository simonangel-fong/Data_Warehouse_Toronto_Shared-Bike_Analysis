-- SQL script to create tables for metadata
-- sys, cdb

ALTER SESSION set container=toronto_shared_bike;
show user;
show con_name;

CREATE TABLE app_admin.metadata_table (
    table_id                NUMBER      PRIMARY KEY
    , table_name            VARCHAR2(50)
    , table_description     VARCHAR2(255)
    , created_at            TIMESTAMP
    , updated_at            TIMESTAMP
);

-- Insert for dim_time table
INSERT INTO app_admin.metadata_table (table_id, table_name, table_description, created_at, updated_at) 
VALUES (
    1
    , 'dim_time'
    , 'Dimension table for time details'
    , (
        SELECT created
        FROM dba_objects
        WHERE object_name = upper('dim_time')
        AND owner = upper('app_admin')
        AND object_type = 'TABLE'
    )
    , null
);

-- Insert for dim_station table
INSERT INTO app_admin.metadata_table (table_id, table_name, table_description, created_at, updated_at) 
VALUES (
    2
    , 'dim_station'
    , 'Dimension table for station details'
    , (
        SELECT created
        FROM dba_objects
        WHERE object_name = upper('dim_station')
        AND owner = upper('app_admin')
        AND object_type = 'TABLE'
    )
    , null
);

-- Insert for dim_bike table
INSERT INTO app_admin.metadata_table (table_id, table_name, table_description, created_at, updated_at) 
VALUES (
    3
    , 'dim_bike'
    , 'Dimension table for bike details'
    , (
        SELECT created
        FROM dba_objects
        WHERE object_name = upper('dim_bike')
        AND owner = upper('app_admin')
        AND object_type = 'TABLE'
    )
    , null
);

-- Insert for dim_user_type table
INSERT INTO app_admin.metadata_table (table_id, table_name, table_description, created_at, updated_at)
VALUES (
    4
    , 'dim_user_type'
    , 'Dimension table for user type details'
    , (
        SELECT created
        FROM dba_objects
        WHERE object_name = upper('dim_user_type')
        AND owner = upper('app_admin')
        AND object_type = 'TABLE'
    )
    , null
);

-- Insert for fact_ridership table
INSERT INTO app_admin.metadata_table (table_id, table_name, table_description, created_at, updated_at)
VALUES (
    5
    , 'fact_ridership'
    , 'Fact table storing ridership records'
    , (
        SELECT created
        FROM dba_objects
        WHERE object_name = upper('fact_ridership')
        AND owner = upper('app_admin')
        AND object_type = 'TABLE'
    )
    , null
);

COMMIT;


CREATE TABLE app_admin.metadata_column (
    column_id       NUMBER      PRIMARY KEY
    , table_id      NUMBER
    , column_name   VARCHAR2(50)
    , data_type     VARCHAR2(50)
    , nullable      VARCHAR2(3)
    , column_description VARCHAR2(255)
    , CONSTRAINT fk_table_name FOREIGN KEY (table_id) REFERENCES app_admin.metadata_table(table_id)
);

-- dim_time
-- Inserts for dim_time table
INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (1, 1, 'time_id', 'INT', 'NO', 'Primary key for time dimension');

INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (2, 1, 'full_time', 'TIMESTAMP', 'YES', 'Full timestamp of the event');

INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (3, 1, 'year', 'INT', 'YES', 'Year component of the timestamp');

INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (4, 1, 'month', 'INT', 'YES', 'Month component of the timestamp');

INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (5, 1, 'day', 'INT', 'YES', 'Day component of the timestamp');

INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (6, 1, 'hour', 'INT', 'YES', 'Hour component of the timestamp');

INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (7, 1, 'minute', 'INT', 'YES', 'Minute component of the timestamp');

INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (8, 1, 'quarter', 'INT', 'YES', 'Quarter of the year');

INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (9, 1, 'weekday', 'INT', 'YES', 'Day of the week');

-- Inserts for dim_station table
INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (10, 2, 'station_id', 'INT', 'NO', 'Primary key for station dimension');
INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (11, 2, 'station_name', 'VARCHAR2(100)', 'NO', 'Name of the station');

-- Inserts for dim_bike table
INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (12, 3, 'bike_id', 'NUMBER', 'NO', 'Primary key for bike dimension');

-- Inserts for dim_user_type table
INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (13, 4, 'user_type_id', 'NUMBER', 'NO', 'Primary key for user type dimension');
INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (14, 4, 'user_type', 'VARCHAR2(50)', 'NO', 'Type of user (e.g., subscriber, customer)');

-- Inserts for fact_ridership table
INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (15, 5, 'trip_id', 'NUMBER', 'NO', 'Primary key for ridership fact table');
INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (16, 5, 'trip_duration', 'NUMBER', 'YES', 'Duration of the trip in seconds');
INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (17, 5, 'start_time_id', 'NUMBER', 'YES', 'Foreign key to dim_time (start time)');
INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (18, 5, 'end_time_id', 'NUMBER', 'YES', 'Foreign key to dim_time (end time)');
INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (19, 5, 'start_station_id', 'NUMBER', 'YES', 'Foreign key to dim_station (start station)');
INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (20, 5, 'end_station_id', 'NUMBER', 'YES', 'Foreign key to dim_station (end station)');
INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (21, 5, 'bike_id', 'NUMBER', 'YES', 'Foreign key to dim_bike (bike used)');
INSERT INTO app_admin.metadata_column (column_id, table_id, column_name, data_type, nullable, column_description) 
VALUES (22, 5, 'user_type_id', 'NUMBER', 'YES', 'Foreign key to dim_user_type (user type)');

COMMIT;

-- trigger
CREATE OR REPLACE TRIGGER app_admin.trg_update_metadata_dim_time
AFTER INSERT OR UPDATE ON app_admin.dim_time
FOR EACH ROW
BEGIN
    UPDATE app_admin.metadata_table
    SET updated_at = SYSTIMESTAMP
    WHERE table_name = 'dim_time';
END;
/
CREATE OR REPLACE TRIGGER app_admin.trg_update_metadata_dim_station
AFTER INSERT OR UPDATE ON app_admin.dim_station
FOR EACH ROW
BEGIN
    UPDATE app_admin.metadata_table
    SET updated_at = SYSTIMESTAMP
    WHERE table_name = 'dim_station';
END;
/
CREATE OR REPLACE TRIGGER app_admin.trg_update_metadata_dim_bike
AFTER INSERT OR UPDATE ON app_admin.dim_bike
FOR EACH ROW
BEGIN
    UPDATE app_admin.metadata_table
    SET updated_at = SYSTIMESTAMP
    WHERE table_name = 'dim_bike';
END;
/
CREATE OR REPLACE TRIGGER app_admin.trg_update_metadata_dim_user_type
AFTER INSERT OR UPDATE ON app_admin.dim_user_type
FOR EACH ROW
BEGIN
    UPDATE app_admin.metadata_table
    SET updated_at = SYSTIMESTAMP
    WHERE table_name = 'dim_user_type';
END;
/
CREATE OR REPLACE TRIGGER app_admin.trg_update_metadata_fact_ridership
AFTER INSERT OR UPDATE ON app_admin.fact_ridership
FOR EACH ROW
BEGIN
    UPDATE app_admin.metadata_table
    SET updated_at = SYSTIMESTAMP
    WHERE table_name = 'fact_ridership';
END;
/

SELECT *
FROM app_admin.metadata_table;
--
--SELECT *
--FROM app_admin.metadata_column;



