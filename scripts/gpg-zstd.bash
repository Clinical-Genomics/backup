#!/bin/bash

set -Eeuo pipefail

#############
# FUNCTIONS #
#############

log() {
    NOW=$(date +"%Y-%m-%d %H:%M:%S")
    echo "`echo $'\n '`[${NOW}] $@"
}

log_exc() {
    log "$@"
    "$@"
}

finish() {
    if [[ ! -z "${PASSPHRASEFILE}" && -f ${PASSPHRASEFILE} ]]; then
        rm ${PASSPHRASEFILE}
    fi
    if [[ -f ${PASSPHRASEFILE}.gpg ]]; then
        rm ${PASSPHRASEFILE}.gpg
    fi

trap finish ERR EXIT

########
# VARS #
########

IN=$1
OUTDIR=$2

INDIR=$(dirname ${IN})
RUN=$(basename ${IN})

########
# MAIN #
########

export TMPDIR=${OUTDIR}
PASSPHRASEFILE=$(mktemp)
chmod a-rwx,u+rw ${PASSPHRASEFILE}

cd ${INDIR}

# can take some time when there is not a lot of entropy
log gpg --gen-random 2 256 > ${PASSPHRASEFILE}
gpg --gen-random 2 256 > ${PASSPHRASEFILE}

# asymmetrically encrypt the passphrase file
log_exc gpg -e -r "Kenny Billiau" -o ${PASSPHRASEFILE}.gpg ${PASSPHRASEFILE}
log_exc ls -l ${PASSPHRASEFILE}*

# TAR with zstd
log_exc tar -cP --use-compress-program='zstd -19 -T0' -f ${OUTDIR}/${RUN}.tar.zstd ${RUN}

# GPG
log_exc gpg --symmetric --cipher-algo aes256 --passphrase-file ${PASSPHRASEFILE} --batch --compress-algo none -o ${OUTDIR}/${RUN}.tar.zstd.gpg ${OUTDIR}/${RUN}.tar.zstd

log_exc mv ${PASSPHRASEFILE}.gpg ${OUTDIR}/${RUN}.key.gpg
cd -
log "Finished"
