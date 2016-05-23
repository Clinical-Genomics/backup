#!/bin/bash

RUNPATH=${1?'Please provide fully qualified path to the archive'}
REMOTE=$2
REMOTE_DIR=$3

if [[ ${#@} -lt 2 ]]; then
    >&2 echo -e "USAGE:\n\t$0 source_filename dest_dir"
    >&2 echo -e "\t$0 source_filename server dest_dir"
    exit 1
fi

RUNDIR=$(dirname $RUNPATH)
RUN=$(basename $RUNPATH)
RUN=${RUN%%.*}

read -s -p "Passphrase: " PASSPHRASE

if [[ ${#@} -eq 2 ]]; then
    echo "gpg --cipher-algo aes256 --passphrase-file <(gpg --cipher-algo aes256 --passphrase ******** --batch --decrypt ${RUNDIR}/${RUN}.key.gpg) --batch --decrypt ${RUNDIR}/${RUN}.tar.gz.gpg | tar xz - -C ${REMOTE}"
    gpg --cipher-algo aes256 --passphrase-file <(gpg --cipher-algo aes256 --passphrase "$PASSPHRASE" --batch --decrypt ${RUNDIR}/${RUN}.key.gpg) --batch --decrypt ${RUNDIR}/${RUN}.tar.gz.gpg | tar xz - -C ${REMOTE}
elif [[ ${#@} -eq 3 ]]; then
    echo "gpg --cipher-algo aes256 --passphrase-file <(gpg --cipher-algo aes256 --passphrase ******** --batch --decrypt ${RUNDIR}/${RUN}.key.gpg) --batch --decrypt ${RUNDIR}/${RUN}.tar.gz.gpg | ssh $REMOTE \"tar xz - -C ${REMOTE_DIR}\""
    gpg --cipher-algo aes256 --passphrase-file <(gpg --cipher-algo aes256 --passphrase "$PASSPHRASE" --batch --decrypt ${RUNDIR}/${RUN}.key.gpg) --batch --decrypt ${RUNDIR}/${RUN}.tar.gz.gpg  | ssh $REMOTE "cd ${REMOTE_DIR} && tar xzf -"
fi
