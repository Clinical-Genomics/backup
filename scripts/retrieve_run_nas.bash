#!/bin/bash

# retrieves a file from PDC to local disk space.
# rsyncs it then to destination.

set -eu -o pipefail

########
# VARS #
########

if [[ ${#@} -ne 3 ]]; then
    >&2 echo -e "USAGE:\n\t$0 fc server dest_dir"
    exit 1
fi

FC=$1
DEST_SERVER=$2
DEST_DIR=$3

DEST_DIR_NAS=/home/hiseq.clinical/oldRuns/
DEST_SERVER_NAS=localhost

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
ON_PDC_RUN=( $(grep "${FC}.tar.gz.gpg" ${ON_PDC_FILE}) )
RUN_ARCHIVE=${ON_PDC_RUN[2]}
RUN=$(basename ${RUN_ARCHIVE%*.tar.gz.gpg})

log "bash retrieve_decrypt.bash ${RUN_ARCHIVE} ${DEST_SERVER_NAS} ${DEST_DIR_NAS}"
bash retrieve_decrypt.bash ${RUN_ARCHIVE} ${DEST_SERVER_NAS} ${DEST_DIR_NAS}

log "rsync -a ${DEST_DIR_NAS}/${RUN} ${DEST_SERVER}:${DEST_DIR} --exclude ${DEST_DIR_NAS}/${RUN}/RTAComplete.txt --exclude demuxstarted.txt --exclude Thumbnail_Images"
rsync -a ${DEST_DIR_NAS}/${RUN} ${DEST_SERVER}:${DEST_DIR} --exclude ${DEST_DIR_NAS}/${RUN}/RTAComplete.txt --exclude demuxstarted.txt --exclude Thumbnail_Images

log "ssh $DEST_SERVER 'touch ${DEST_DIR}/${RUN}/RTAComplete.txt'"
ssh $DEST_SERVER "touch ${DEST_DIR}/${RUN}/RTAComplete.txt"
