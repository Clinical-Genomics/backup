#!/bin/bash

# retrieves and transfers a file from PDC

set -e -o pipefail

########
# VARS #
########

if [[ ${#@} -ne 3 ]]; then
    >&2 echo -e "USAGE:\n\t$0 source_filename server dest_dir"
    exit 1
fi

RESTORE_FILE=$1
DEST_SERVER=$2
DEST_DIR=$3

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
    if [[ -e $KEY_FILE ]]; then
        rm $KEY_FILE
    fi
    if [[ -e $FIFO ]]; then
        rm $FIFO
    fi
}

#########
# TRAPS #
#########

trap finish EXIT ERR

########
# MAIN #
########

# get the encrypted key first
KEY_FILE=$(mktemp -u)
log "dsmc retrieve '${RUNDIR}/${RUN}.key.gpg' $KEY_FILE"
dsmc retrieve "${RUNDIR}/${RUN}.key.gpg" $KEY_FILE

# create named pipe
FIFO=$(mktemp -u)
mkfifo $FIFO

# init the tunnel
if [[ ${DEST_SERVER} == 'localhost' ]]; then
    cd ${DEST_DIR}
    cat $FIFO | gpg --cipher-algo aes256 --passphrase-file <(gpg --cipher-algo aes256 --passphrase "$PASSPHRASE" --batch --decrypt ${KEY_FILE}) --batch --decrypt | tar xzf - --exclude=${RUN}/RTAComplete.txt &

    # retrieve the backup
    log "dsmc retrieve -replace=yes '$RESTORE_FILE' $FIFO"
    dsmc retrieve -replace=yes "$RESTORE_FILE" $FIFO


    log "touch ${DEST_DIR}/${RUN}/RTAComplete.txt"
    touch ${DEST_DIR}/${RUN}/RTAComplete.txt

else
    cat $FIFO | gpg --cipher-algo aes256 --passphrase-file <(gpg --cipher-algo aes256 --passphrase "$PASSPHRASE" --batch --decrypt ${KEY_FILE}) --batch --decrypt | ssh $DEST_SERVER "cd ${DEST_DIR} && tar xzf - --exclude=${RUN}/RTAComplete.txt" &

    # retrieve the backup
    log "dsmc retrieve -replace=yes '$RESTORE_FILE' $FIFO"
    dsmc retrieve -replace=yes "$RESTORE_FILE" $FIFO

    log "ssh $DEST_SERVER 'touch ${DEST_DIR}/${RUN}/RTAComplete.txt'"
    ssh $DEST_SERVER "touch ${DEST_DIR}/${RUN}/RTAComplete.txt"
fi
