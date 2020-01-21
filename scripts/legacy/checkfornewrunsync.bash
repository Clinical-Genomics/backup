#!/bin/bash

set -e

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

sync() {
    log "rsync -av $1 $2"
    rsync -av $1 $2
    log "rsync -av --checksum $1 $2"
    rsync -av --checksum $1 $2
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

log "find ${INDIR} -name RTAComplete.txt -mtime +5 -maxdepth 2"
RTACOMPLETES=$(find ${INDIR} -name RTAComplete.txt -mtime +5 -maxdepth 2)
for RTACOMPLETE in $RTACOMPLETES; do
    RUN=$(basename $(dirname ${RTACOMPLETE}))
    log ${RUN}
    if [[ -d "${INDIR}/${RUN}" && ! -e ${OUTDIR}/${RUN}_started ]]; then
        log "gpg-pigz.batch ${INDIR}/${RUN} ${OUTDIR}"
        touch ${OUTDIR}/${RUN}_started
        bash ${SCRIPTDIR}/gpg-pigz.batch "${INDIR}/${RUN}" "${OUTDIR}"

        sync ${OUTDIR}/${RUN}.tar.gz.gpg ${REMOTE_OUTDIR}/
        sync ${OUTDIR}/${RUN}.key.gpg ${REMOTE_OUTDIR}/

        # signal the transfer is complete
        touch ${OUTDIR}/${RUN}_complete
        sync ${OUTDIR}/${RUN}_complete ${REMOTE_OUTDIR}/

        log "mv ${INDIR}/${RUN} ${MVDIR}/"
        mv ${INDIR}/${RUN} ${MVDIR}/

        log "rm ${OUTDIR}/${RUN}.tar.gz.gpg ${OUTDIR}/${RUN}.key.gpg ${OUTDIR}/${RUN}_started ${OUTDIR}/${RUN}_complete"
        rm ${OUTDIR}/${RUN}.tar.gz.gpg ${OUTDIR}/${RUN}.key.gpg ${OUTDIR}/${RUN}_started ${OUTDIR}/${RUN}_complete
    fi
done
