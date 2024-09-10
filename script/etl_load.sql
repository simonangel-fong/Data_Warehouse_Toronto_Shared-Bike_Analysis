-- SQL script to load transformed data from staging area to warehouse schema.
-- User = dba, container = root

ALTER SESSION SET container=toronto_shared_bike;
show con_name;
show user;

-- Load date
MERGE INTO app_admin.dim_time tgt
USING (
    SELECT DISTINCT
        TO_NUMBER(TO_CHAR(start_time, 'YYYYMMDDHH24MI')) "TIME_ID",
        start_time "FULL_TIME",
        EXTRACT(YEAR FROM start_time) "YEAR",
        EXTRACT(MONTH FROM start_time) "MONTH",
        EXTRACT(DAY FROM start_time) "DAY",
        EXTRACT(HOUR FROM start_time) "HOUR",
        EXTRACT(MINUTE FROM start_time) "MINUTE",
        TO_NUMBER(TO_CHAR(start_time, 'Q')) "QUARTER",
        TO_NUMBER(TO_CHAR(start_time, 'D')) "WEEKDAY"
    FROM app_admin.staging_tran_ridership
    UNION
    SELECT DISTINCT
        TO_NUMBER(TO_CHAR(end_time, 'YYYYMMDDHH24MI')) "TIME_ID",
        end_time "FULL_TIME",
        EXTRACT(YEAR FROM end_time) "YEAR",
        EXTRACT(MONTH FROM end_time) "MONTH",
        EXTRACT(DAY FROM end_time) "DAY",
        EXTRACT(HOUR FROM end_time) "HOUR",
        EXTRACT(MINUTE FROM end_time) "MINUTE",
        TO_NUMBER(TO_CHAR(end_time, 'Q')) "QUARTER",
        TO_NUMBER(TO_CHAR(end_time, 'D')) "WEEKDAY"
    FROM app_admin.staging_tran_ridership
) src
ON (tgt.TIME_ID = src.TIME_ID)
WHEN MATCHED THEN
    UPDATE SET
        tgt.FULL_TIME = src.FULL_TIME,
        tgt.YEAR = src.YEAR,
        tgt.MONTH = src.MONTH,
        tgt.DAY = src.DAY,
        tgt.HOUR = src.HOUR,
        tgt.MINUTE = src.MINUTE,
        tgt.QUARTER = src.QUARTER,
        tgt.WEEKDAY = src.WEEKDAY
WHEN NOT MATCHED THEN
    INSERT (
        TIME_ID,
        FULL_TIME,
        YEAR,
        MONTH,
        DAY,
        HOUR,
        MINUTE,
        QUARTER,
        WEEKDAY
    )
    VALUES (
        src.TIME_ID,
        src.FULL_TIME,
        src.YEAR,
        src.MONTH,
        src.DAY,
        src.HOUR,
        src.MINUTE,
        src.QUARTER,
        src.WEEKDAY
    );

COMMIT;

-- Load station
DECLARE
    CURSOR station_cur is
        SELECT DISTINCT
            start_station_id "STATION_ID", 
            start_station_name "STATION_NAME"
        FROM app_admin.staging_tran_ridership
        UNION
        SELECT DISTINCT
            end_station_id "STATION_ID", 
            end_station_name "STATION_NAME"
        FROM app_admin.staging_tran_ridership
        ORDER BY STATION_ID;
        
    v_station_id NUMBER;
    v_station_name VARCHAR2(100);
    v_count NUMBER := 0;
BEGIN
    OPEN station_cur; 
    LOOP
        FETCH station_cur INTO v_station_id, v_station_name;
        EXIT WHEN station_cur%notfound;
        
        v_count := 0;
        SELECT count(*) INTO v_count
        FROM app_admin.dim_station
        WHERE station_id = v_station_id;
        
        IF v_count > 0 THEN
            -- if exist
            UPDATE app_admin.dim_station SET
                station_name = v_station_name
            WHERE station_id = v_station_id;
        ELSE
            INSERT INTO app_admin.dim_station(station_id, station_name)
            VALUES (v_station_id, v_station_name);
        END IF;
        
    END LOOP; 
    CLOSE station_cur;
    
    COMMIT;
END;
/
-- Load user type
DECLARE
    CURSOR cur_usertype IS
        SELECT DISTINCT 
            TRIM(user_type)
        FROM app_admin.staging_tran_ridership;
    v_count NUMBER;
    v_usertype VARCHAR2(50);
    v_rownum NUMBER;
BEGIN
    OPEN cur_usertype;
    LOOP
        FETCH cur_usertype INTO v_usertype;
        EXIT WHEN cur_usertype%notfound;
        
        SELECT count(*) INTO v_rownum
        FROM app_admin.dim_user_type;
        
        SELECT count(*) INTO v_count
        FROM app_admin.dim_user_type
        WHERE user_type = v_usertype;
        
        IF v_count = 0 THEN
            v_rownum := v_rownum + 1;
            INSERT INTO app_admin.dim_user_type(user_type_id, user_type)
            VALUES (v_rownum, v_usertype);
        END IF;
    END LOOP;
    CLOSE cur_usertype;
    
    COMMIT;
END;
/
MERGE INTO app_admin.dim_bike tgt
USING (
    SELECT DISTINCT
        bike_id
    FROM app_admin.staging_tran_ridership
) scr
ON(tgt.bike_id = scr.bike_id)
WHEN NOT MATCHED THEN
    INSERT (bike_id)
    VALUES (scr.bike_id);

COMMIT;

/
MERGE INTO app_admin.fact_ridership tgt
USING (
    SELECT 
        trip_id "TRIP_ID"
        , trip_duration "TRIP_DURATION"
        , TO_NUMBER(TO_CHAR(start_time, 'YYYYMMDDHH24MI')) "START_TIME_ID"
        , TO_NUMBER(TO_CHAR(end_time, 'YYYYMMDDHH24MI')) "END_TIME_ID"
        , start_station_id "START_STATION_ID"
        , end_station_id "END_STATION_ID"
        , bike_id "BIKE_ID"
        , dim.user_type_id "USER_TYPE_ID"
    FROM app_admin.staging_tran_ridership stg
    JOIN app_admin.dim_user_type dim
    ON stg.user_type = dim.user_type
) src
ON (tgt.trip_id = src.trip_id)
WHEN MATCHED THEN
    UPDATE SET
        tgt.trip_duration = src.trip_duration
        , tgt.start_time_id = src.start_time_id
        , tgt.end_time_id = src.end_time_id
        , tgt.start_station_id = src.start_station_id
        , tgt.end_station_id = src.end_station_id
        , tgt.BIKE_ID = src.BIKE_ID
        , tgt.user_type_id = src.user_type_id
WHEN NOT MATCHED THEN
    INSERT (
        trip_id
        , trip_duration
        , start_time_id
        , end_time_id
        , start_station_id
        , end_station_id
        , bike_id
        , user_type_id
    )
    VALUES (
        src.trip_id
        , src.trip_duration
        , src.start_time_id
        , src.end_time_id
        , src.start_station_id
        , src.end_station_id
        , src.bike_id
        , src.USER_TYPE_ID
    );

COMMIT;
