#!/bin/bash

# retrieves and transfers a file from PDC

set -o errexit
set -o nounset
set -o pipefail
set -E

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

START_DIR=$(pwd)
RUN_DIR=$(dirname $RESTORE_FILE)
RUN_FILE=$(basename $RESTORE_FILE)
RUN_NAME=${RUN_FILE%%.*}
TMP_DIR="${RUN_NAME}.TMP"
KEY_FILE=${RUN_NAME}.key.gpg
RETRIEVED_FILE="./${RUN_FILE}"
DECRYPTED_FILE="${RUN_FILE%%.gpg}"

#############
# FUNCTIONS #
#############

log() {
    NOW=$(date +"%Y%m%d%H%M%S")
    echo "`echo $'\n '`[${NOW}] $@"
}

log_exc() {
    log "$@"
    $@
}

cleanup() {
    # remove key
    if [[ -e $KEY_FILE ]]; then
        log "removing key $KEY_FILE"
        log_exc "rm $KEY_FILE"
    fi
    # remove retrieved file
    if [[ -e ${RETRIEVED_FILE} ]]; then
        log "removing retrieved file ${RETRIEVED_FILE}"
        log_exc "rm ${RETRIEVED_FILE}"
    fi

    # remove decrypted file
    if [[ -e ${DECRYPTED_FILE} ]]; then
        log "removing decrypted file ${DECRYPTED_FILE}"
        log_exc "rm ${DECRYPTED_FILE}"
    fi

    # remove decompressed folder
    if [[ -d ${RUN_NAME} ]]; then
        log "removing decompressed folder ${RUN_NAME}"
        log_exc "rm -rf ${RUN_NAME}"
    fi

    # temporary folder
    cd ${START_DIR}
    if [[ -d ${TMP_DIR} ]]; then
        log "removing temporary folder ${TMP_DIR}"
        log_exc "rm -rf ${TMP_DIR}"
    fi

    log "finished!"
}

error() {
  log "Something went wrong! leaving files for manual handling:"
  for entry in "$START_DIR/$TMP_DIR"/*
  do
    echo "$entry"
  done
}

not_exists_or_confirm_overwrite() {
  if [ ! -e "$1" ]
  then
    return 1
  else
    read -p "`echo $'\n '`File $1 already exist, Overwrite? " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      return 1
    else
      return 0
    fi
  fi
}

#########
# TRAPS #
#########

trap error ERR

########
# MAIN #
########

# create TMP
if [[ ! -d ${TMP_DIR} ]]; then
  log_exc "mkdir ${TMP_DIR}"
fi
log_exc "cd ${TMP_DIR}"

# get the encrypted key first
# if not exists or confirm_overwrite
if [[ $(not_exists_or_confirm_overwrite ${KEY_FILE}) ]]; then
  log_exc "dsmc retrieve -replace=yes '${RUN_DIR}/${RUN_NAME}.key.gpg' '${KEY_FILE}'"
else
  log "skipping retrieving key"
fi

# retrieve run
if [[ $(not_exists_or_confirm_overwrite ${RETRIEVED_FILE}) ]]; then
  log_exc "dsmc retrieve -replace=yes '${RESTORE_FILE}' '${RETRIEVED_FILE}'"
else
  log "skipping retrieving run"
fi

# decrypt run
if [[ $(not_exists_or_confirm_overwrite ${DECRYPTED_FILE}) ]]; then
  log_exc "time gpg --cipher-algo aes256 --passphrase-file <(gpg --cipher-algo aes256 --passphrase '${PASSPHRASE}' --batch --decrypt ${KEY_FILE}) --batch --decrypt ${RUN_FILE} > ${DECRYPTED_FILE}"
else
  log "skipping gpg"
fi

# decompress run
if [[ $(not_exists_or_confirm_overwrite ${RUN_NAME}) ]]; then
  log_exc "time tar xf ${DECRYPTED_FILE} --exclude='RTAComplete.txt' --exclude='demuxstarted.txt' --exclude='Thumbnail_Images'"
else
  log "skipping untaring"
fi

if [[ ${DEST_SERVER} == 'localhost' ]]; then
  # rsync run
  if [[ $(not_exists_or_confirm_overwrite ${DEST_DIR}) ]]; then
    log_exc "time rsync -r --progress ${RUN_NAME} ${DEST_DIR} --partial-dir=${DEST_DIR}.partial --delay-updates"
  else
    log "skipping rsync"
  fi

  # mark as finished
  log_exc "touch ${DEST_DIR}/${RUN_NAME}/RTAComplete.txt"
else
  # rsync run
  if [[ $(not_exists_or_confirm_overwrite ${DEST_DIR}) ]]; then
    log_exc "time rsync -r --progress ${RUN_NAME} hiseq.clinical@$DEST_SERVER:${DEST_DIR} --partial-dir=${DEST_DIR}.partial --delay-updates"
  else
    log "skipping rsync"
  fi

  # mark as finished
  log_exc "ssh $DEST_SERVER 'touch ${DEST_DIR}/${RUN_NAME}/RTAComplete.txt'"
fi

log "finished retrieval, decryption and decompression!"

cleanup

}