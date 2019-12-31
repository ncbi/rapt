#!/usr/bin/env python3

import json
import sys
import yaml

args = len(sys.argv)
inFile = sys.stdin
outFile = sys.stdout
if args > 1:
    inFile = open(sys.argv[1], 'rt', encoding='ISO-8859-1') 
if args > 2:
    outFile = open(sys.argv[2], 'w')
    
y=yaml.safe_load(inFile.read())
json.dump(y, outFile)
