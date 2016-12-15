#!/bin/bash

mkdir -p /home/hiseq.clinical/SCRIPTS/git
mkdir -p /home/hiseq.clinical/{ENCRYPT,BACKUP}/
cd /home/hiseq.clinical/SCRIPTS/git/
git clone https://github.com/clinical-genomics/backup.git
cd /home/hiseq.clinical/SCRIPTS/

rm checkfornewrun.bash gpg-pigz.batch sendtopdc.bash
ln -s git/backup/scripts/checkfornewrun.bash
ln -s git/backup/scripts/gpg-pigz.batch
ln -s git/backup/scripts/sendtopdc.bash

