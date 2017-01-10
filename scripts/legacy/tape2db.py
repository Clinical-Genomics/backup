#!/usr/bin/env python
# encoding: utf-8

from __future__ import print_function, division

import sys
import os
import time
from datetime import datetime
import yaml
from os.path import expanduser

from glob import glob

from sqlalchemy.orm import Load

from clinstatsdb.db.store import connect
from clinstatsdb.db.models import Backuptape, Backup

class Config:

    def __init__(self):
        with open(expanduser("~/.clinical/databases.yaml"), 'r') as ymlfile:
            self.config = yaml.load(ymlfile)

    def __getitem__(self, key):
        """Simple array-based getter.

        Args:
            key (str): Gets the value for this key in the YAML file.

        Returns (str, dict): returns the structure underneat this key.

        """
        return self.config[key]

def get_runs(d):
    files = [f for f in os.listdir(d)]
    for file in files:
        if file.endswith('.tar.gz'):
            yield file

def get_mtime(filename):
    """Get the creation date of a file. Format it to %Y%m%d %H%M%S

    Args:
        filename (str): full path to file

    Returns: a datetime formatted string to %Y-%m-%d %H:%M:%S

    """

    # Mon Mar 16 22:06:21 2015
    filename_mtime = time.ctime(os.path.getmtime(filename))
    return datetime.strptime(filename_mtime, '%a %b %d %H:%M:%S %Y').strftime('%Y-%m-%d %H:%M:%S')

def get_run_startdate(run_name):
    """Gets the startdate of a run based on its name

    Args:
        run_name (str): name of the run date_machine_number_flowcell

    Returns: date

    """
    return run_name.split('_')[0]

def main(argv):
    tape_dir = argv[0]
    tape_name = os.path.basename(tape_dir.rstrip('/'))

    config = Config()
    SQL = connect(config['clinstats']['connection_string'])

    tape_id = Backuptape.exists(tape_name)
    print("TAPE: {} {}".format(tape_name, tape_id))
    if not tape_id:
        backup_band_name_files = glob(os.path.join(tape_dir, 'Backup_band_namn*-1.txt'))
        backup_band_name_files.sort(key=os.path.getmtime)
        backup_band_name_file = backup_band_name_files[0]
        tape_date = get_mtime(backup_band_name_file)

        backuptape = Backuptape()
        backuptape.tapedir = tape_name
        # backuptape.nametext = '' # TODO
        backuptape.tapedate = tape_date

        SQL.add(backuptape)
        SQL.flush()

        tape_id = backuptape.backuptape_id
        print(tape_id)

    runs = get_runs(tape_dir)
    for run in runs:
        run_name = run.replace('.tar.gz', '')
        backup_runname = Backup.exists(run_name)
        print('Arch name: ' + str(backup_runname))
        if backup_runname:
            backup = SQL.query(Backup).filter(Backup.runname==run_name).one()
        else:
            backup = Backup()
            backup.startdate = get_run_startdate(run_name)
        backup.runname = run_name
        backup.backuptape_id = tape_id
        backup.backupdone = get_mtime(os.path.join(tape_dir, run))
        print('Arch done: ' + backup.backupdone)
        backup.md5done = get_mtime(os.path.join(tape_dir, run + '.md5.txt'))
        print('MD5 done : ' + backup.md5done)

        SQL.add(backup)
        SQL.flush()

    SQL.commit()


if __name__ == '__main__':
    main(sys.argv[1:])
