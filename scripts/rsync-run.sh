#!/bin/bash

set -e

RUNDIR=${1?'please provide a rundir'}
RUN=${RUNDIR##*/}
FC=${RUNDIR##*_}
FC=${FC:1}

rsync -rv --ignore-existing ${RUNDIR} --exclude RTAComplete.txt --exclude Thumbnail_Images rasta:/mnt/hds2/proj/bioinfo/Runs/ && ssh rasta "touch /mnt/hds2/proj/bioinfo/Runs/${RUN}/RTAComplete.txt"

