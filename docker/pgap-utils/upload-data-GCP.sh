#!/bin/bash
#
#  TeamCity step Copy data to GS
#

set -uexo pipefail
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

