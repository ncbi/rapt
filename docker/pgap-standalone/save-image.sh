#!/bin/bash
set -uexo pipefail

IMAGE=pgap
if [ $# -ne 0 ]; then
   IMAGE=${IMAGE}-${1}
fi

USERNAME=ncbi
VERSION=$(cat VERSION)

docker_tag="$USERNAME/$IMAGE:$VERSION"
#docker_file="${USERNAME}_${IMAGE}_${VERSION}.tar"
docker_file="docker_image.tgz"

docker save "$docker_tag" | gzip > $docker_file

