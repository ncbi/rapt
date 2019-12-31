#!/bin/bash

# 1. Determine Build Type

TARBALL=install_gencoll_release.tar.gz
IMAGE_NAME=pgap-utils
BUILD_TYPE=%teamcity.build.branch%
if [ "${BUILD_TYPE}" = "dev" ]; then
  TARBALL=install_gencoll.tar.gz
fi
IMAGE_NAME=${IMAGE_NAME}-${BUILD_TYPE}
cat <<EOF
##teamcity[setParameter name='env.PGAP_BUILD_TYPE' value='${BUILD_TYPE}']
##teamcity[setParameter name='env.TOOLKIT_TARBALL' value='${TARBALL}']
##teamcity[setParameter name='env.DOCKER_IMAGE_NAME' value='${IMAGE_NAME}']
EOF
 
# 2. Fetch binaries and third party data

./fetch-data.sh ${TOOLKIT_TARBALL} \
    %teamcity.build.branch% \
    %dep.GP_GpPgap2_Release.build.vcs.number.pgap_2% \
    %dep.GP_GpPgap2_Release.vcsroot.pgap_2.url%

# 3. Generate Container Image

./build-image.sh ${DOCKER_IMAGE_NAME}
./save-image.sh ${DOCKER_IMAGE_NAME}

# 4. Archive input-links

tar cvzf input-links.tgz input-links

# 5. Materialize Data

./materialize-data.sh

# 6. Copy data to S3
 
./upload-data.sh
