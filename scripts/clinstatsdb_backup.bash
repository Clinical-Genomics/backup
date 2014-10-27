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
. /home/clinical/CONFIG/configuration.txt
NOW=$(date +"%Y%m%d%H%M%S")
mysqldump clinstatsdb > ${BACKUPDIR}clinstatsdb_${NOW}.sql
