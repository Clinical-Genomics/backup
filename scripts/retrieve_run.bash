#!/bin/bash

# retrieves and transfers a file from PDC

set -eu -o pipefail

########
# VARS #
########

if [[ ${#@} -ne 3 ]]; then
    >&2 echo -e "USAGE:\n\t$0 fc server dest_dir"
    exit 1
fi

FC=$1
DEST_SERVER=$2
DEST_DIR=$3

#############
# FUNCTIONS #
#############

source backup.functions
ON_PDC_FILE=$(get_pdc_runs)

log() {
    NOW=$(date +"%Y%m%d%H%M%S")
    echo "[${NOW}] $@"
}

finish() {
    if [[ -e ${ON_PDC_FILE} ]]; then
        rm ${ON_PDC_FILE}
    fi
}

#########
# TRAPS #
#########

trap finish EXIT ERR

########
# MAIN #
########

IFS=\$' ' read -ra ON_PDC_RUN <<< $(grep "${FC}.tar.gz.gpg" ${ON_PDC_FILE})
unset IFS

RUN=${ON_PDC_RUN[2]}

echo bash retrieve_decrypt.bash ${RUN} ${DEST_SERVER} ${DEST_DIR}
