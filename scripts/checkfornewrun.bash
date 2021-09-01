#!/bin/bash

set -e

VERSION=3.14.0

########
# VARS #
########

INDIR=${1?'Need a directory to monitor'}
OUTDIR=${2-/home/hiseq.clinical/ENCRYPT}
REMOTE_OUTDIR=${3-rasta:/mnt/hds/proj/bioinfo/TO_PDC}
MVDIR=/home/hiseq.clinical/BACKUP
EMAILS=clinical-logwatch@scilifelab.se

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

finish() {
    NAS=$(hostname)
    echo "Error while backing up ${RUN} on ${NAS}" | mail -s "Error while backing up ${RUN} on ${NAS}" ${EMAILS}
}
trap finish ERR

########
# MAIN #
########

if pgrep rsync || pgrep -x gpg; then
    log "Skipping archiving - Other runs are syncing"
    exit
fi

log "find ${INDIR} -maxdepth 2 -name RTAComplete.txt -mtime +1"
RTACOMPLETES=$(find ${INDIR} -maxdepth 2 -name RTAComplete.txt -mtime +1)
for RTACOMPLETE in $RTACOMPLETES; do
    RUN=$(basename $(dirname ${RTACOMPLETE}))
    log ${RUN}
    if [[ -d "${INDIR}/${RUN}" && ! -e ${OUTDIR}/${RUN}_started ]]; then
        log "gpg-pigz.batch ${INDIR}/${RUN} ${OUTDIR}"
        echo $VERSION > ${OUTDIR}/${RUN}_started
        bash ${SCRIPTDIR}/gpg-pigz.batch "${INDIR}/${RUN}" "${OUTDIR}"

        # signal the transfer is complete
        touch ${OUTDIR}/${RUN}_complete

        log "mv ${INDIR}/${RUN} ${MVDIR}/"
        mv ${INDIR}/${RUN} ${MVDIR}/
    fi
done
