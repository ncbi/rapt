#!/bin/bash

set -euxo pipefail

sdir=$(readlink -f $(dirname $0))
read VERSION < VERSION

$sdir/build_image.sh "$VERSION"


