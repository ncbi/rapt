#!/bin/bash
set -eux
BRANCH=$1 # %teamcity.build.branch%

echo "##teamcity[progressMessage 'Determine Build Type']]"
PGAP_BUILD_TYPE=$BRANCH

echo "##teamcity[progressMessage 'Generate Container Image']]"
echo "##teamcity[blockOpened name='buildImage' description='Generate Container Image']"
./build-image.sh $PGAP_BUILD_TYPE
echo "##teamcity[blockClosed name='buildImage']"

echo "##teamcity[progressMessage 'Save Container Image']]"
echo "##teamcity[blockOpened name='saveImage' description='Save Container Image']"
./save-image.sh $PGAP_BUILD_TYPE
echo "##teamcity[blockClosed name='saveImage']"

echo "##teamcity[progressMessage 'Push to hub.docker.com']]"
echo "##teamcity[blockOpened name='pushImage' description='Push to hub.docker.com']"
./push-image.sh $PGAP_BUILD_TYPE
echo "##teamcity[blockClosed name='pushImage']"
