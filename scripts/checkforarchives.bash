#!/bin/bash

set -e

########
# VARS #
########

REMOTE_OUTDIR=${1-/mnt/hds/proj/bioinfo/TO_PDC}
REMOTE_OUTDIR_2=/home/hiseq.clinical/ENCRYPT
REMOTE_TMPDIR=${2-/tmp/to_pdc}

NASES=(clinical-nas-2 seq-nas-1 seq-nas-3 nas-6 nas-9 nas-10)

SCRIPTDIR=$(dirname $0)

#############
# FUNCTIONS #
#############

log() {
    NOW=$(date +"%Y%m%d%H%M%S")
    echo "[${NOW}] $@"
}

#########
# TRAPS #
#########

cleanup() {
    if [[ -e ${TO_PDC_LIST} ]]; then
        rm ${TO_PDC_LIST}
    fi
    ssh ${NAS} rm ${REMOTE_TMPDIR}
    exit
}
trap cleanup EXIT ERR

########
# MAIN #
########

# get the list of runs from PDC
TO_PDC_LIST=$(mktemp)
ssh clinical-db "dsmc q archive '${REMOTE_OUTDIR}/' | tr -s ' ' | sed 's/^[[:space:]]*//' | cut -d ' ' -f1,2,5" > ${TO_PDC_LIST}
ssh clinical-db "dsmc q archive '${REMOTE_OUTDIR_2}/' | tr -s ' ' | sed 's/^[[:space:]]*//' | cut -d ' ' -f1,2,5" >> ${TO_PDC_LIST}

for NAS in ${NASES[@]}; do
    echo ${NAS}

    # check if runs are ready for backup
    MYCOMMAND=`base64 -w0 is_run_ready.bash`
    ssh ${NAS} "echo $MYCOMMAND | base64 -d | bash"

    # push the list to the NAS
    scp -q ${TO_PDC_LIST} ${NAS}:${REMOTE_TMPDIR}

    # execute script remotely
    MYCOMMAND=`base64 -w0 is_run_backuped.bash`
    ssh ${NAS} "(export DELETE=${DELETE}; echo $MYCOMMAND | base64 -d | bash)"
done
