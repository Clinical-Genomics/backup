import sys
import os
import shutil
from collections import namedtuple

Item = namedtuple('Item', 'name weight value'.split())

def get_files(indir):
    for root, dirs, files in os.walk(indir, topdown=False):
    	for file_name in files:
            if file_name.endswith('.tar.gz'):
    	        f = os.path.join(root, file_name)
                file_size = os.path.getsize(f)
                value = file_size / 100000000
                yield Item(file_name, file_size, value)

def efficiency(item):
    """Return efficiency of item (its value per unit weight)."""
    return float(item.value) / float(item.weight)

def packing(items, max_weight=1300000000000):
    """Return a list of items with the maximum value, subject to the
    constraint that their combined weight must not exceed max_weight.

    """    
    def pack(item):
        # Attempt to pack item; return True if successful.
        if item.weight <= pack.max_weight:
            pack.max_weight -= item.weight
            return True
        else:
            return False

    pack.max_weight = max_weight
    return list(filter(pack, sorted(items, key=efficiency, reverse=True)))

def main(argv):
    if len(argv) < 3:
        print("USAGE: knapsack indir outdir max_file_size_bytes")
        print("	Moves max_file_size_bytes files from indir to outdir")
        exit()

    indir = argv[0]
    outdir = argv[1]
    max_file_size = int(argv[2])

    packed_items = packing(get_files(indir), max_file_size)
    for packed_item in packed_items:
        print(packed_item.name)
        shutil.move(os.path.join(indir, packed_item.name), os.path.join(outdir, packed_item.name))
        shutil.move(os.path.join(indir, packed_item.name + '.md5.txt'), os.path.join(outdir, packed_item.name + '.md5.txt'))

if __name__ == '__main__':
    main(sys.argv[1:])
