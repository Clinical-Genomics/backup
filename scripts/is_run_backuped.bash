#!/bin/bash

set -e

IN_FILE=$1
BACKUP_DIR=/home/hiseq.clinical/BACKUP/

# COLORS
RED="\033[0;31m"
GREEN="\033[0;32m"
RESET="\033[0m"

for RUN in ${BACKUP_DIR}/*; do
    RUN=${RUN##*/}

    # is the run on PDC?
    read -a RUN_SIZE <<< $(grep ${RUN}.tar.gz.gpg ${IN_FILE})
    if [[ ${#RUN_SIZE[@]} -ne 2 ]]; then
        echo -e "${RED}${RUN}${RESET}\t"
        continue
    else
        echo -en "${RUN}\t"
    fi

    # check size
    SIZE=${RUN_SIZE[0]};
    SIZE=${SIZE//,}
    if grep -qs Description,NIPTv1 ${BACKUP_DIR}/${RUN}/SampleSheet.csv; then # NIPT RUN
        EXPECTED_SIZE=9000000 # 9GB
    elif [[ ${RUN} == *CCXX ]]; then
        EXPECTED_SIZE=580000000 # 550GB
    else
        EXPECTED_SIZE=35000000 # 35GB
    fi

    if [[ $SIZE -lt $EXPECTED_SIZE ]]; then
        echo -en "${RED}${SIZE}${RESET}\t"
    else
        echo -en "${GREEN}${SIZE}${RESET}\t"
    fi

    # check the key
    read -a KEY <<< $(grep ${RUN}.key.gpg ${IN_FILE})
    if [[ ${#KEY[@]} -ne 2 ]]; then
        echo -e "${RED}MISSING KEY${RESET}"
    else
        if [[ ${KEY[0]} -ne 607 ]]; then
            echo -e "${RED}KEY WRONG SIZE ${KEY[0]}${RESET}"
        else
            echo -e "${GREEN}KEY FOUND${RESET}"
        fi
    fi
done
