#!/bin/bash
#
#    Usage: overview.bash
#      run as hiseq.clinical 
#      use screen or nohup
#

VERSION=1.2.2

# Echo's a timestamped message in the form of [timestamp] [module] message
# Args:
#   message (str): the message to be printed
log() {
  NOW=$(date +"%Y%m%d%H%M%S")
  MSG=$1
  echo [${NOW}] ${MSG}
  echo [${NOW}] ${MSG} >> ${LOGFILE}
}

log "VERSION ${VERSION}"

. /home/clinical/CONFIG/configuration.txt
NOW=$(date +"%Y%m%d%H%M%S")
LOGFILE=${LOGDIR}check${NOW}.log

log "Logfile is ${LOGFILE}"
log "Variables read in from /home/clinical/CONFIG/configuration.txt"
log "              RUNBASE  -  ${RUNBASE}"
log "            BACKUPDIR  -  ${BACKUPDIR}"
log "           OLDRUNBASE  -  ${OLDRUNBASE}"
log "              PREPROC  -  ${PREPROC}"
log "       PREPROCRUNBASE  -  ${PREPROCRUNBASE}"
log "         BACKUPSERVER  -  ${BACKUPSERVER}"
log "BACKUPSERVERBACKUPDIR  -  ${BACKUPSERVERBACKUPDIR}"
log "         BACKUPCOPIED  -  ${BACKUPCOPIED}"
log "               LOGDIR  -  ${LOGDIR}"

SERVERS=(clinical-db clinical-preproc clinical-nas-1 clinical-nas-2 seq-nas-1 seq-nas-2 seq-nas-3 nas-6 nas-7 nas-8 nas-9 nas-10)

for SERVER in "${SERVERS[@]}"; do
  SERVER_HOME=$(ssh ${SERVER} df -h 2> /dev/null | grep home)
  SERVER_HOME=$(echo ${SERVER_HOME} | awk '{ print $6,$5 }')
  MSG="   ${SERVER} ${SERVER_HOME}"
  if [[ "$(echo ${SERVER_HOME} | awk '{split($2,arr,"%");print arr[1]}')" -ge 85 ]]; then
    MSG="${MSG}  -  C R I T I C A L !"
  fi
  log "${MSG}"
done

exit 0
