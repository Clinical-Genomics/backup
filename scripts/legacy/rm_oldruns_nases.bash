#!/bin/bash

NASES=(clinical-nas-1 clinical-nas-2 seq-nas-1 seq-nas-2 seq-nas-3 nas-6 nas-7 nas-8 nas-9 nas-10)
SCRIPT_DIR=$(dirname $0)

for NAS in ${NASES[@]}; do
    echo "bash ${SCRIPT_DIR}/rm_oldruns_nas.bash ${NAS}"
    bash ${SCRIPT_DIR}/rm_oldruns_nas.bash ${NAS}
done
