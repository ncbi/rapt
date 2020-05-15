#!/bin/bash
#
#  TeamCity step Create tarballs for upload
#
#
#  Input parameters: PGAP_BUILD_TYPE
#

set -uexo pipefail
PGAP_BUILD_TYPE=$1

VERSION=`cat binaries/VERSION`

inputdir=input-${VERSION}
ln -sf ${inputdir} input
pids=
tarballs_file=tarballs.for.upload
rm -f "$tarballs_file"
for files_from in files-from.*.list; do
    package=$(echo "$files_from" | perl -pe 's{files-from\.}{}; s{\.list}{}' )
    if [ "$package" = "pgap" ]; then
        tarfile=${inputdir}.${PGAP_BUILD_TYPE}.tgz
    else
        tarfile=${inputdir}.${PGAP_BUILD_TYPE}."$package".tgz
    fi
    (
        tar cvzf ${tarfile}  --mode='u+w' --files-from <(
            cat "$files_from" |
            grep -vP '^#'  | 
            grep -P '\S' | 
            perl -pe 's{^}{'"$inputdir"'/}' 
            ) 
    ) &
    pids="$pids $!"
    echo "$tarfile" >> "$tarballs_file"
done
for pid in $pids; do
    wait $pid
done

