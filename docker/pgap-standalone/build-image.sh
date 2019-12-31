#!/bin/bash
set -ex

BASE=pgap-utils
IMAGE=pgap
if [ $# -ne 0 ]; then
    BUILD_TYPE=${1}
    BASE=${BASE}-${BUILD_TYPE}
    IMAGE=${IMAGE}-${BUILD_TYPE}
fi

USERNAME=ncbi
VERSION=`cat VERSION`

docker build --build-arg BASE="${BASE}" --build-arg PGAP_VERSION="${VERSION}" -t $USERNAME/$IMAGE:$VERSION .
docker tag $USERNAME/$IMAGE:$VERSION $USERNAME/$IMAGE:latest
