#!/bin/bash
set -euxo pipefail

sdir=$(readlink -f $(dirname $0))

branch="release"
version=$( curl -s https://api.github.com/repos/ncbi/pgap/releases/latest | grep \"name\" | cut -d\" -f4 )

$sdir/build_image.sh "$version"
