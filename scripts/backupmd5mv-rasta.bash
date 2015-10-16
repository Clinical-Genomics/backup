#!/bin/bash

VERSION=1.3.0
echo "VERSION ${VERSION}"

RUNDIR=/mnt/hds2/proj/bioinfo/Runs/
OLDRUNDIR=/mnt/hds2/proj/bioinfo/oldRuns/
BACKUPDIR=/mnt/hds/proj/bioinfo/BACKUP/
NASRUNDIR=/home/hiseq.clinical/Runs/
NASOLDRUNDIR=/home/hiseq.clinical/oldRuns/

for RUN in $( cd ${RUNDIR} && ls -1); do
    echo ${BACKUPDIR}/${RUN}.tar.gz

    echo tar -czf ${BACKUPDIR}/${RUN}.tar.gz ${RUNDIR}/${RUN}/
    tar -czf ${BACKUPDIR}/${RUN}.tar.gz ${RUNDIR}/${RUN}/

    echo "md5sum ${BACKUPDIR}/${RUN}.tar.gz > ${BACKUPDIR}/${RUN}.tar.gz.md5.txt"
    md5sum ${BACKUPDIR}/${RUN}.tar.gz > ${BACKUPDIR}/${RUN}.tar.gz.md5.txt

    echo mv ${RUNDIR}/${RUN} ${OLDRUNDIR}/
    mv ${RUNDIR}/${RUN} ${OLDRUNDIR}/

    for NAS in seq-nas-1 nas-7 nas-8 nas-9 nas-10; do
        ssh ${NAS} "ls ${NASRUNDIR}/${run}"
        sshcommand=$?
        if [[ ${sshcommand} != 0 ]] ; then
            echo "skipping ${NAS}..."
	    continue # it's not on this NAS
        fi

        ssh ${NAS} "mv ${NASRUNDIR}/${run} ${NASOLDRUNBASE}"
        sshcommand=$?
        NOW=$(date +"%Y%m%d%H%M%S")
        if [[ ${sshcommand} != 0 ]] ; then
            echo "ssh ${NAS} mv ${NASRUNDIR}${run} ${NASOLDRUNDIR} failed:${sshcommand}"
        else
            echo "ssh ${NAS} mv ${NASRUNDIR}${run} ${NASOLDRUNDIR} completed"
        fi
    done
done
