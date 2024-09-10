#!/bin/bash





sqlplus -s / as sysdba <<EOF

SET SERVEROUTPUT ON;
ALTER SESSION SET container=toronto_shared_bike;
show con_name;
show user;

DROP TABLE app_admin.external_ridership PURGE;
DROP DIRECTORY load_dir;

DROP TABLE app_admin.staging_ridership PURGE;
DROP TABLE app_admin.staging_tran_ridership PURGE;

exit;
EOF

log_message "ETL Tables have been dropped."
