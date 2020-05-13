#!/bin/bash
set -eux

echo "##teamcity[progressMessage 'Validate Config']]"
packer validate pgapx-dev.json

echo "##teamcity[progressMessage 'Build Image']]"
packer build -machine-readable pgapx-dev.json | tee build.log
grep 'artifact,0,id' build.log | rev | cut -f1 -d, | cut -f1 -d: | rev > ami-id.txt
grep 'cwltool.*whl' build.log | rev | cut -f1 -d/ | rev | cut -f1,2 -d- > cwltool-ver.txt