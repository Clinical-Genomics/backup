#!/bin/bash
#
#    Usage: clinstatsdb_backup.bash
#      run as hiseq.clinical 
#      This script will dump the clinstatsdb database to an sql text file
#      It should be run every night using crontab 
#
# requires a file '.my.cnf' in the home directory
## [client]
## user = DBUSERNAME
## password = "DBPASSWORD"
## host = localhost
#

VERSION=3.2.2
echo "VERSION ${VERSION}"

. /home/clinical/CONFIG/configuration.txt
NOW=$(date +"%Y%m%d%H%M%S")
OUTFILE=${BACKUPDIR}clinical-db_${NOW}.sql
mysqldump --databases csdb nipt_new > $OUTFILE

scp $OUTFILE rasta:/mnt/hds/proj/bioinfo/BACKUP/clinstatsdb_${NOW}.sql

