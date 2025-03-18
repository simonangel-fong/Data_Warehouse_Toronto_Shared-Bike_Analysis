# Oracle 19c Installation

[Back](../../../../README.md)

- [Oracle 19c Installation](#oracle-19c-installation)
  - [Homelab Specification](#homelab-specification)
  - [Install Oracle Database 19c](#install-oracle-database-19c)
    - [Automatic Pre-install Setup](#automatic-pre-install-setup)
    - [Set Up Required Directories](#set-up-required-directories)
    - [Set Environment Variables for Oracle](#set-environment-variables-for-oracle)
    - [Install Oracle 19c Software](#install-oracle-19c-software)
    - [Create and Configure Oracle Database](#create-and-configure-oracle-database)
    - [Enable Database Auto-Startup](#enable-database-auto-startup)
  - [Connect with db](#connect-with-db)
  - [Shell script](#shell-script)

---

## Homelab Specification

- Subnet: `192.168.128.0/24`
- Host OS: `Oracle Linux 8.10`
- Host IP: `192.168.128.50`
- Host name: `Argus-Homelab`

---

## Install Oracle Database 19c

### Automatic Pre-install Setup

```sh
# perform all your prerequisite setup
yum update -y
yum install -y oracle-database-preinstall-19c

# confirm
# it create user oracle
id oracle
# uid=54321(oracle) gid=54321(oinstall) groups=54321(oinstall),54322(dba),54323(oper),54324(backupdba),54325(dgdba),54326(kmdba),54330(racdba)
```

| Group Name  | Purpose                                                           |
| ----------- | ----------------------------------------------------------------- |
| `oinstall`  | Primary group for Oracle installation                             |
| `dba`       | Grants full administrative privileges on the database             |
| `oper`      | Allows limited administrative operations (e.g., startup/shutdown) |
| `backupdba` | Used for backup/restore operations                                |
| `dgdba`     | Used for Data Guard management                                    |
| `kmdba`     | Used for encryption key management                                |
| `racdba`    | Used for Oracle RAC (not needed for single-instance installs)     |

---

### Set Up Required Directories

| Directory                                 | Purpose                                     |
| ----------------------------------------- | ------------------------------------------- |
| `/u01/app/oracle`                         | Oracle base directory                       |
| `/u01/app/oracle/product/19.0.0/dbhome_1` | Oracle Database Home                        |
| `/u01/app/oraInventory`                   | Oracle Inventory for tracking installations |
| `/u02/oradata`                            | Oracle data file destination                |

```sh
# Oracle base directory
mkdir -pv /u01/app/oracle
# mkdir: created directory '/u01'
# mkdir: created directory '/u01/app'
# mkdir: created directory '/u01/app/oracle'

# Oracle Database Home
mkdir -pv /u01/app/oracle/product/19.0.0/dbhome_1
# mkdir: created directory '/u01/app/oracle/product'
# mkdir: created directory '/u01/app/oracle/product/19.0.0'
# mkdir: created directory '/u01/app/oracle/product/19.0.0/dbhome_1'

# Oracle Inventory for tracking installations
mkdir -pv /u01/app/oraInventory
# mkdir: created directory '/u01/app/oraInventory'

# Oracle data file destination
mkdir -pv /u02/oradata
# mkdir: created directory '/u02'
# mkdir: created directory '/u02/oradata'

# Set ownership for Oracle User
chown -Rv oracle:oinstall /u01 /u02
# changed ownership of '/u01/app/oracle/product/19.0.0/dbhome_1' from root:root to oracle:oinstall
# changed ownership of '/u01/app/oracle/product/19.0.0' from root:root to oracle:oinstall
# changed ownership of '/u01/app/oracle/product' from root:root to oracle:oinstall
# changed ownership of '/u01/app/oracle' from root:root to oracle:oinstall
# changed ownership of '/u01/app/oraInventory' from root:root to oracle:oinstall
# changed ownership of '/u01/app' from root:root to oracle:oinstall
# changed ownership of '/u01' from root:root to oracle:oinstall
# changed ownership of '/u02/oradata' from root:root to oracle:oinstall
# changed ownership of '/u02' from root:root to oracle:oinstall

# Set Permissions for Oracle User
chmod -Rv 775 /u01 /u02
# mode of '/u01' changed from 0755 (rwxr-xr-x) to 0775 (rwxrwxr-x)
# mode of '/u01/app' changed from 0755 (rwxr-xr-x) to 0775 (rwxrwxr-x)
# mode of '/u01/app/oracle' changed from 0755 (rwxr-xr-x) to 0775 (rwxrwxr-x)
# mode of '/u01/app/oracle/product' changed from 0755 (rwxr-xr-x) to 0775 (rwxrwxr-x)
# mode of '/u01/app/oracle/product/19.0.0' changed from 0755 (rwxr-xr-x) to 0775 (rwxrwxr-x)
# mode of '/u01/app/oracle/product/19.0.0/dbhome_1' changed from 0755 (rwxr-xr-x) to 0775 (rwxrwxr-x)
# mode of '/u01/app/oraInventory' changed from 0755 (rwxr-xr-x) to 0775 (rwxrwxr-x)
# mode of '/u02' changed from 0755 (rwxr-xr-x) to 0775 (rwxrwxr-x)
# mode of '/u02/oradata' changed from 0755 (rwxr-xr-x) to 0775 (rwxrwxr-x)
```

---

### Set Environment Variables for Oracle

```sh
# as root
# Create an environment file called "setEnv.sh".
mkdir -v /home/oracle/scripts
cat > /home/oracle/scripts/setEnv.sh <<EOF
# Oracle Settings
export TMP=/tmp
export TMPDIR=\$TMP

export ORACLE_HOSTNAME=Argus-HomeLab
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=\$ORACLE_BASE/product/19.0.0/dbhome_1
export ORA_INVENTORY=/u01/app/oraInventory
export DATA_DIR=/u02/oradata

export ORACLE_UNQNAME=cdb1
export ORACLE_SID=cdb1
export PDB_NAME=pdb1

export PATH=/usr/sbin:/usr/local/bin:\$PATH
export PATH=\$ORACLE_HOME/bin:\$PATH

export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib
EOF

# Add a reference to the "setEnv.sh" file at the end of the "/home/oracle/.bash_profile" file.
echo ". /home/oracle/scripts/setEnv.sh" >> /home/oracle/.bash_profile

# change the ownership
chown -R oracle:oinstall /home/oracle/scripts
# change the permission
chmod u+x /home/oracle/scripts/*.sh
```

---

### Install Oracle 19c Software

- Extract Oracle 19c Software

```sh
# Switch to the Oracle User
su - oracle
# Extract the Installation Files to Oracle Home
unzip -oq /mnt/hgfs/Softwares/LINUX.X64_193000_db_home.zip -d /u01/app/oracle/product/19.0.0/dbhome_1

# confirm
ll /u01/app/oracle/product/19.0.0/dbhome_1
```

---

- Start the Installer in Silent Mode

```sh
# As oracle
# confirm env var is available
echo $ORACLE_HOME

# Fake Oracle Linux 7.
export CV_ASSUME_DISTID=OEL7.6

# Start the Installer in Silent Mode
/u01/app/oracle/product/19.0.0/dbhome_1/runInstaller -silent -responseFile ${ORACLE_HOME}/install/response/db_install.rsp  \
    oracle.install.option=INSTALL_DB_SWONLY                 \
    ORACLE_HOSTNAME=${ORACLE_HOSTNAME}                      \
    UNIX_GROUP_NAME=oinstall                                \
    INVENTORY_LOCATION=${ORA_INVENTORY}                     \
    SELECTED_LANGUAGES=en,en_GB                             \
    ORACLE_HOME=${ORACLE_HOME}                              \
    ORACLE_BASE=${ORACLE_BASE}                              \
    oracle.install.db.InstallEdition=EE                     \
    oracle.install.db.OSDBA_GROUP=dba                       \
    oracle.install.db.OSBACKUPDBA_GROUP=dba                 \
    oracle.install.db.OSDGDBA_GROUP=dba                     \
    oracle.install.db.OSKMDBA_GROUP=dba                     \
    oracle.install.db.OSRACDBA_GROUP=dba                    \
    oracle.install.db.OSOPER_GROUP=dba                      \
    SECURITY_UPDATES_VIA_MYORACLESUPPORT=false              \
    DECLINE_SECURITY_UPDATES=true
# Launching Oracle Database Setup Wizard...
#
# The response file for this session can be found at:
#  /u01/app/oracle/product/19.0.0/dbhome_1/install/response/db_2025-03-02_06-54-07PM.rsp

# You can find the log of this install session at:
#  /tmp/InstallActions2025-03-02_06-54-07PM/installActions2025-03-02_06-54-07PM.log
#
# As a root user, execute the following script(s):
#         1. /u01/app/oraInventory/orainstRoot.sh
#         2. /u01/app/oracle/product/19.0.0/dbhome_1/root.sh
#
# Execute /u01/app/oraInventory/orainstRoot.sh on the following nodes:
# [Argus-HomeLab]
# Execute /u01/app/oracle/product/19.0.0/dbhome_1/root.sh on the following nodes:
# [Argus-HomeLab]
#
#
# Successfully Setup Software.
# Moved the install session logs to:
#  /u01/app/oraInventory/logs/InstallActions2025-03-02_06-54-07PM

# Run the Root Scripts as root
su - root -c "/u01/app/oraInventory/orainstRoot.sh"
# Changing permissions of /u01/app/oraInventory.
# Adding read,write permissions for group.
# Removing read,write,execute permissions for world.

# Changing groupname of /u01/app/oraInventory to oinstall.
# The execution of the script is complete.

su - root -c "/u01/app/oracle/product/19.0.0/dbhome_1/root.sh"
# Check /u01/app/oracle/product/19.0.0/dbhome_1/install/root_Argus-HomeLab_2025-03-02_18-56-28-272093939.log for the output of root script
```

- Options:

| Option                          | Desc                                                                  |
| ------------------------------- | --------------------------------------------------------------------- |
| `INSTALL_DB_SWONLY`             | Installs only the Oracle Database software (no database created yet). |
| `UNIX_GROUP_NAME=oinstall`      | Sets the primary Oracle installation group.                           |
| `INVENTORY_LOCATION`            | Specifies the location of the Oracle Inventory.                       |
| `ORACLE_HOME`                   | Directory where Oracle software will be installed.                    |
| `ORACLE_BASE`                   | The base directory for Oracle installations.                          |
| `InstallEdition=EE`             | Specifies the Enterprise Edition of Oracle Database.                  |
| `OSDBA_GROUP=dba`               | Grants dba group privileges for Oracle DBAs.                          |
| `DECLINE_SECURITY_UPDATES=true` | Declines Oracle's automatic security updates (optional).              |

---

### Create and Configure Oracle Database

```sh
# as oracle
# Run Oracle Database Configuration Assistant (DBCA)
dbca -silent -createDatabase                                                   \
     -templateName General_Purpose.dbc                                         \
     -gdbname ${ORACLE_SID} -sid  ${ORACLE_SID} -responseFile NO_VALUE         \
     -characterSet AL32UTF8                                                    \
     -sysPassword SysPassword1                                                 \
     -systemPassword SysPassword1                                              \
     -createAsContainerDatabase true                                           \
     -numberOfPDBs 1                                                           \
     -pdbName ${PDB_NAME}                                                      \
     -pdbAdminPassword PdbPassword1                                            \
     -databaseType MULTIPURPOSE                                                \
     -memoryMgmtType auto_sga                                                  \
     -totalMemory 2000                                                         \
     -storageType FS                                                           \
     -datafileDestination "${DATA_DIR}"                                        \
     -redoLogFileSize 50                                                       \
     -emConfiguration NONE                                                     \
     -ignorePreReqs

# Prepare for db operation
# 8% complete
# Copying database files
# 31% complete
# Creating and starting Oracle instance
# 32% complete
# 36% complete
# 40% complete
# 43% complete
# 46% complete
# Completing Database Creation
# 51% complete
# 53% complete
# 54% complete
# Creating Pluggable Databases
# 58% complete
# 77% complete
# Executing Post Configuration Actions
# 100% complete
# Database creation complete. For details check the logfiles at:
#  /u01/app/oracle/cfgtoollogs/dbca/cdb1.
# Database Information:
# Global Database Name:cdb1
# System Identifier(SID):cdb1
# Look at the log file "/u01/app/oracle/cfgtoollogs/dbca/cdb1/cdb1.log" for further details.
```

| Option                               | Description                                                                                  |
| ------------------------------------ | -------------------------------------------------------------------------------------------- |
| `-templateName General_Purpose.dbc`  | Specifies the template for the database (General_Purpose.dbc).                               |
| `-gdbname ${ORACLE_SID}`             | Sets the global database name (GDB) to the value of the Oracle SID (${ORACLE_SID}).          |
| `-sid ${ORACLE_SID}`                 | Specifies the SID (System Identifier) of the database.                                       |
| `-responseFile NO_VALUE`             | Indicates that no response file is being used, and parameters are passed directly.           |
| `-characterSet AL32UTF8`             | Sets the character set for the database to AL32UTF8 (Unicode).                               |
| `-sysPassword SysPassword1`          | Specifies the password for the SYS administrative user.                                      |
| `-systemPassword SysPassword1`       | Specifies the password for the SYSTEM administrative user.                                   |
| `-createAsContainerDatabase true`    | Specifies that the database will be created as a Container Database (CDB).                   |
| `-numberOfPDBs 1`                    | Sets the number of Pluggable Databases (PDBs) to be created inside the CDB (1 in this case). |
| `-pdbName ${PDB_NAME}`               | Specifies the name of the Pluggable Database (PDB).                                          |
| `-pdbAdminPassword PdbPassword1`     | Specifies the password for the PDB administrator (PDB_ADMIN).                                |
| `-databaseType MULTIPURPOSE`         | Specifies the database type (MULTIPURPOSE for general use, including OLTP and DSS).          |
| `-memoryMgmtType auto_sga`           | Specifies automatic management of the System Global Area (SGA).                              |
| `-totalMemory 2000`                  | Specifies the total memory (in MB) to be allocated to the Oracle database (2000 MB here).    |
| `-storageType FS`                    | Specifies that the storage type for database files is a file system (FS).                    |
| `-datafileDestination "${DATA_DIR}"` | Specifies the directory where the database data files will be stored.                        |
| `-redoLogFileSize 50`                | Specifies the size (in MB) of each redo log file (50 MB in this case).                       |
| `-emConfiguration NONE`              | Specifies that no Enterprise Manager (EM) configuration will be applied.                     |
| `-ignorePreReqs`                     | Instructs the installer to ignore prerequisite checks during the installation.               |

---

- Confirm

```sh
# make sure localhost is added in the /etc/hosts
su - root -c 'echo "192.168.128.50 Argus-HomeLab" >> /etc/hosts'

# Start the listener.
lsnrctl start
lsnrctl status
# LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 02-MAR-2025 19:27:57

# Copyright (c) 1991, 2019, Oracle.  All rights reserved.

# Connecting to (ADDRESS=(PROTOCOL=tcp)(HOST=)(PORT=1521))
# STATUS of the LISTENER
# ------------------------
# Alias                     LISTENER
# Version                   TNSLSNR for Linux: Version 19.0.0.0.0 - Production
# Start Date                02-MAR-2025 19:13:59
# Uptime                    0 days 0 hr. 13 min. 57 sec
# Trace Level               off
# Security                  ON: Local OS Authentication
# SNMP                      OFF
# Listener Log File         /u01/app/oracle/diag/tnslsnr/Argus-HomeLab/listener/alert/log.xml
# Listening Endpoints Summary...
#   (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=Argus-HomeLab)(PORT=1521)))
# Services Summary...
# Service "2f65f4dc9a8e4222e065020c29a319e8" has 1 instance(s).
#   Instance "cdb1", status READY, has 1 handler(s) for this service...
# Service "86b637b62fdf7a65e053f706e80a27ca" has 1 instance(s).
#   Instance "cdb1", status READY, has 1 handler(s) for this service...
# Service "cdb1" has 1 instance(s).
#   Instance "cdb1", status READY, has 1 handler(s) for this service...
# Service "cdb1XDB" has 1 instance(s).
#   Instance "cdb1", status READY, has 1 handler(s) for this service...
# Service "pdb1" has 1 instance(s).
#   Instance "cdb1", status READY, has 1 handler(s) for this service...
# The command completed successfully

sqlplus / as sysdba
select status from v$instance;
# STATUS
# ------------
# OPEN
show pdbs;

#     CON_ID CON_NAME                       OPEN MODE  RESTRICTED
# ---------- ------------------------------ ---------- ----------
#          2 PDB$SEED                       READ ONLY  NO
#          3 PDB1                           READ WRITE NO
exit;
```

---

### Enable Database Auto-Startup

```sh
vi /etc/oratab
# Locate the entry for your database,
cdb1:/u01/app/oracle/product/19.0.0/dbhome_1:Y

# Create a "start_all.sh" script to startup service
cat > /home/oracle/scripts/start_all.sh <<EOF
#!/bin/bash

# call env var
. /home/oracle/scripts/setEnv.sh

# prevents oraenv from prompting for the ORACLE_SID interactively.
export ORAENV_ASK=NO

# runs the Oracle environment script,
. oraenv

# restores the default behavior after execution.
export ORAENV_ASK=YES

# starts the database
dbstart \$ORACLE_HOME
EOF

# Create a "stop_all.sh" script to shutdown service
cat > /home/oracle/scripts/stop_all.sh <<EOF
#!/bin/bash

# call env var
. /home/oracle/scripts/setEnv.sh

# prevents oraenv from prompting for the ORACLE_SID interactively.
export ORAENV_ASK=NO

# runs the Oracle environment script,
. oraenv

# restores the default behavior after execution.
export ORAENV_ASK=YES

# shutdown db
dbshut \$ORACLE_HOME
EOF

# change the ownership
chown -R oracle:oinstall /home/oracle/scripts
# change the permission
chmod u+x /home/oracle/scripts/*.sh

su - root
# Creating Linux Services
cat > /etc/systemd/system/oracle-db.service << EOF

[Unit]
Description=The Oracle Database Service
After=syslog.target network.target

[Service]
# systemd ignores PAM limits, so set any necessary limits in the service.
# Not really a bug, but a feature.
# https://bugzilla.redhat.com/show_bug.cgi?id=754285
LimitMEMLOCK=infinity
LimitNOFILE=65535

#Type=simple
# idle: similar to simple, the actual execution of the service binary is delayed
#       until all jobs are finished, which avoids mixing the status output with shell output of services.
RemainAfterExit=yes
User=oracle
Group=oinstall
Restart=no
ExecStart=/bin/bash -c '/home/oracle/scripts/start_all.sh'
ExecStop=/bin/bash -c '/home/oracle/scripts/stop_all.sh'

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd so it can see the new service.
systemctl daemon-reload

# test: start, might take time
systemctl start oracle-db.service
systemctl status oracle-db.service
# oracle-db.service - The Oracle Database Service
#    Loaded: loaded (/etc/systemd/system/oracle-db.service; disabled; vendor preset: disabled)
#    Active: active (exited) since Sun 2025-03-02 19:55:11 EST; 2min 1s ago
#   Process: 21484 ExecStart=/bin/bash -c /home/oracle/scripts/start_all.sh (code=exited, status=0/SUCCESS)
#  Main PID: 21484 (code=exited, status=0/SUCCESS)
#     Tasks: 58 (limit: 22834)
#    Memory: 1.7G
#    CGroup: /system.slice/oracle-db.service
#            ├─21511 /u01/app/oracle/product/19.0.0/dbhome_1/bin/tnslsnr LISTENER -inherit
#            ├─21606 ora_pmon_cdb1
#            ├─21608 ora_clmn_cdb1
#            ├─21610 ora_psp0_cdb1
#            ├─21612 ora_vktm_cdb1
#            ├─21616 ora_gen0_cdb1
#            ├─21618 ora_mman_cdb1
#            ├─21622 ora_gen1_cdb1
#            ├─21625 ora_diag_cdb1
#            ├─21627 ora_ofsd_cdb1
#            ├─21630 ora_dbrm_cdb1
#            ├─21632 ora_vkrm_cdb1
#            ├─21634 ora_svcb_cdb1
#            ├─21636 ora_pman_cdb1
#            ├─21638 ora_dia0_cdb1
#            ├─21640 ora_dbw0_cdb1
#            ├─21642 ora_lgwr_cdb1
#            ├─21644 ora_ckpt_cdb1
#            ├─21646 ora_lg00_cdb1
#            ├─21648 ora_smon_cdb1
#            ├─21650 ora_lg01_cdb1
#            ├─21652 ora_smco_cdb1
#            ├─21654 ora_reco_cdb1
#            ├─21656 ora_w000_cdb1
#            ├─21658 ora_lreg_cdb1
#            ├─21660 ora_w001_cdb1
#            ├─21662 ora_pxmn_cdb1
#            ├─21666 ora_mmon_cdb1
#            ├─21668 ora_mmnl_cdb1
#            ├─21670 ora_d000_cdb1
#            ├─21672 ora_s000_cdb1
#            ├─21674 ora_tmon_cdb1
#            ├─21678 ora_m000_cdb1
#            ├─21680 ora_m001_cdb1
#            ├─21685 ora_tt00_cdb1
#            ├─21687 ora_tt01_cdb1
#            ├─21689 ora_tt02_cdb1
#            ├─21691 ora_aqpc_cdb1
#            ├─21695 ora_p000_cdb1
#            ├─21697 ora_p001_cdb1
#            ├─21699 ora_p002_cdb1
#            ├─21701 ora_p003_cdb1
#            ├─21703 ora_p004_cdb1
#            ├─21705 ora_p005_cdb1
#            ├─21707 ora_p006_cdb1
#            ├─21709 ora_p007_cdb1
#            ├─21711 ora_cjq0_cdb1
#            ├─21872 ora_w002_cdb1
#            ├─21953 ora_m002_cdb1
#            ├─21977 ora_m003_cdb1
#            ├─21979 ora_w003_cdb1
#            ├─21983 ora_w004_cdb1
#            ├─21985 ora_qm02_cdb1
#            ├─21987 ora_q001_cdb1
#            └─21991 ora_q003_cdb1

# Mar 02 19:55:11 Argus-HomeLab systemd[1]: Started The Oracle Database Service.
# Mar 02 19:55:11 Argus-HomeLab bash[21484]: The Oracle base remains unchanged with value /u01/app/oracle
# Mar 02 19:55:11 Argus-HomeLab bash[21548]: Processing Database instance "cdb1": log file /u01/app/oracle/product/19.0.0/dbhome_1/rdbms/log/startup.log

systemctl stop oracle-db.service
systemctl status oracle-db.service
# ● oracle-db.service - The Oracle Database Service
#    Loaded: loaded (/etc/systemd/system/oracle-db.service; disabled; vendor preset: disabled)
#    Active: inactive (dead)
# Mar 02 19:53:09 Argus-HomeLab systemd[1]: Started The Oracle Database Service.
# Mar 02 19:53:09 Argus-HomeLab bash[20818]: The Oracle base remains unchanged with value /u01/app/>
# Mar 02 19:53:09 Argus-HomeLab bash[20880]: Processing Database instance "cdb1": log file /u01/app>
# Mar 02 19:53:23 Argus-HomeLab systemd[1]: Stopping The Oracle Database Service...
# Mar 02 19:53:23 Argus-HomeLab bash[21052]: The Oracle base remains unchanged with value /u01/app/>
# Mar 02 19:53:23 Argus-HomeLab bash[21074]: Processing Database instance "cdb1": log file /u01/app>
# Mar 02 19:54:08 Argus-HomeLab systemd[1]: oracle-db.service: Succeeded.
# Mar 02 19:54:08 Argus-HomeLab systemd[1]: Stopped The Oracle Database Service.

systemctl enable oracle-db.service

reboot
```

---

## Connect with db

```sh
# confirm listener start
tnsping 192.168.128.50:1521
# TNS Ping Utility for Linux: Version 19.0.0.0.0 - Production on 02-MAR-2025 20:06:13

# Copyright (c) 1997, 2019, Oracle.  All rights reserved.

# Used parameter files:

# Used HOSTNAME adapter to resolve the alias
# Attempting to contact (DESCRIPTION=(CONNECT_DATA=(SERVICE_NAME=))(ADDRESS=(PROTOCOL=tcp)(HOST=192.168.128.50)(PORT=1521)))
# OK (0 msec)

# enable 1521 port
# confirm selinux port is enabled
semanage port -l | grep 1521
# oracle_port_t                  tcp      1521, 2483, 2484
# oracle_port_t                  udp      1521, 2483, 2484

# confirm port in firewall
firewall-cmd --zone=public --add-port=1521/tcp --permanent
firewall-cmd --reload
firewall-cmd --list-ports
# 1521/tcp
```

- Connect using SQL Server

![pic](./pic/pic01.png)

![pic](./pic/pic02.png)

---

## Shell script

```sh
#!/bin/bash
#!/bin/bash

set -e  # Exit on error
set -o pipefail  # Exit if any command fails in a pipeline
set -u  # Treat unset variables as an error

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
INSTALLER_ZIP="/mnt/hgfs/Softwares/LINUX.X64_193000_db_home.zip"
ROOT_USER="root"
ORACLE_USER="oracle"
ORACLE_GROUP="oinstall"
DBA_GROUP="dba"
SYS_PASSWORD="SysPassword1"
PDB_PASSWORD="PdbPassword1"

# Add host entry
echo "${ORACLE_HOST_IP} ${ORACLE_HOSTNAME}" >> /etc/hosts

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
cat > /home/${ORACLE_USER}/scripts/setEnv.sh <<EOF
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

echo ". /home/${ORACLE_USER}/scripts/setEnv.sh" >> /home/${ORACLE_USER}/.bash_profile

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
echo "${ORACLE_SID}:${ORACLE_HOME}:Y" >> /etc/oratab

# Create startup and shutdown scripts
cat > /home/${ORACLE_USER}/scripts/start_all.sh <<EOF
#!/bin/bash
. /home/${ORACLE_USER}/scripts/setEnv.sh
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES
dbstart \$ORACLE_HOME
EOF

cat > /home/${ORACLE_USER}/scripts/stop_all.sh <<EOF
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
cat > /etc/systemd/system/oracle-db.service << EOF
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
echo "192.168.128.50 ${ORACLE_HOSTNAME}" >> /etc/hosts

# Enable port 1521 in firewall and ensure it persists after reboot
semanage port -l | grep 1521
# If output does not include port 1521, we can configure it
semanage port -a -t oracle_port_t -p tcp 1521

# Confirm and add port to firewall
firewall-cmd --zone=public --add-port=1521/tcp --permanent
firewall-cmd --reload

echo "Oracle 19c installation, firewall configuration, and service setup completed successfully."

```
