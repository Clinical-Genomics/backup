#!/bin/bash

# retrieves a file from PDC to local disk space.
# rsyncs it then to destination.

set -Eeuo pipefail

#########
# USAGE #
#########

declare -A SERVERS
SERVERS[thalamus]=/home/hiseq.clinical/RUNS/
SERVERS[hasta]=/home/proj/production/flowcells/hiseqx/

if [[ ${#@} -lt 2 ]]; then
    >&2 echo -e "USAGE:\n\t$0 fc server dest_dir"
    >&2 echo
    >&2 echo -e "\tIf server is filled in, follwing dest_dirs will be used:"
    for SERVER in "${!SERVERS[@]}"; do
        >&2 echo -e "\t* ${SERVER}: ${SERVERS[${SERVER}]}"
    done
    exit 1
fi

########
# VARS #
########

FC=$1
DEST_SERVER=$2
DEST_DIR=${3-${SERVERS[${DEST_SERVER}]}}

DEST_DIR_NAS=/home/hiseq.clinical/oldRuns/
DEST_SERVER_NAS=localhost

SCRIPT_DIR=$(dirname $0)

#############
# FUNCTIONS #
#############


get_pdc_runs() {
    local ON_PDC_FILE=$(mktemp)
    local REMOTE_OUTDIR=/mnt/hds/proj/bioinfo/TO_PDC
    local REMOTE_OUTDIR_2=/home/hiseq.clinical/ENCRYPT
    dsmc q archive "${REMOTE_OUTDIR}/" | tr -s ' ' | sed 's/^[[:space:]]*//' | cut -d ' ' -f1,2,5 > ${ON_PDC_FILE}
    dsmc q archive "${REMOTE_OUTDIR_2}/" | tr -s ' ' | sed 's/^[[:space:]]*//' | cut -d ' ' -f1,2,5 >> ${ON_PDC_FILE}

    echo ${ON_PDC_FILE}
}

log() {
    NOW=$(date +"%Y%m%d%H%M%S")
    echo "[${NOW}] $@"
}

finish() {
    if [[ -e ${ON_PDC_FILE} ]]; then
        rm ${ON_PDC_FILE}
    fi
}

#########
# TRAPS #
#########

trap finish EXIT ERR

########
# MAIN #
########

ON_PDC_FILE=$(get_pdc_runs)
ON_PDC_RUN=( $(grep "${FC}.tar." ${ON_PDC_FILE}) )
RUN_ARCHIVE=${ON_PDC_RUN[${#ON_PDC_RUN[@]}-1]}

RUN=$(basename ${RUN_ARCHIVE%*.tar.*.gpg})

CMD="bash ${SCRIPT_DIR}/retrieve_decrypt_safe_mode.bash ${RUN_ARCHIVE} ${DEST_SERVER_NAS} ${DEST_DIR_NAS}"
log $CMD
$CMD

CMD="rsync -r ${DEST_DIR_NAS}/${RUN} ${DEST_SERVER}:${DEST_DIR} --partial-dir=${DEST_SERVER}:${DEST_DIR}.partial --delay-updates --exclude RTAComplete.txt --exclude demuxstarted.txt --exclude Thumbnail_Images"
log $CMD
$CMD

CMD="ssh $DEST_SERVER 'touch ${DEST_DIR}/${RUN}/RTAComplete.txt'"
log $CMD
$CMD

CMD="rm -rf ${DEST_DIR_NAS}/${RUN}"
log $CMD
$CMD
