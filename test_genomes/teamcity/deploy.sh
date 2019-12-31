#!/bin/bash
set -euxo pipefail
VERSION=$(cat VERSION)
FILENAME=test_genomes-${VERSION}
TARBALL=$FILENAME.%teamcity.build.branch%.tgz
URL="%test_genome_url%${TARBALL}"
mv test_genomes $FILENAME
ln -s $FILENAME test_genomes
tar cvzf $TARBALL $FILENAME test_genomes
aws s3 cp --acl public-read $TARBALL ${URL}
