#!/bin/bash

##########
# PARAMS #
##########

INDIR=${1?'Need an input directory to monitor'}

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

for RUNFILE in ls ${INDIR}/*.tar.gz.gpg; do
    RUN=${RUNFILE%%.*}
    KEYFILE=${RUN}.key.gpg
    if ! dsmc q archive "${RUNFILE}"; then
        log "dsmc archive ${RUNFILE} && dsmc archive ${KEYFILE}"
        dsmc archive ${RUNFILE} && dsmc archive ${KEYFILE}
        #if [[ $? -eq 0 ]]; then
        #    log "rm ${RUNFILE}"
        #    rm ${RUNFILE}
        #    log "rm ${KEYFILE}"
        #    rm ${KEYFILE}
        #fi
    fi
done
