#!/bin/bash

sqlplus -s / as sysdba <<EOF
@mv_cleanup.sql
exit;
EOF

log_message "MY has been cleaned up."
