#!/bin/bash
#set -x

sdir=$(dirname $(readlink -f $0))
global_version_file="$1"; shift
set -uexo pipefail
source $sdir/scripts/global_version_file_tools.source
global_version=
TC_VERSION=
GITHUB_VERSION=
BITBUCKET_VERSION=

if [ "$global_version_file" != "" ]; then
    global_version=$(get_global_version "$global_version_file")
    TC_VERSION=$(get_tc_version "$global_version_file")
    GITHUB_VERSION=$(get_github_version "$global_version_file")
    BITBUCKET_VERSION=$(get_bitbucket_version "$global_version_file")
fi

USERNAME=ncbi
IMAGE=gpdev
Dockerfile=$sdir/Dockerfile
if [ "$BITBUCKET_VERSION" = "" ]; then
    git pull # git checkout would be better but risky
else
    # git checkout "$BITBUCKET_VERSION" # even riskier, do nothing for now
    true
fi

if [ "$TC_VERSION" = "" ]; then
    tc_build_tag=.lastSuccessful
else
    tc_build_tag="${TC_VERSION}:id"
fi
wget -N https://teamcity.ncbi.nlm.nih.gov/guestAuth/repository/download/GP_DEV_SoftwareCompilationArtifactGeneration_ReleaseWoDependencies/$tc_build_tag/install.prod.tar.gz
set +e
VERSION=`tar -tf install.prod.tar.gz | head -n1 | cut -f1 -d/`
set -e
mkdir -p tmp
tar --exclude='*/etc' --exclude='*/setup' --exclude='*/src.tar.gz' -xvf install.prod.tar.gz -C tmp
files=`find tmp/next/arch/x86_64/bin -maxdepth 1 -type f -not -name "*.p*" -not -name "*.txt" -print`
$sdir/package_dependencies.sh tmp/next/arch/x86_64/bin $files
linked_exe=`find tmp/next/arch/x86_64/bin -maxdepth 1 -type l -print | grep -f exe_links.whitelist | xargs ls -l | cut -d'>' -f2 | tr -d '\n'`
tar cvPf linked_exe.tar $linked_exe

# collect apps and dependencies using pgap_app_list and replace install.prod.tar.gz
mkdir tmp/next/arch/x86_64/tmp
cat ${sdir}/pgap_app_list | ${sdir}/collect_dependencies.sh tmp/next/arch/x86_64/ tmp/next/arch/x86_64/tmp
rm -r tmp/next/arch/x86_64/bin tmp/next/arch/x86_64/lib
mv -v -t tmp/next/arch/x86_64 tmp/next/arch/x86_64/tmp/* 
rm -r tmp/next/arch/x86_64/tmp
rm -rf install.prod.tar.gz
cd tmp
tar -cvPf ../install.prod.tar *
cd ..
gzip install.prod.tar

rm -rf tmp

BINDIR=/panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/bacterial_pipeline/system/${VERSION}/arch/x86_64/bin
LIBDIR=/panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/bacterial_pipeline/system/${VERSION}/arch/x86_64/lib

mkdir -p bin
cp -r \
    /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/ThirdParty/infernal/production/arch/x86_64/bin/* \
    /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/ThirdParty/sparclbl/production/* \
    bin/
rsync -avP --exclude src --exclude *.tar.gz --exclude 1.21-patched --exclude 1.21-patched-2 --exclude 1.21-patched-3 \
    /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/ThirdParty/tRNAscan-SE \
    .

mkdir -p etc/yum.repos.d
cp /etc/yum.repos.d/ncbi.repo etc/yum.repos.d
cp /etc/toolkitrc etc
cp /etc/.ncbirc etc
cp /etc/resolv.conf etc

docker_tag="$USERNAME/$IMAGE:$VERSION"
docker_production_tag="$USERNAME/$IMAGE:latest"

docker build \
       --build-arg version=${VERSION} \
       --build-arg bindir=${BINDIR} \
       --build-arg libdir=${LIBDIR} \
       -t  "$docker_tag" .
if [ "$global_version_file" != "" ]; then       
    add_docker_tag       "$global_version_file"  "$docker_tag"
fi    
docker tag "$docker_tag"  "$docker_production_tag" # comment this out during testing. "latest" tag is always production
rm -f install.prod.tar.gz libraries.tar linked_exe.tar
