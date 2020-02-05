#!/bin/bash
set -eux
BRANCH=$1 # %teamcity.build.branch%
SVNREV=$2 # %dep.GP_GpPgap2_Release.build.vcs.number.pgap_2% \
SVNURL=$3 # %dep.GP_GpPgap2_Release.vcsroot.pgap_2.url% we always have this, even for origin/dev builds

echo "##teamcity[progressMessage 'Determine Build Type']]"
TARBALL=install_gencoll_release.tar.gz
IMAGE_NAME=pgap-utils
BUILD_TYPE=$BRANCH
if [ "${BUILD_TYPE}" = "dev" ]; then
  TARBALL=install_gencoll.tar.gz
fi
IMAGE_NAME=${IMAGE_NAME}-${BUILD_TYPE}

set +x

echo "##teamcity[progressMessage 'Fetch binaries and third party data']]"
echo "##teamcity[blockOpened name='FetchData' description='Fetch binaries and third party data']"
./fetch-data.sh $TARBALL $BRANCH $SVNREV $SVNURL
echo "##teamcity[blockClosed name='FetchData']"

echo "##teamcity[progressMessage 'Generate Container Image']]"
echo "##teamcity[blockOpened name='Container' description='Generate Container Image']"
./build-image.sh $IMAGE_NAME
./save-image.sh $IMAGE_NAME
echo "##teamcity[blockClosed name='Container']"

echo "##teamcity[progressMessage 'Archive input-links']]"
echo "##teamcity[blockOpened name='Archive' description='Archive input-links']"
tar cvzf input-links.tgz input-links
echo "##teamcity[blockClosed name='Archive']"

echo "##teamcity[progressMessage 'Materialize Data']]"
echo "##teamcity[blockOpened name='Materialize' description='Materialize Data']"
./materialize-data.sh
echo "##teamcity[blockClosed name='Materialize']"

echo "##teamcity[progressMessage 'Copy data to S3']]"
echo "##teamcity[blockOpened name='S3' description='Copy data to S3']"
./upload-data.sh $BUILD_TYPE
echo "##teamcity[blockClosed name='S3']"
