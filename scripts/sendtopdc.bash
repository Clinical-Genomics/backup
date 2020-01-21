#!/bin/bash

set -e

##########
# PARAMS #
##########

INDIR=${1?'Need an input directory to monitor'}
EMAILS=clinical.logwatch@scilifelab.se

#############
# FUNCTIONS #
#############

log() {
    NOW=$(date +"%Y%m%d%H%M%S")
    echo "[${NOW}] $@"
}

dsmc() {
    DSM_DIR=/opt/adsm_clinical command dsmc $@
}

#########
# TRAPS #
#########

errr() {
    NAS=$(hostname)
    echo "Error while transferring ${RUN}" | mail -s "Error while transferring ${RUN} on line $1" ${EMAILS}
    exit 1
}
trap 'errr ${LINENO}' ERR

########
# MAIN #
########

if pgrep dsmc; then
    log "dsmc is already running - exit"
    exit
fi

for RUNFILE in ${INDIR}/*.tar.gz.gpg; do
    RUN=${RUNFILE%.tar.gz.gpg}

    if [[ ! -e ${RUN}_complete ]]; then
        log "${RUN} hasn't finished yet"
        continue # if not yet fully copied, skip
    fi

    if ! dsmc q archive "${RUNFILE}" > /dev/null; then

        # check if key is there
        KEYFILE=${RUN}.key.gpg
        if [[ ! -e ${KEYFILE} ]]; then
            exit 2
        fi

        log "dsmc archive ${RUNFILE}"
        dsmc archive ${RUNFILE}
        log "dsmc archive ${KEYFILE}"
        dsmc archive ${KEYFILE}
        if [[ $? -eq 0 ]]; then
            log "rm ${RUNFILE}"
            rm ${RUNFILE}
            log "rm ${KEYFILE}"
            rm ${KEYFILE}
        fi
    else
        log "${RUN} has already been sent"
    fi
done
