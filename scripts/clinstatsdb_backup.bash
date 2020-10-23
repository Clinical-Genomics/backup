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

set -e

##########
# CONFIG #
##########

VERSION=3.12.2
EMAILS=clinical-logwatch@scilifelab.se
BACKUPDIR=/home/clinical/BACKUP/
echo "VERSION ${VERSION}"

#########
# TRAPS #
#########

errr() {
    echo "Error while backing up ${DATABASE}" | mail -s "Error while backing up ${DATABASE}" ${EMAILS}
}
trap errr ERR 

########
# MAIN #
########

DATABASES=$(mysql --skip-column-names -e 'show databases')

for DATABASE in $DATABASES; do
    if echo "$DATABASE" | egrep -qs -v '(-dev|-stage)'; then
        echo "Backup up $DATABASE"
    else
        echo "Not backing up $DATABASE"
        continue
    fi
    
    NOW=$(date +"%Y%m%d%H%M%S")
    OUTFILE=${BACKUPDIR}/${DATABASE}_${NOW}.sql.gz
    mysqldump $DATABASE | gzip -9 > $OUTFILE

    scp $OUTFILE hasta:/home/proj/production/backup/mysql/clinical-db/
done
 
cd ${BACKUPDIR}
find . -type f -mtime +30 -exec rm ${BACKUPDIR}{} \;
