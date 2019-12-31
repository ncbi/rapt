#!/bin/bash

set -uexo pipefail

TARBALL=install.tar.gz
NAME=pgap-utils
#TARBALL=install.prod.tar.gz
#NAME=gpdev

./fetch-build.sh $TARBALL
./fetch-data.sh $TARBALL
./build-image.sh $NAME
