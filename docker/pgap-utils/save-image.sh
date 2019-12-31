#!/bin/bash
#
#  TeamCity step Generate Container Image, substep 2
#
set -uexo pipefail

USERNAME=ncbi
if [ -z "$1" ]
then
    echo "Must supply image name, e.g. gpdev or pgap"
    exit 1
fi
IMAGE=$1

VERSION=$(cat binaries/VERSION)

docker_tag="$USERNAME/$IMAGE:$VERSION"
#docker_file="${USERNAME}_${IMAGE}_${VERSION}.tar"
docker_file="docker_image.tgz"

docker save "$docker_tag" | gzip > $docker_file

