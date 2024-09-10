#!/bin/bash

sqlplus -s / as sysdba <<EOF
@etl_load.sql
exit;
EOF

log_message "Data has been loaded."
