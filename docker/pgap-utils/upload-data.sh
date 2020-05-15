#!/bin/bash
#
#  TeamCity step Copy data to S3
#
#
#  Input parameters: PGAP_BUILD_TYPE
#

set -uexo pipefail
tarballs_file=tarballs.for.upload
pids=

for tarfile in $(cat "$tarballs_file" /dev/null); do
    (
        aws s3 cp --acl public-read --no-progress ${tarfile} s3://pgap/${tarfile}
        #  --no-progress ${tarfile} 
    ) &
    pids="$pids $!"
done
for pid in $pids; do
    wait $pid
done
