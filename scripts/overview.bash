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

echo
echo "[${NOW}] Will check hippocampus [clinical-db]"
df -h 
hippohome=$(df -h | grep home | awk '{print $6,$5}')
NOW=$(date +"%Y%m%d%H%M%S")
echo
echo "[${NOW}] Will check thalamus [preproc]"
ssh thalamus.scilifelab.se df -h
thalahome=$(ssh thalamus.scilifelab.se df -h | grep home | awk '{print $6,$5}')
NOW=$(date +"%Y%m%d%H%M%S")
echo
echo "[${NOW}] Will check cerebellum [clinical-nas-1]"
ssh cerebellum.scilifelab.se df -h
cerebhome=$(ssh cerebellum.scilifelab.se df -h | grep home | awk '{print $6,$5}')
NOW=$(date +"%Y%m%d%H%M%S")
echo
echo "[${NOW}] Will check  [clinical-nas-2]"
ssh clinical-nas-2.scilifelab.se df -h
cnas2home=$(ssh clinical-nas-2.scilifelab.se df -h | grep home | awk '{print $6,$5}')
NOW=$(date +"%Y%m%d%H%M%S")
echo
echo "[${NOW}] Will check rastapopoulos [cluster]"
ssh rastapopoulos.scilifelab.se df -h
rastahds=$(ssh rastapopoulos.scilifelab.se df -h | grep "/mnt/hds$" | awk '{print $5,$4}')
NOW=$(date +"%Y%m%d%H%M%S")
echo
echo "[${NOW}] Will check amygdala [develop]"
ssh amygdala.scilifelab.se df -h
amygdhome=$(ssh amygdala.scilifelab.se df -h | grep home | awk '{print $6,$5}')
echo 
NOW=$(date +"%Y-%m-%d %H:%M:%S")
echo "      ${NOW}"
WARNING=""
if [[ "$(echo ${hippohome} | awk '{split($2,arr,"%");print arr[1]}')" -ge 89 ]]; then
  WARNING="   -  C R I T I C A L ! "
fi
echo "   hippocampus  home ${hippohome} ${WARNING}"
WARNING=""
if [[ "$(echo ${thalahome} | awk '{split($2,arr,"%");print arr[1]}')" -ge 89 ]]; then
  WARNING="   -  C R I T I C A L ! "
fi
echo "      thalamus  home ${thalahome} ${WARNING}"
WARNING=""
if [[ "$(echo ${cerebhome} | awk '{split($2,arr,"%");print arr[1]}')" -ge 89 ]]; then
  WARNING="   -  C R I T I C A L ! "
fi
echo "    cerebellum  home ${cerebhome} ${WARNING}"
WARNING=""
if [[ "$(echo ${cnas2home} | awk '{split($2,arr,"%");print arr[1]}')" -ge 89 ]]; then
  WARNING="   -  C R I T I C A L ! "
fi
echo "clinical-nas-2  home ${cnas2home} ${WARNING}"
WARNING=""
if [[ "$(echo ${rastahds} | awk '{split($2,arr,"%");print arr[1]}')" -ge 89 ]]; then
  WARNING="   -  C R I T I C A L ! "
fi
echo " rastapopoulos  hds ${rastahds} ${WARNING}"
WARNING=""
if [[ "$(echo ${amygamygd} | awk '{split($2,arr,"%");print arr[1]}')" -ge 89 ]]; then
  WARNING="   -  C R I T I C A L ! "
fi
echo "      amygdala  home ${amygdhome} ${WARNING}"
echo
exit 0

