#!/bin/bash
#
#  TeamCity step Copy data to GS
#

set -uexo pipefail
key_file="$1"; shift; # /panfs/pan1/gpipe/etc/.gpipe_gcp/ncbi-pgapx-f16c4ab8be62.json
# project=ncbi-pgapx
project=$(grep '"project_id"' "$key_file" | cut -d'"' -f4)
gcloud auth activate-service-account --project="$project" --key-file="$key_file"
tarballs_file=tarballs.for.upload
pids=
for tarfile in $(cat "$tarballs_file" /dev/null); do
    (
        gsutil cp -a public-read ${tarfile}  gs://pgap/${tarfile}
        #  --no-progress ${tarfile} 
    ) &
    pids="$pids $!"
done
for pid in $pids; do
    wait $pid
done
