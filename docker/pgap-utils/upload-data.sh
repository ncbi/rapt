#!/bin/bash
#
#  TeamCity step Copy data to S3
#
#
#  Input parameters: environmental variable PGAP_BUILD_TYPE
#

set -uexo pipefail

VERSION=`cat binaries/VERSION`

inputdir=input-${VERSION}
ln -sf ${inputdir} input
pids=
for files_from in files-from.*.list; do
    (
        package=$(echo "$files_from" | perl -pe 's{files-from\.}{}; s{\.list}{}' )
        tarfile=${inputdir}.${PGAP_BUILD_TYPE}."$package".tgz
        tar cvzf ${tarfile} --files-from <(
            cat "$files_from" |
            grep -vP '^#'  | 
            grep -P '\S' | 
            perl -pe 's{^}{'"$inputdir"'/}' 
            ) 
        aws s3 cp --acl public-read --no-progress ${tarfile} s3://pgap/${tarfile}
    ) &
    pids="$pids $!"
done
for pid in $pids; do
    wait $pid
done

