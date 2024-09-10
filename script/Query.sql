SELECT ROUND((SPACE_USED - SPACE_RECLAIMABLE)/SPACE_LIMIT * 100, 4) AS PERCENT_FULL 
FROM V$RECOVERY_FILE_DEST;

ALTER SESSION SET container=toronto_shared_bike;

SELECT *
FROM app_admin.external_ridership;

SELECT *
FROM app_admin.staging_ridership;

SELECT *
FROM app_admin.dim_time
WHERE time_id >= 201901000000
  AND time_id < 201902000000
ORDER BY 1 desc;

SELECT *
FROM app_admin.dim_time
order by time_id desc;
subpartition(p_2019_jan);

SELECT *
FROM app_admin.fact_ridership
WHERE start_time_id >= 201901000000
  AND start_time_id < 201902000000;

create or replace directory exp_dir AS '/home/oracle/toronto_shared_bike/exp';
GRANT read, write ON DIRECTORY exp_dir TO app_admin;

/

/
EXEC app_admin.write_file();
/
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name => 'EXPORT_CSV_J',
    job_type => 'PLSQL_BLOCK',
    job_action => 'begin write_file; end;',
    number_of_arguments => 0,
    start_date => NULL,
    repeat_interval => 'FREQ=DAILY',
    end_date => NULL,
    enabled => FALSE,
    auto_drop => FALSE);

  DBMS_SCHEDULER.SET_ATTRIBUTE( 
    name => 'EXPORT_CSV_J', 
    attribute => 'logging_level', 
    value => DBMS_SCHEDULER.LOGGING_RUNS);
  
  DBMS_SCHEDULER.enable(
    name => 'EXPORT_CSV_J');
END;
/
SELECT
    *
    f.trip_id
    , f.trip_duration
    , st.full_time "start_time"
    , en.full_time "end_time"
FROM app_admin.fact_ridership f
JOIN app_admin.dim_time st
ON st.time_id = f.start_time_id
JOIN app_admin.dim_time en
ON en.time_id = f.end_time_id
JOIN f;
