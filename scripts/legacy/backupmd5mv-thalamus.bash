#!/bin/bash
#
#    Usage: backupmd5-thalamus.bash <toml-config-file>
#      run as hiseq.clinical 
#      use screen or nohup
#

VERSION=3.4.2
echo "VERSION ${VERSION}"

if [ -f "$1" ] ; then 
  CONF=$1
else
  CONF=~/clinical.toml
fi
NOW=$(date +"%Y%m%d%H%M%S")
BKPLOG=backup.${NOW}.log
echo ${CONF}
if [ ! -f "${CONF}" ] ; then 
  echo File ${CONF} not found
  exit 9
fi

cat ${CONF} | grep -v "^#" | sed 's/ //g' $1 | sed 's/"//g' >> ${BKPLOG}
. ${BKPLOG}
echo ${LOGDIR} next
mv ${BKPLOG} ${LOGDIR}
exec >> ${LOGDIR}${BKPLOG} 2>&1

echo "Variables read in from ${CONF}"
echo "LOGDIR   -  ${LOGDIR}"
echo "RUNBASE  -  ${RUNBASE}"
echo "BACKUPDIR  -  ${BACKUPDIR}"
echo "OLDRUNBASE  -  ${OLDRUNBASE}"
echo "NASRUNBASE  -  ${NASRUNBASE}"
echo "NASOLDRUNBASE  -  ${NASOLDRUNBASE}"
echo "BACKUPSERVER  -  ${BACKUPSERVER}"
echo "BACKUPSERVERBACKUPDIR  -  ${BACKUPSERVERBACKUPDIR}"
echo "BACKUPCOPIED  -  ${BACKUPCOPIED}"
NOW=$(date +"%Y%m%d%H%M%S")
echo "[${NOW}] [${RUNBASE}] Backup the older runs"
runs=$(find ${RUNBASE} -maxdepth 1 -name "*D00*" -mtime +65 -or -name "*_SN*" -mtime +15 | awk 'BEGIN {FS="/"} {print $NF}')

bckps=0
for run in ${runs[@]}; do
  echo "Will back up ${run}"
  python /home/clinical/SCRIPTS/clinical/clinical/getbackup.py ${run}
done
for run in ${runs[@]}; do
  cd ${RUNBASE}
  tar -czf ${BACKUPDIR}${run}.tar.gz ${RUNBASE}${run}
  tarcommand=$?
  NOW=$(date +"%Y%m%d%H%M%S")
  if [[ ${tarcommand} != 0 ]] ; then
    echo "[${NOW}] tar -czf ${BACKUPDIR}${run}.tar.gz ${run} failed:${tarcommand}"
  else
    echo "[${NOW}] tar -czf ${BACKUPDIR}${run}.tar.gz ${run} completed"
  fi

  cd ${BACKUPDIR}
  md5sum ${run}.tar.gz > ${run}.tar.gz.md5.txt
  md5command=$?
  NOW=$(date +"%Y%m%d%H%M%S")
  if [[ ${md5command} != 0 ]] ; then
    echo "[${NOW}] md5sum ${run}.tar.gz failed:${md5command}"
  else
    echo "[${NOW}] md5sum ${run}.tar.gz completed"
  fi

  md5=$(cat ${BACKUPDIR}${run}.tar.gz.md5.txt)
  NOW=$(date +"%Y%m%d%H%M%S")
  echo [${NOW}] [${run}] [${md5}] Backup files generated

  # issue this command for all NAS's
  for NAS in seq-nas-1 seq-nas-2 seq-nas-3 nas-6 clinical-nas-2; do
    ssh ${NAS} "mv ${NASRUNBASE}${run} ${NASOLDRUNBASE}"
    sshcommand=$?
    NOW=$(date +"%Y%m%d%H%M%S")
    if [[ ${sshcommand} != 0 ]] ; then
      echo "[${NOW}] ssh ${NAS} mv ${NASRUNBASE}${run} ${NASOLDRUNBASE} failed:${sshcommand}"
    else
      echo "[${NOW}] ssh ${NAS} mv ${NASRUNBASE}${run} ${NASOLDRUNBASE} completed"
    fi
  done
  echo [${NOW}] [${run}] [${NASOLDRUNBASE}] Moved to old . . .

  mv ${RUNBASE}${run} ${OLDRUNBASE}
  mvcommand=$?
  NOW=$(date +"%Y%m%d%H%M%S")
  if [[ ${mvcommand} != 0 ]] ; then
    echo "[${NOW}] mv ${RUNBASE}${run} ${OLDRUNBASE} failed:${mvcommand}"
  else
    echo "[${NOW}] [${run}] [${OLDRUNBASE}] Moved to old . . . completed"
  fi

  let bckps++
done
NOW=$(date +"%Y%m%d%H%M%S")
echo "[${NOW}] [${BACKUPDIR}] [${OLDRUNBASE}] ${bckps} runs backed up & moved"

oks=0
fails=0
copyoks=0
copyfails=0

NOW=$(date +"%Y%m%d%H%M%S")
echo "[${NOW}] [${BACKUPDIR}] Checking dir md5's"
files=$(ls ${BACKUPDIR} | grep -v "md5.txt$" | grep -v ".log")
for file in ${files[@]}; do
  echo "Will move ${file}"
done
for file in ${files[@]}; do
#  echo "${file}"
  newmd5=$(md5sum ${BACKUPDIR}${file} | awk '{print $1}')
  oldmd5=$(cat ${BACKUPDIR}${file}.md5.txt | awk '{print $1}')
  NOW=$(date +"%Y%m%d%H%M%S")
  if [ "${newmd5}" == "${oldmd5}" ]; then                   # compare stored md5 with calculated
    echo "[${NOW}] [${file}] [${newmd5} == ${oldmd5}] OK"   # echo OK if identical
    let oks++                                               # increment ok-counter
    scp ${BACKUPDIR}${file} ${BACKUPSERVER}:${BACKUPSERVERBACKUPDIR}  # copy the backup file and md5 control to backup server
    mvcommand=$?
    NOW=$(date +"%Y%m%d%H%M%S")
    if [[ ${mvcommand} != 0 ]] ; then
      echo "[${NOW}] scp ${BACKUPDIR}${file} ${BACKUPSERVER}:${BACKUPSERVERBACKUPDIR} failed:${mvcommand}"
    else
      echo "[${NOW}] scp ${BACKUPDIR}${file} ${BACKUPSERVER}:${BACKUPSERVERBACKUPDIR} done"
    fi

    scp ${BACKUPDIR}${file}.md5.txt ${BACKUPSERVER}:${BACKUPSERVERBACKUPDIR}  
    NOW=$(date +"%Y%m%d%H%M%S")
    if [[ ${mvcommand} != 0 ]] ; then
      echo "[${NOW}] scp ${BACKUPDIR}${file}.md5.txt ${BACKUPSERVER}:${BACKUPSERVERBACKUPDIR} failed:${mvcommand}"
    else
      echo "[${NOW}] scp ${BACKUPDIR}${file}.md5.txt ${BACKUPSERVER}:${BACKUPSERVERBACKUPDIR} done"
    fi

    servmd5=$(ssh ${BACKUPSERVER} md5sum ${BACKUPSERVERBACKUPDIR}${file} | awk '{print $1}')
    servold=$(ssh ${BACKUPSERVER} cat ${BACKUPSERVERBACKUPDIR}${file}.md5.txt | awk '{print $1}')
    NOW=$(date +"%Y%m%d%H%M%S")
    if [ "${servmd5}" == "${servold}" ]; then                   # compare copied md5s
      echo "[${NOW}] [${file}] COPIED TO SERVER OK"         
      let copyoks++       
      mv ${BACKUPDIR}${file} ${BACKUPCOPIED}                 # move the copied ones to copied dir
      mvcommand=$?
      NOW=$(date +"%Y%m%d%H%M%S")
      if [[ ${mvcommand} != 0 ]] ; then
        echo "[${NOW}] mv ${BACKUPDIR}${file} ${BACKUPCOPIED} failed:${mvcommand}"
      else
        echo "[${NOW}] mv ${BACKUPDIR}${file} ${BACKUPCOPIED} done"
      fi
      mv ${BACKUPDIR}${file}.md5.txt ${BACKUPCOPIED}
      mvcommand=$?
      NOW=$(date +"%Y%m%d%H%M%S")
      if [[ ${mvcommand} != 0 ]] ; then
        echo "[${NOW}] mv ${BACKUPDIR}${file}.md5.txt ${BACKUPCOPIED} failed:${mvcommand}"
      else
        echo "[${NOW}] mv ${BACKUPDIR}${file}.md5.txt ${BACKUPCOPIED} done"
      fi
    else
      echo "[${NOW}] [${file}] COPY TO SERVER FAILED"
      let copyfails++
    fi
  else
    echo "[${NOW}] [${file}] [${newmd5} != ${oldmd5}] FAIL"
    let fails++
  fi
done
echo "[${NOW}] [${BACKUPDIR}] Done checking OK:${oks} and FAIL:${fails} [copied ok:${copyoks} failed:${copyfails}]" 

