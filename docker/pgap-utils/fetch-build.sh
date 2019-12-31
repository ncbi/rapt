#!/bin/bash

set -uexo pipefail

if [ -z "$1" ]
then
    echo "Must supply tarball name, e.g. install.tar.gz or install.prod.tar.gz"
    exit 1
fi
tarball=$1

TC_VERSION=
TC_BUILD=
if [ "$TC_VERSION" = "" ]; then
    tc_version_tag=.lastSuccessful
else
    tc_version_tag="${TC_VERSION}:id"
fi
if [ "$TC_BUILD" = "" ]; then
    tc_build_tag=GP_GpPgap2_Release
    #tc_build_tag=GP_DEV_SoftwareCompilationArtifactGeneration_ReleaseWoDependencies
fi

rm -rf binaries
mkdir -p binaries
wget -N https://teamcity.ncbi.nlm.nih.gov/guestAuth/repository/download/$tc_build_tag/$tc_version_tag/$tarball

