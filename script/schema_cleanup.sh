#!/bin/bash

sqlplus -s / as sysdba <<EOF
@schema_cleanup.sql
exit
EOF

log_message "Data warehouse schema has been removed."
