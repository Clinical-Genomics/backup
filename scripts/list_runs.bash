#!/bin/bash

# list all runs since a certain data

readarray -t LINES <<< "$(dsmc q archive "/mnt/hds/proj/bioinfo/TO_PDC/*")"

OUTFILE=$(mktemp)
EMAILS=kenny.billiau@scilifelab.se

declare -A FILESIZE_OF

for LINE in "${LINES[@]}"; do
    LINE_PARTS=( $(echo $LINE) )

    # skip non-run lines
    if [[ $LINE != *.gpg* ]]; then
         continue
    fi

    arch_date=$(date -d "${LINE_PARTS[2]} ${LINE_PARTS[3]}" +%s)
    comp_date=$(date -d 'yesterday 00:00' +%s)

    if [[ $arch_date -ge $comp_date ]]; then
         FILESIZE_OF[${LINE_PARTS[4]}]=${LINE_PARTS[0]}
    fi
done

readarray -t SORTED_FILENAMES <<< "$(for k in ${!FILESIZE_OF[@]}; do echo $k; done | sort --version-sort)"

for FILENAME in ${SORTED_FILENAMES[@]}; do
    printf '%15s %s\n' ${FILESIZE_OF[$FILENAME]} $FILENAME >> $OUTFILE
done

cat $OUTFILE | mail -s 'PDC report' $EMAILS

rm $OUTFILE
