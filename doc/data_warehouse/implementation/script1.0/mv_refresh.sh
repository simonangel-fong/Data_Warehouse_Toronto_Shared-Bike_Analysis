#!/bin/bash

sqlplus -s / as sysdba <<EOF
@mv_refresh.sql
exit;
EOF

log_message "MV has been refreshed."
