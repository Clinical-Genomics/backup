#!/bin/bash

VERSION=3.1.0
echo "VERSION ${VERSION}"

# exit on empty var (to avoid to mv an empty ${RUN}
set -u

RUNDIR=/mnt/hds2/proj/bioinfo/Runs/
OLDRUNDIR=/mnt/hds2/proj/bioinfo/oldRuns/
BACKUPDIR=/mnt/hds/proj/bioinfo/BACKUP/
NASRUNDIR=/home/hiseq.clinical/Runs/
NASOLDRUNDIR=/home/hiseq.clinical/oldRuns/

RUNS=$(find ${RUNDIR} -maxdepth 1 -mtime +15 | awk 'BEGIN {FS="/"} {print $NF}')
for RUN in ${RUNS}; do
    echo ${BACKUPDIR}/${RUN}.tar.gz

    echo "tar -czf ${BACKUPDIR}/${RUN}.tar.gz ${RUNDIR}/${RUN}/"
    tar -czf ${BACKUPDIR}/${RUN}.tar.gz ${RUNDIR}/${RUN}/

    echo "md5sum ${BACKUPDIR}/${RUN}.tar.gz > ${BACKUPDIR}/${RUN}.tar.gz.md5.txt"
    md5sum ${BACKUPDIR}/${RUN}.tar.gz > ${BACKUPDIR}/${RUN}.tar.gz.md5.txt

    echo "mv ${RUNDIR}/${RUN} ${OLDRUNDIR}/"
    mv ${RUNDIR}/${RUN} ${OLDRUNDIR}/

    for NAS in seq-nas-2 nas-7 nas-8 nas-9 nas-10; do
        ssh ${NAS} "ls ${NASRUNDIR}/${RUN}"
        sshcommand=$?
        if [[ ${sshcommand} != 0 ]] ; then
            echo "skipping ${NAS}..."
	    continue # it's not on this NAS
        fi

        echo "ssh ${NAS} 'mv ${NASRUNDIR}/${RUN} ${NASOLDRUNDIR}'"
        ssh ${NAS} "mv ${NASRUNDIR}/${RUN} ${NASOLDRUNDIR}"
        sshcommand=$?
        NOW=$(date +"%Y%m%d%H%M%S")
        if [[ ${sshcommand} != 0 ]] ; then
            echo "ssh ${NAS} mv ${NASRUNDIR}${RUN} ${NASOLDRUNDIR} failed:${sshcommand}"
        else
            echo "ssh ${NAS} mv ${NASRUNDIR}${RUN} ${NASOLDRUNDIR} completed"
        fi
        break
    done
done
