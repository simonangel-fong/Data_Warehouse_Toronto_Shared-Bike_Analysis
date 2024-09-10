#!/bin/bash

. ./parameters.sh

. ./archivelog_cleanup.sh

sqlplus -s / as sysdba <<EOF
@project_init.sql
exit
EOF

log_message "The project PDB has been initialized."
