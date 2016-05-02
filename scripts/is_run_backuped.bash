#!/bin/bash

set -e

IN_FILE=$1
BACKUP_DIR=/home/hiseq.clinical/BACKUP/

# COLORS
RED="\033[0;31m"
GREEN="\033[0;32m"
RESET="\033[0m"

while read -a REPLY; do
    SIZE=${REPLY[0]};
    RUN=${REPLY[1]};

    if [[ -z ${RUN} ]]; then
        continue
    fi

    if [[ ${RUN} == *.key.gpg ]]; then
        continue
    fi

    SIZE=${SIZE//,}
    RUN=${RUN##*/}
    RUN=${RUN%%.*}
    if [[ -e ${BACKUP_DIR}/${RUN} ]]; then
        # check size
        if grep -qs Description,NIPTv1 ${BACKUP_DIR}/${RUN}/SampleSheet.csv; then # NIPT RUN
            EXPECTED_SIZE=9000000 # 9GB
        elif [[ ${RUN} == *CCXX ]]; then
            EXPECTED_SIZE=580000000 # 550GB
        else
            EXPECTED_SIZE=35000000 # 35GB
        fi

        
        echo -en "${RUN}\t"
        if [[ $SIZE -lt $EXPECTED_SIZE ]]; then
            echo -en "${RED}${SIZE}${RESET}\t"
        else
            echo -en "${GREEN}${SIZE}${RESET}\t"
        fi

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
    fi
done < ${IN_FILE}
