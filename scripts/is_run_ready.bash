#!/bin/bash

set -e
set -u

IN_FILE=${1-/tmp/to_pdc}
RUN_DIR=/home/hiseq.clinical/Runs/
ENCRYPT_DIR=/home/hiseq.clinical/ENCRYPT/

# COLORS
RED="\033[0;31m"
ORANGE="\033[0;33m"
GREEN="\033[0;32m"
RESET="\033[0m"

for RUN in ${RUN_DIR}/*; do
    RUN=${RUN##*/}

    # check if run is ready for archiving
    RTAComplete_found=$(find ${RUN_DIR}/${RUN} -maxdepth 1 -name RTAComplete.txt -mtime +5 | wc -l)
    if [[ $RTAComplete_found -gt 0 ]]; then
        if [[ ! -e ${ENCRYPT_DIR}/${RUN}_started ]]; then
            echo -e "${RED}${RUN}${RESET}"
        else
            echo -e "${ORANGE}${RUN}${RESET}"
        fi
    else
        echo "${RUN}"
    fi
done
