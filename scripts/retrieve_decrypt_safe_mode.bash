#!/bin/bash

# retrieves and transfers a file from PDC

set -o errexit
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
KEY_FILE="${RUN_NAME}.key.gpg"
RETRIEVED_FILE="./${RUN_FILE}"
DECRYPTED_FILE="${RUN_FILE%%.gpg}"
SEMAPHORE="running"

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

cleanup() {

    log "Removing files in temporary folder '${TMP_DIR}':"
    log_exc cd ${START_DIR}/${TMP_DIR}
    list_files

    log "removing dsmc error log dsmerror.log"
    log_exc remove_file dsmerror.log

    log "removing key $KEY_FILE"
    log_exc remove_file $KEY_FILE

    log "removing retrieved run file ${RETRIEVED_FILE}"
    log_exc remove_file ${RETRIEVED_FILE}

    log "removing decrypted file ${DECRYPTED_FILE}"
    log_exc remove_file ${DECRYPTED_FILE}

    log "removing decompressed folder ${RUN_NAME}"
    log_exc remove_folder_recursive ${RUN_NAME}

    log "removing semaphore file " ${SEMAPHORE}
    log_exc remove_file ${SEMAPHORE}

    log_exc remove_empty_folder ${START_DIR}/${TMP_DIR}
    log "finished!"
}

show_dsmc_errors() {
  log_exc tail dsmerror.log
}

remove_file() {
  TO_REMOVE=$1
  if [[ -f ${TO_REMOVE} ]]; then
      log "Removing file ${TO_REMOVE}"
      log_exc rm ${TO_REMOVE}
  fi
}

remove_empty_folder() {
  TO_REMOVE=$1
  if [[ -d ${TO_REMOVE} ]]; then
      log "Removing empty folder ${TO_REMOVE}"
      log_exc rmdir ${TO_REMOVE}
  fi
}

remove_folder_recursive() {
  TO_REMOVE=$1
  if [[ -d ${TO_REMOVE} ]]; then
      log "Removing folder recursively ${TO_REMOVE}"
      log_exc rm -rf ${TO_REMOVE}
  fi
}

error() {
  log "Something went wrong! leaving files for manual handling:"
  list_files
}

list_files() {
  for entry in "$START_DIR/$TMP_DIR"/*
  do
    log "$entry"
  done
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
  log_exc mkdir ${TMP_DIR}
fi
log_exc cd ${TMP_DIR}

if [[ ! -f ${SEMAPHORE} ]]; then
  log_exc touch ${SEMAPHORE}
else
  log "Semaphore file ${SEMAPHORE} exists, quiting"
  exit 0
fi

# STEP 1: get the encrypted key
# if not exists or confirm_overwrite
trap "remove_file ${KEY_FILE}; error" ERR
if [[ ! -f ${KEY_FILE} ]]; then
  TMP_KEY=${KEY_FILE}.tmp
  log_exc dsmc retrieve -replace=yes ${RUN_DIR}/${RUN_NAME}.key.gpg ${TMP_KEY}
  mv ${TMP_KEY} ${KEY_FILE}
else
  log "Found key file ${KEY_FILE}, skipping retrieving key"
fi

# STEP 2: retrieve run
trap "remove_file ${RETRIEVED_FILE}; error" ERR
if [[ ! -f ${RETRIEVED_FILE} ]]; then
  TMP_RETRIEVED_FILE=${RETRIEVED_FILE}.tmp
  log_exc dsmc retrieve -replace=yes ${RESTORE_FILE} ${TMP_RETRIEVED_FILE}
  mv ${TMP_RETRIEVED_FILE} ${RETRIEVED_FILE}
else
  log "Found run file ${RETRIEVED_FILE}, skipping retrieving run"
fi

# STEP 3: decrypt run
trap "remove_file ${DECRYPTED_FILE}; error" ERR
if [[ ! -f ${DECRYPTED_FILE} ]]; then
  TMP_DECRYPTED_FILE=${DECRYPTED_FILE}.tmp
  log "gpg --cipher-algo aes256 --passphrase-file <(gpg --cipher-algo aes256 --passphrase <NOT-SHOWN> --batch --decrypt ${KEY_FILE}) --batch --decrypt ${RUN_FILE} > ${DECRYPTED_FILE}"
  gpg --cipher-algo aes256 --passphrase-file <(gpg --cipher-algo aes256 --passphrase "${PASSPHRASE}" --batch --decrypt ${KEY_FILE}) --batch --decrypt ${RUN_FILE} > ${DECRYPTED_FILE}
  mv ${TMP_DECRYPTED_FILE} ${DECRYPTED_FILE}
else
  log "Found decrypted run file ${DECRYPTED_FILE}, skipping gpg decrypting run"
fi

# STEP 4: decompress run
trap "remove_folder_recursive ${RUN_NAME}; error" ERR
if [[ ! -d ${RUN_NAME} ]]; then
  TMP_RUN_NAME=${RUN_NAME}.tmp
  if [[ ! -d ${TMP_RUN_NAME} ]]; then
    log_exc mkdir ${TMP_RUN_NAME}
  fi

  log_exc tar -xf ${DECRYPTED_FILE} --exclude=RTAComplete.txt --exclude=demuxstarted.txt --exclude=Thumbnail_Images -C ${TMP_RUN_NAME}
  mv ${TMP_RUN_NAME}/${RUN_NAME} ${RUN_NAME}
else
  log "Found decompressed run folder ${RUN_NAME}, skipping decompressing run"
fi

trap error ERR

if [[ ${DEST_SERVER} == 'localhost' ]]; then

  # STEP 5: rsync run
  log_exc mkdir -p ${DEST_DIR}
  log_exc mv ${RUN_NAME} ${DEST_DIR}

  # STEP 6: mark as finished
  log_exc touch ${DEST_DIR}/${RUN_NAME}/RTAComplete.txt
else
  # STEP 5: rsync run
  log_exc ssh $DEST_SERVER mkdir -p ${DEST_DIR}
  log_exc rsync -r ${RUN_NAME} hiseq.clinical@$DEST_SERVER:${DEST_DIR}

  # STEP 6: mark as finished
  log_exc ssh $DEST_SERVER touch ${DEST_DIR}/${RUN_NAME}/RTAComplete.txt
fi

log "finished retrieval, decryption and decompression!"

cleanup
