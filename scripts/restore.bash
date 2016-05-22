#!/bin/bash

# retrieves and transfers a file from PDC

set -e

########
# VARS #
########

RESTORE_FILE=$1
DEST_SERVER=$2
DEST_FILE=$3

if [[ ${#@} -ne 3 ]]; then
    >&2 echo -e "USAGE:\n\t$0 source_filename server dest_filename"
    exit 1
fi

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
}

#########
# TRAPS #
#########

trap finish EXIT ERR

########
# MAIN #
########

# create named pipe
FIFO=$(mktemp -u)
mkfifo $FIFO

# init the tunnel
log "cat $FIFO | ssh $DEST_SERVER 'cat > $DEST_FILE' &"
cat $FIFO | ssh $DEST_SERVER "cat > $DEST_FILE" &

# retrieve the backup
log "dsmc retrieve '$RESTORE_FILE' $FIFO"
dsmc retrieve "$RESTORE_FILE" $FIFO
