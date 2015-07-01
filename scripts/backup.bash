#!/bin/bash
#
#
#
#
#

source log.bash

VERSION=$(getversion)
log VERSION

NOW=$(date +"%Y%m%d%H%M%S")

lowerlimit=1200000000
upperlimit=1300000000
backupdir=/mnt/hds/proj/bioinfo/BACKUP/
totapedir=/mnt/hds/proj/bioinfo/FOR_TAPE/
logfile=/mnt/hds/proj/bioinfo/LOG/backup.${NOW}.log

sizeintotape=$(du -s ${totapedir} | awk '{print $1}')
if [ "${sizeintotape}" -gt "${lowerlimit}" ]; then 
  echo above min limit >> ${logfile}
  if [ "${sizeintotape}" -lt "${upperlimit}" ]; then
    echo below max limit >> ${logfile}
    NOW=$(date +"%Y%m%d%H%M%S")
    echo Will start backup procedure ${NOW} >> ${logfile}
    ls -lt ${totapedir} >> ${logfile}
    ssh amanda@burns.scilifelab.se -i ~/.ssh/start_backup_id_dsa >> ${logfile}
  else
    echo ABOVE MAX LIMIT, needs attention! >> ${logfile}
    exit 9
  fi
else 
  echo below min limit, will move files to FOR_TAPE . . . >> ${logfile}
  echo [${NOW}] moving files from ${backupdir} to ${totapedir} >> ${logfile}
  files=$(ls -t ${backupdir} | grep "gz$")
  for bkp in ${files[@]}; do
    mv ${backupdir}${bkp} ${totapedir}
    mv ${backupdir}${bkp}.md5.txt ${totapedir}
    NOW=$(date +"%Y%m%d%H%M%S")
    csize=$(du -s ${totapedir} | awk '{print $1}')
    echo [${NOW}] mv ${bkp} size ${csize} >> ${logfile}
    if [ "${csize}" -gt "${lowerlimit}" ]; then
      echo  "${csize} > ${lowerlimit}" >> ${logfile}
      echo Stopped moving files . . . >> ${logfile}
      break
    fi
  done
fi

NOW=$(date +"%Y%m%d%H%M%S")
echo [${NOW}] Backup script ended size for tape ${sizeintotape}



