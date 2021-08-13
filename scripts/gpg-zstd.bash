#!/bin/bash

set -Eeuo pipefail

#############
# FUNCTIONS #
#############

log() {
    NOW=$(date +"%Y%m%d%H%M%S")
    echo "[${NOW}] $@"
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
CMD="gpg --gen-random 2 256 > ${PASSPHRASEFILE}"
log $CMD
$CMD

# asymmetrically encrypt the passphrase file
CMD="gpg -e -r 'Kenny Billiau' -o ${PASSPHRASEFILE}.gpg ${PASSPHRASEFILE}"
log $CMD
$CMD
ls -l ${PASSPHRASEFILE}*

# previous step can take a long while, check if the rundir still is there
if [[ ! -d ${RUN} ]]; then
    >&2 echo "${RUN} is gone - aborting"
    exit 1
fi

# TAR with zstd | GPG
CMD = "tar -c -I='zstd -19 -T0' -f - ${RUN} | gpg --symmetric --cipher-algo aes256 --passphrase-file ${PASSPHRASEFILE} --batch --compress-algo none -o ${OUTDIR}/${RUN}.tar.zstd.gpg"
log $CMD
$CMD

mv ${PASSPHRASEFILE}.gpg ${OUTDIR}/${RUN}.key.gpg
cd -
log "Finished"
