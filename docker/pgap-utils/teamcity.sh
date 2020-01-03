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

#cat <<EOF
##teamcity[setParameter name='env.PGAP_BUILD_TYPE' value='${BUILD_TYPE}']
##teamcity[setParameter name='env.TOOLKIT_TARBALL' value='${TARBALL}']
##teamcity[setParameter name='env.DOCKER_IMAGE_NAME' value='${IMAGE_NAME}']
#EOF
 
echo "##teamcity[progressMessage 'Fetch binaries and third party data']]"
./fetch-data.sh $TARBALL $BRANCH $SVNREV $SVNURL

echo "##teamcity[progressMessage 'Generate Container Image']]"
./build-image.sh $IMAGE_NAME
./save-image.sh $IMAGE_NAME

echo "##teamcity[progressMessage 'Archive input-links']]"
tar cvzf input-links.tgz input-links

echo "##teamcity[progressMessage 'Materialize Data']]"
./materialize-data.sh

echo "##teamcity[progressMessage 'Copy data to S3']]"
./upload-data.sh
