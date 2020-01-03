#!/bin/bash
#
#  TeamCity step  Generate Container Image  
#
set -uexo pipefail
sdir=$(dirname $(readlink -f "$0"))
USERNAME=ncbi
if [ -z "$1" ]
then
    echo "Must supply image name, e.g. gpdev or pgap"
    exit 1
fi
IMAGE="$1"

VERSION=$(cat binaries/VERSION)
BINDIR=/panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/bacterial_pipeline/system/${VERSION}/arch/x86_64/bin
LIBDIR=/panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/bacterial_pipeline/system/${VERSION}/arch/x86_64/lib
TRNASCAN_VERSION=2.0.4

docker_tag="$USERNAME/$IMAGE:$VERSION"
docker_production_tag="$USERNAME/$IMAGE:latest"

docker --log-level debug  build \
       --file "$sdir/Dockerfile" \
       --build-arg version=${VERSION} \
       --build-arg bindir=${BINDIR} \
       --build-arg libdir=${LIBDIR} \
       --build-arg trnascan_version=${TRNASCAN_VERSION} \
       -t  "$docker_tag" .
#       
# we will never do tagging right after building, see JIRA: GP-24568
#
# temporarily introduce tagging back for the sake of testing  GP-24592
#docker tag "$docker_tag"  "$docker_production_tag" # comment this out during testing. "latest" tag is always production
