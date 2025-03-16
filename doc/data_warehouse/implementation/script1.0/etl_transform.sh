#!/bin/bash

sqlplus -s / as sysdba <<EOF
@etl_transform.sql
exit;
EOF

log_message "Data has been transformed."
