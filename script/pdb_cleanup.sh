#!/bin/bash

# Script Name: cleanup_pdb.sh
# Creator: Wenhao Fang
# This script:
# To clean up existing pdb

sqlplus -s / as sysdba <<EOF
@pdb_cleanup.sql
exit
EOF
log_message "PDB $P_APP_ADMIN has been dropped."
