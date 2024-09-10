#!/bin/bash

sqlplus -s / as sysdba <<EOF
@schema_create.sql
exit
EOF

log_message "Data warehouse schema has been created."
