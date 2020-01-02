#!/bin/bash
set -euxo pipefail
BRANCH=$1

echo "##teamcity[progressMessage 'Creating tarball']]"
VERSION=$(cat VERSION)
FILENAME=test_genomes-${VERSION}
TARBALL=$FILENAME.$BRANCH.tgz
URL="s3://pgap-data/${TARBALL}"
mv test_genomes $FILENAME
ln -s $FILENAME test_genomes
tar cvzf $TARBALL $FILENAME test_genomes

echo "##teamcity[progressMessage 'Uploading to S3']]"
aws s3 cp --acl public-read $TARBALL ${URL}
