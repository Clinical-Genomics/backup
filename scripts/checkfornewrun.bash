#!/bin/bash

set -e

INDIR=${1?'Need a directory to monitor'}
OUTDIR=${2-/home/hiseq.clinical/ENCRYPT}
REMOTE_OUTDIR=${3-rasta:/mnt/hds/proj/bioinfo/TO_PDC}
MVDIR=/home/hiseq.clinical/BACKUP

SCRIPTDIR=$(dirname $0)

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

log "find ${INDIR} -name RTAComplete.txt -mtime +5 -maxdepth 2"
RTACOMPLETES=$(find ${INDIR} -name RTAComplete.txt -mtime +5 -maxdepth 2)
for RTACOMPLETE in $RTACOMPLETES; do
    RUN=$(basename $(dirname ${RTACOMPLETE}))
    log ${RUN}
    if [[ ! -e ${OUTDIR}/${RUN}.tar.gz.gpg ]]; then
        log "gpg-pigz.batch ${INDIR}/${RUN} ${OUTDIR}"
        bash ${SCRIPTDIR}/gpg-pigz.batch "${INDIR}/${RUN}" "${OUTDIR}"

        sync ${OUTDIR}/${RUN}.tar.gz.gpg ${REMOTE_OUTDIR}/
        sync ${OUTDIR}/${RUN}.key.gpg ${REMOTE_OUTDIR}/

        # signal the transfer is complete
        touch ${OUTDIR}/${RUN}_complete
        sync ${OUTDIR}/${RUN}_complete ${REMOTE_OUTDIR}/

        log "mv ${INDIR}/${RUN} ${MVDIR}/"
        mv ${INDIR}/${RUN} ${MVDIR}/

        log "rm ${OUTDIR}/${RUN}.tar.gz.gpg ${OUTDIR}/${RUN}.key.gpg"
        rm ${OUTDIR}/${RUN}.tar.gz.gpg ${OUTDIR}/${RUN}.key.gpg
    fi
done
