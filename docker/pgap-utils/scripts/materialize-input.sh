#!/bin/bash
#
#  materializes input/ from input-links/
#
#  we need a separate process, because it might take a long time

sdir=$(dirname $(readlink -f $0))
source $sdir/global_version_file_tools.source

global_version_file="$1"; shift
home="$1"; shift

set -euxo pipefail

if [ "$home" = "" ]; then
    echo "usage: $0 global_version_file home" >&2
    die "Specify all params" 
fi
global_version=$(get_global_version "$global_version_file")
input="$home/$global_version/input-links"
output="$home/$global_version/input"
rm -rf $output

cp -rL $input $output
rm -f $output/uniColl_path/Naming.fa # 4Gb shaved off

