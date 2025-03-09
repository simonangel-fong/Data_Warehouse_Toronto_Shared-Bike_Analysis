#!/bin/bash

sqlplus -s / as sysdba <<EOF
@mv_create.sql
exit;
EOF

log_message "MV has been created."
