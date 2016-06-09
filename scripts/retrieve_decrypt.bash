#!/bin/bash

# retrieves and transfers a file from PDC

set -e

########
# VARS #
########

RESTORE_FILE=$1
DEST_SERVER=$2
DEST_DIR=$3

if [[ ${#@} -ne 3 ]]; then
    >&2 echo -e "USAGE:\n\t$0 source_filename server dest_dir"
    exit 1
fi

RUNDIR=$(dirname $RESTORE_FILE)
RUN=$(basename $RESTORE_FILE)
RUN=${RUN%%.*}

#############
# FUNCTIONS #
#############

log() {
    NOW=$(date +"%Y%m%d%H%M%S")
    echo "[${NOW}] $@"
}

finish() {
    if [[ -e $FIFO ]]; then
        rm $FIFO
    fi
    if [[ -e $KEY_FILE ]]; then
        rm $KEY_FILE
    fi
}

#########
# TRAPS #
#########

trap finish EXIT ERR

########
# MAIN #
########

read -s -p "Passphrase: " PASSPHRASE

# get the encrypted key first
KEY_FILE=$(mktemp -u)
log "dsmc retrieve '${RUNDIR}/${RUN}.key.gpg' $KEY_FILE"
dsmc retrieve "${RUNDIR}/${RUN}.key.gpg" $KEY_FILE

# create named pipe
FIFO=$(mktemp -u)
mkfifo $FIFO

# init the tunnel
cat $FIFO | gpg --cipher-algo aes256 --passphrase-file <(gpg --cipher-algo aes256 --passphrase "$PASSPHRASE" --batch --decrypt ${KEY_FILE}) --batch --decrypt | ssh $DEST_SERVER "cd ${DEST_DIR} && tar xzf -" &

# retrieve the backup
log "dsmc retrieve '$RESTORE_FILE' $FIFO"
dsmc retrieve "$RESTORE_FILE" $FIFO
