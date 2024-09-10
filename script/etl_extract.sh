#!/bin/bash

sqlplus -s / as sysdba <<EOF
@elt_extract.sql
exit;
EOF

log_message "Data has been extracted."
