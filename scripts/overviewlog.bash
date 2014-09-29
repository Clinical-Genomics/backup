#!/bin/bash
#
#    Usage: overview.bash
#      run as hiseq.clinical 
#      use screen or nohup
#
. /home/clinical/CONFIG/configuration.txt
echo "Variables read in from /home/clinical/CONFIG/configuration.txt"
echo "              RUNBASE  -  ${RUNBASE}"
echo "            BACKUPDIR  -  ${BACKUPDIR}"
echo "           OLDRUNBASE  -  ${OLDRUNBASE}"
echo "              PREPROC  -  ${PREPROC}"
echo "       PREPROCRUNBASE  -  ${PREPROCRUNBASE}"
echo "         BACKUPSERVER  -  ${BACKUPSERVER}"
echo "BACKUPSERVERBACKUPDIR  -  ${BACKUPSERVERBACKUPDIR}"
echo "         BACKUPCOPIED  -  ${BACKUPCOPIED}"
echo "               LOGDIR  -  ${LOGDIR}"
NOW=$(date +"%Y%m%d%H%M%S")
logfile=${LOGDIR}check${NOW}.log
echo "Logfile is ${logfile}"
echo "[${NOW}] Will check hippocampus [clinical-db]"
echo "[${NOW}] Will check hippocampus [clinical-db]" > ${logfile}
df -h >> ${logfile}
hippohome=$(df -h | grep home | awk '{print $6,$5}')
NOW=$(date +"%Y%m%d%H%M%S")
echo "[${NOW}] Will check thalamus [preproc]"
echo "[${NOW}] Will check thalamus [preproc]" >> ${logfile}
ssh thalamus.scilifelab.se df -h >> ${logfile}
thalahome=$(ssh thalamus.scilifelab.se df -h | grep home | awk '{print $6,$5}')
NOW=$(date +"%Y%m%d%H%M%S")
echo "[${NOW}] Will check cerebellum [clinical-nas-1]"
echo "[${NOW}] Will check cerebellum [clinical-nas-1]" >> ${logfile}
ssh cerebellum.scilifelab.se df -h >> ${logfile}
cerebhome=$(ssh cerebellum.scilifelab.se df -h | grep home | awk '{print $6,$5}')
NOW=$(date +"%Y%m%d%H%M%S")
echo "[${NOW}] Will check  [clinical-nas-2]"
echo "[${NOW}] Will check  [clinical-nas-2]" >> ${logfile}
ssh clinical-nas-2.scilifelab.se df -h >> ${logfile}
cnas2home=$(ssh clinical-nas-2.scilifelab.se df -h | grep home | awk '{print $6,$5}')
NOW=$(date +"%Y%m%d%H%M%S")
echo "[${NOW}] Will check rastapopoulos [cluster]"
echo "[${NOW}] Will check rastapopoulos [cluster]" >> ${logfile}
ssh rastapopoulos.scilifelab.se df -h >> ${logfile}
rastahds=$(ssh rastapopoulos.scilifelab.se df -h | grep "/mnt/hds$" | awk '{print $5,$4}')
NOW=$(date +"%Y%m%d%H%M%S")
echo "[${NOW}] Will check amygdala [develop]"
echo "[${NOW}] Will check amygdala [develop]" >> ${logfile}
ssh amygdala.scilifelab.se df -h >> ${logfile}
amygdhome=$(ssh amygdala.scilifelab.se df -h | grep home | awk '{print $6,$5}')
echo >> ${logfile}
WARNING=""
if [[ "$(echo ${hippohome} | awk '{split($2,arr,"%");print arr[1]}')" -ge 89 ]]; then
  WARNING="   -  C R I T I C A L ! "
  echo "   hippocampus  home ${hippohome} ${WARNING}"
fi
echo "   hippocampus  home ${hippohome} ${WARNING}" >> ${logfile}
WARNING=""
if [[ "$(echo ${thalahome} | awk '{split($2,arr,"%");print arr[1]}')" -ge 89 ]]; then
  WARNING="   -  C R I T I C A L ! "
  echo "      thalamus  home ${thalahome} ${WARNING}"
fi
echo "      thalamus  home ${thalahome} ${WARNING}" >> ${logfile}
WARNING=""
if [[ "$(echo ${cerebhome} | awk '{split($2,arr,"%");print arr[1]}')" -ge 89 ]]; then
  WARNING="   -  C R I T I C A L ! "
  echo "    cerebellum  home ${cerebhome} ${WARNING}"
fi
echo "    cerebellum  home ${cerebhome} ${WARNING}" >> ${logfile}
WARNING=""
if [[ "$(echo ${cnas2home} | awk '{split($2,arr,"%");print arr[1]}')" -ge 89 ]]; then
  WARNING="   -  C R I T I C A L ! "
  echo "clinical-nas-2  home ${cnas2home} ${WARNING}" 
fi
echo "clinical-nas-2  home ${cnas2home} ${WARNING}" >> ${logfile}
WARNING=""
if [[ "$(echo ${rastahds} | awk '{split($2,arr,"%");print arr[1]}')" -ge 89 ]]; then
  WARNING="   -  C R I T I C A L ! "
  echo " rastapopoulos  hds ${rastahds} ${WARNING}"
fi
echo " rastapopoulos  hds ${rastahds} ${WARNING}" >> ${logfile}
WARNING=""
if [[ "$(echo ${amygamygd} | awk '{split($2,arr,"%");print arr[1]}')" -ge 89 ]]; then
  WARNING="   -  C R I T I C A L ! "
  echo "      amygdala  home ${amygdhome} ${WARNING}" 
fi
echo "      amygdala  home ${amygdhome} ${WARNING}" >> ${logfile}
echo 

exit 0

