#!/bin/bash
set -uexo pipefail

IMAGE=pgap
if [ $# -ne 0 ]; then
   IMAGE=${IMAGE}-${1}
fi

USERNAME=ncbi
VERSION=$(cat VERSION)

docker_tag="$USERNAME/$IMAGE:$VERSION"

docker push "$docker_tag"


