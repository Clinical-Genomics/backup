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

RUN_DIR=$(dirname $RESTORE_FILE)
RUN_FILE=$(basename $RESTORE_FILE)
RUN_NAME=${RUN_FILE%%.*}

#############
# FUNCTIONS #
#############

log() {
    NOW=$(date +"%Y%m%d%H%M%S")
    echo "[${NOW}] $@"
}

finish() {
    # remove key
    if [[ -e $KEY_FILE ]]; then
        log "removing key $KEY_FILE"
        CMD="rm $KEY_FILE"
        log $CMD
    fi
    # remove retrieved file
    if [[ -e ${RETRIEVED_FILE} ]]; then
        log "removing retrieved file ${RETRIEVED_FILE}"
        CMD="rm ${RETRIEVED_FILE}"
        log $CMD
    fi

    # remove decrypted file
    if [[ -e ${DECRYPTED_FILE} ]]; then
        log "removing decrypted file ${DECRYPTED_FILE}"
        CMD="rm ${DECRYPTED_FILE}"
        log $CMD
    fi

    # remove decompressed folder
    if [[ -e ${RUN_NAME} ]]; then
        log "removing decompressed folder ${RUN_NAME}"
        CMD="rm -rf ${RUN_NAME}"
        log $CMD
    fi
}

#########
# TRAPS #
#########

trap finish EXIT ERR

########
# MAIN #
########

# create TMP
TMP_DIR="${RUN_NAME}.TMP"
CMD="mkdir ${TMP_DIR}"
log $CMD
CMD="cd ${TMP_DIR}"
log $CMD

# get the encrypted key first
KEY_FILE=${RUN_NAME}.key.gpg
CMD="dsmc retrieve '${RUN_DIR}/${RUN_NAME}.key.gpg' $KEY_FILE"
log $CMD

# retrieve run
RETRIEVED_FILE="./${RUN_FILE}"
CMD="dsmc retrieve '$RESTORE_FILE' ${RETRIEVED_FILE}"
log $CMD

# decrypt run
DECRYPTED_FILE="${RUN_FILE%%.gpg}"
CMD="gpg --cipher-algo aes256 --passphrase-file <(gpg --cipher-algo aes256 --passphrase '$PASSPHRASE' --batch --decrypt ${KEY_FILE}) --batch --decrypt ${RUN_FILE} > ${DECRYPTED_FILE}"
log $CMD

# decompress run
CMD="tar xf $DECRYPTED_FILE --exclude='RTAComplete.txt' --exclude='demuxstarted.txt' --exclude='Thumbnail_Images'"
log $CMD

if [[ ${DEST_SERVER} == 'localhost' ]]; then

  # rsync run
  CMD="time rsync -r --progress {$RUN_NAME} ${DEST_DIR} --partial-dir=${DEST_DIR}.partial --delay-updates"
  log $CMD

  CMD=${DEST_DIR}/${RUN}/RTAComplete.txt
  log $CMD
else
  # rsync run
  CMD="time rsync -r --progress {$RUN_NAME} hiseq.clinical@$DEST_SERVER:${DEST_DIR} --partial-dir=${DEST_DIR}.partial --delay-updates"
  log $CMD

  # mark as finished
  CMD="ssh $DEST_SERVER 'touch ${DEST_DIR}/${RUN_NAME}/RTAComplete.txt'"
  log $CMD
fi

log "finished retrieval, decryption and decompression!"
