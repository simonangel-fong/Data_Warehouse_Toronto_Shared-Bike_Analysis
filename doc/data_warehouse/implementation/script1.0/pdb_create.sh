#!/bin/bash

# Script Name: init_db.sh
# Creator: Wenhao Fang
# This script:
# Initialize PDB and create admin

# Import parameters
source ./parameters.sh

P_PDB_ADMIN="pdb_admin"
P_PDB_ADMIN_PWD="welcome"

P_APP_ADMIN="app_admin"
P_APP_ADMIN_PWD="welcome"

P_LOG_DIR="log_dir"

######## Create PDB for project ########

log_message "Creating Project PDB $toronto_shared_bike..."

sqlplus -s / as sysdba <<EOF
CREATE PLUGGABLE DATABASE $PROJECT_NAME
    ADMIN USER $P_PDB_ADMIN IDENTIFIED BY $P_PDB_ADMIN_PWD ROLES=(DBA)
    DEFAULT TABLESPACE users
    DATAFILE '$PROJECT_ORCL_DATAFILE' 
    SIZE 1M AUTOEXTEND ON NEXT 1M
    FILE_NAME_CONVERT = ('$SEED_ORCL_PATH/',
                        '$PROJECT_ORCL_PATH/');

-- Open the PDB
ALTER PLUGGABLE DATABASE $PROJECT_NAME OPEN;

-- Save the state of the PDB so it opens automatically after a CDB restart
ALTER PLUGGABLE DATABASE $PROJECT_NAME SAVE STATE;
exit;
EOF

log_message "Project PDB $toronto_shared_bike has been created."
log_message "--------"
######## Create users ########

log_message "Creating User $P_APP_ADMIN..."

sqlplus -s / as sysdba <<EOF
-- Connect to the PDB as the admin user
ALTER SESSION SET CONTAINER = $PROJECT_NAME;

-- Create Application Admin User
-- DROP USER $P_APP_ADMIN CASCADE;
CREATE USER $P_APP_ADMIN
    IDENTIFIED BY $P_APP_ADMIN_PWD
    DEFAULT TABLESPACE users
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON users;

-- Grant privileges to Application Admin
GRANT CONNECT, RESOURCE TO $P_APP_ADMIN;
exit;
EOF

log_message "User $P_APP_ADMIN has been created."
log_message "--------"

######## Create Oracle procedure for logging ########

log_message "Creating procedure write_log..."

sqlplus -s / as sysdba <<EOF
ALTER SESSION SET CONTAINER = $PROJECT_NAME;
CREATE OR REPLACE DIRECTORY $P_LOG_DIR AS '$LOG_BASE_PATH';
GRANT READ, WRITE ON DIRECTORY $P_LOG_DIR TO $P_APP_ADMIN;

CREATE OR REPLACE PROCEDURE $P_APP_ADMIN.write_log (p_message IN VARCHAR2) IS
  v_file UTL_FILE.FILE_TYPE;
  v_filename VARCHAR2(50) := '$LOG_FILE';
BEGIN
  -- Open the file for appending text
  v_file := UTL_FILE.FOPEN('$LOG_BASE_PATH', v_filename, 'A');

  -- Write the message to the file
  UTL_FILE.PUT_LINE(v_file, TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') || ' - ' || p_message);

  -- Close the file
  UTL_FILE.FCLOSE(v_file);
EXCEPTION
  WHEN OTHERS THEN
    -- Handle exceptions (e.g., file not found, no permission, etc.)
    IF UTL_FILE.IS_OPEN(v_file) THEN
      UTL_FILE.FCLOSE(v_file);
    END IF;
    RAISE;
END write_log;

exit;
EOF

log_message "Procedure write_log has been created."
log_message "--------"
