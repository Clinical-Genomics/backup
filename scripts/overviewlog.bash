#! /bin/bash
#
#    Usage: overview.bash
#      run as hiseq.clinical 
#      use screen or nohup
#

VERSION=3.14.3

. /home/clinical/CONFIG/configuration.txt
NOW=$(date +"%Y%m%d%H%M%S")
LOGFILE=${LOGDIR}check${NOW}.log

# Echo's a timestamped message in the form of [timestamp] [module] message
# Args:
#   message (str): the message to be printed
log() {
  NOW=$(date +"%Y%m%d%H%M%S")
  MSG=$1
  echo "[${NOW}] ${MSG}"
  echo "[${NOW}] ${MSG}" >> "${LOGFILE}"
}

log "VERSION ${VERSION}"


log "Logfile is ${LOGFILE}"
log "Variables read in from /home/clinical/CONFIG/configuration.txt"
log "               LOGDIR  -  ${LOGDIR}"

declare -A SERVERS=( [clinical-db]=493G,/var [clinical-nas-1]=/home [clinical-nas-2]=/home [seq-nas-1]=/home [seq-nas-3]=/home [nas-6]=/home [nas-9]=/home [hasta]=/home )

for SERVER in "${!SERVERS[@]}"; do
  DIRS=( $( echo ${SERVERS[$SERVER]} | sed -e 's/,/ /g' ) )
  for DIR in "${DIRS[@]}"; do
      SERVER_HOME=$(ssh ${SERVER} df -h 2> /dev/null | grep -F "$DIR" | awk '{ print $NF,$(NF -1) }')
      MSG="   ${SERVER} ${SERVER_HOME}"
      if [[ "$(echo ${SERVER_HOME} | awk '{split($2,arr,"%");print arr[1]}')" -ge 85 ]]; then
        MSG="${MSG}  -  C R I T I C A L !"
      fi
      log "${MSG}"
   done
done

exit 0
