#!/bin/bash

# will create a dated directory in LOGDIR and
# mv all logs older than a month into that one

. /mnt/hds/proj/bioinfo/SCRIPTS/log.bash

log $(getversion)

LOGDIR=/mnt/hds/proj/bioinfo/LOG/
THISMONTH=$(date +'%Y%m01')

log "Creating $LOGDIR/$THISMONTH"
[[ -d $THISMONTH ]] || mkdir -p $LOGDIR/$THISMONTH

log "Moving $LOGDIR > $LOGDIR/$THISMONTH"
find $LOGDIR -maxdepth 1 -not -type d -not -newermt $THISMONTH -print0 | xargs -0 -I % mv % $LOGDIR/$THISMONTH/
