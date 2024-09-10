
SET SERVEROUTPUT ON;
ALTER SESSION SET container=toronto_shared_bike;
show con_name;
show user;

DROP TABLE app_admin.external_ridership;
DROP DIRECTORY load_dir;

DROP TABLE app_admin.staging_ridership;
DROP TABLE app_admin.staging_tran_ridership;