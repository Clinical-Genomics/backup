#!/bin/bash

##########
# PARAMS #
##########

INDIR=${1?'Need an input directory to monitor'}
EMAILS=kenny.billiau@scilifelab.se

#############
# FUNCTIONS #
#############

log() {
    NOW=$(date +"%Y%m%d%H%M%S")
    echo "[${NOW}] $@"
}

########
# MAIN #
########

if pgrep dsmc; then
    log "dsmc is already running - exit"
    exit
fi

for RUNFILE in ${INDIR}/*.tar.gz.gpg; do
    RUN=${RUNFILE%%.*}

    if [[ ! -e ${RUN}_complete ]]; then
        log "${RUN} hasn't finished yet"
        continue # if not yet fully copied, skip
    fi

    KEYFILE=${RUN}.key.gpg
    if [[ ! -e ${KEYFILE} ]]; then
        echo "${KEYFILE} is missing! Cannot archive" | mail -s "${KEYFILE} is missing!" ${EMAILS}
    fi
    if ! dsmc q archive "${RUNFILE}" > /dev/null; then
        log "dsmc archive ${RUNFILE} && dsmc archive ${KEYFILE}"
        dsmc archive ${RUNFILE} && dsmc archive ${KEYFILE}
        #if [[ $? -eq 0 ]]; then
        #    log "rm ${RUNFILE}"
        #    rm ${RUNFILE}
        #    log "rm ${KEYFILE}"
        #    rm ${KEYFILE}
        #fi
    else
        log "${RUN} has already been sent"
    fi
done
