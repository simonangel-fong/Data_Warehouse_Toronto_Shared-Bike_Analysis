#!/bin/bash

year_array=(2019 2020 2021 2022 2023)
for i in "${year_array[@]}"; do
    #    echo "$i"

    log_message "Year $i ETL job starts..."

    sqlplus -s / as sysdba <<EOF
    ALTER SESSION set container=toronto_shared_bike;
    CREATE OR REPLACE DIRECTORY load_dir AS '/home/oracle/data/$i';
    GRANT READ, WRITE ON DIRECTORY load_dir TO app_admin;
    exit;
EOF

    sqlplus / as sysdba <<EOF
    @job_etl.sql
    exit;
EOF

    log_message "Year $i ETL job completed."

done
