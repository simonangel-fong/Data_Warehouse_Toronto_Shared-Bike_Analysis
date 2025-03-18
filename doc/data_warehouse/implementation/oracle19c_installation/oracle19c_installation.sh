#!/bin/bash

set -e          # Exit on error
set -o pipefail # Exit if any command fails in a pipeline
set -u          # Treat unset variables as an error

# Variables
ORACLE_HOST_IP="192.168.128.50"
ORACLE_HOSTNAME="Argus-HomeLab"
ORACLE_BASE="/u01/app/oracle"
ORACLE_HOME="${ORACLE_BASE}/product/19.0.0/dbhome_1"
ORA_INVENTORY="/u01/app/oraInventory"
DATA_DIR="/u02/oradata"
ORACLE_UNQNAME="cdb1"
ORACLE_SID="cdb1"
PDB_NAME="pdb1"
INSTALLER_ZIP="/tmp/LINUX.X64_193000_db_home.zip"
ROOT_USER="root"
ORACLE_USER="oracle"
ORACLE_GROUP="oinstall"
DBA_GROUP="dba"
SYS_PASSWORD="SysPassword1"
PDB_PASSWORD="PdbPassword1"

# Add host entry
echo "${ORACLE_HOST_IP} ${ORACLE_HOSTNAME}" >>/etc/hosts

# Update and install prerequisites
yum update -y
yum install -y oracle-database-preinstall-19c

# Create necessary directories
mkdir -pv ${ORACLE_BASE}
mkdir -pv ${ORACLE_HOME}
mkdir -pv ${ORA_INVENTORY}
mkdir -pv ${DATA_DIR}

# Set ownership and permissions
chown -Rv ${ORACLE_USER}:${ORACLE_GROUP} /u01 /u02
chmod -Rv 775 /u01 /u02

# Create Oracle environment setup script
mkdir -p /home/${ORACLE_USER}/scripts
cat >/home/${ORACLE_USER}/scripts/setEnv.sh <<EOF
# Oracle Settings
export TMP=/tmp
export TMPDIR=\$TMP

export ORACLE_HOSTNAME=${ORACLE_HOSTNAME}
export ORACLE_BASE=${ORACLE_BASE}
export ORACLE_HOME=${ORACLE_HOME}
export ORA_INVENTORY=${ORA_INVENTORY}
export DATA_DIR=${DATA_DIR}

export ORACLE_UNQNAME=${ORACLE_UNQNAME}
export ORACLE_SID=${ORACLE_SID}
export PDB_NAME=${PDB_NAME}

export PATH=/usr/sbin:/usr/local/bin:\$PATH
export PATH=\$ORACLE_HOME/bin:\$PATH

export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib
EOF

echo ". /home/${ORACLE_USER}/scripts/setEnv.sh" >>/home/${ORACLE_USER}/.bash_profile

# Set ownership and permissions
chown -R ${ORACLE_USER}:${ORACLE_GROUP} /home/${ORACLE_USER}/scripts
chmod u+x /home/${ORACLE_USER}/scripts/*.sh

# Switch to oracle user and unzip the installer
su - ${ORACLE_USER} -c "unzip -oq ${INSTALLER_ZIP} -d ${ORACLE_HOME}"

# # Set Oracle Home
# echo "export ORACLE_HOME=${ORACLE_HOME}" >> /home/${ORACLE_USER}/.bashrc
# source /home/${ORACLE_USER}/.bashrc

# Run installer in silent mode
export CV_ASSUME_DISTID=OEL7.6
su - ${ORACLE_USER} -c "${ORACLE_HOME}/runInstaller -silent -responseFile ${ORACLE_HOME}/install/response/db_install.rsp  \
    oracle.install.option=INSTALL_DB_SWONLY                 \
    ORACLE_HOSTNAME=${ORACLE_HOSTNAME}                      \
    UNIX_GROUP_NAME=${ORACLE_GROUP}                         \
    INVENTORY_LOCATION=${ORA_INVENTORY}                     \
    SELECTED_LANGUAGES=en,en_GB                             \
    ORACLE_HOME=${ORACLE_HOME}                              \
    ORACLE_BASE=${ORACLE_BASE}                              \
    oracle.install.db.InstallEdition=EE                     \
    oracle.install.db.OSDBA_GROUP=${DBA_GROUP}              \
    oracle.install.db.OSBACKUPDBA_GROUP=${DBA_GROUP}        \
    oracle.install.db.OSDGDBA_GROUP=${DBA_GROUP}            \
    oracle.install.db.OSKMDBA_GROUP=${DBA_GROUP}            \
    oracle.install.db.OSRACDBA_GROUP=${DBA_GROUP}           \
    oracle.install.db.OSOPER_GROUP=${DBA_GROUP}             \
    SECURITY_UPDATES_VIA_MYORACLESUPPORT=false              \
    DECLINE_SECURITY_UPDATES=true"

# Run root scripts
su - ${ROOT_USER} -c "${ORA_INVENTORY}/orainstRoot.sh"
su - ${ROOT_USER} -c "${ORACLE_HOME}/root.sh"

# Create database
su - ${ORACLE_USER} -c "dbca -silent -createDatabase \
     -templateName General_Purpose.dbc \
     -gdbname ${ORACLE_SID} -sid ${ORACLE_SID} -responseFile NO_VALUE \
     -characterSet AL32UTF8 \
     -sysPassword ${SYS_PASSWORD} \
     -systemPassword ${SYS_PASSWORD} \
     -createAsContainerDatabase true \
     -numberOfPDBs 1 \
     -pdbName ${PDB_NAME} \
     -pdbAdminPassword ${PDB_PASSWORD} \
     -databaseType MULTIPURPOSE \
     -memoryMgmtType auto_sga \
     -totalMemory 2000 \
     -storageType FS \
     -datafileDestination ${DATA_DIR} \
     -redoLogFileSize 50 \
     -emConfiguration NONE \
     -ignorePreReqs"

# Configure oratab for auto-startup
echo "${ORACLE_SID}:${ORACLE_HOME}:Y" >>/etc/oratab

# Create startup and shutdown scripts
cat >/home/${ORACLE_USER}/scripts/start_all.sh <<EOF
#!/bin/bash
. /home/${ORACLE_USER}/scripts/setEnv.sh
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES
dbstart \$ORACLE_HOME
EOF

cat >/home/${ORACLE_USER}/scripts/stop_all.sh <<EOF
#!/bin/bash
. /home/${ORACLE_USER}/scripts/setEnv.sh
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES
dbshut \$ORACLE_HOME
EOF

# Set ownership and permissions
chown -R ${ORACLE_USER}:${ORACLE_GROUP} /home/${ORACLE_USER}/scripts
chmod u+x /home/${ORACLE_USER}/scripts/*.sh

# Create systemd service for automatic startup
cat >/etc/systemd/system/oracle-db.service <<EOF
[Unit]
Description=The Oracle Database Service
After=syslog.target network.target

[Service]
LimitMEMLOCK=infinity
LimitNOFILE=65535
RemainAfterExit=yes
User=${ORACLE_USER}
Group=${ORACLE_GROUP}
Restart=no
ExecStart=/bin/bash -c '/home/${ORACLE_USER}/scripts/start_all.sh'
ExecStop=/bin/bash -c '/home/${ORACLE_USER}/scripts/stop_all.sh'

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon and enable service
systemctl daemon-reload
systemctl enable oracle-db.service

# Start Oracle services
su - ${ORACLE_USER} -c "lsnrctl start"
su - ${ORACLE_USER} -c "lsnrctl status"

# Update /etc/hosts
echo "192.168.128.50 ${ORACLE_HOSTNAME}" >>/etc/hosts

# Enable port 1521 in firewall and ensure it persists after reboot
semanage port -l | grep 1521
# If output does not include port 1521, we can configure it
semanage port -a -t oracle_port_t -p tcp 1521

# Confirm and add port to firewall
firewall-cmd --zone=public --add-port=1521/tcp --permanent
firewall-cmd --reload

echo "Oracle 19c installation, firewall configuration, and service setup completed successfully."
