#!/bin/bash
#
#   script generates global version UUID and global version file in designated unique and new location
#
#   it collects latest versioning information from three sources   
#
#       - Bitbucket project
#       - TeamCity project
#       - Github project
#
#   it requires password protected access to Bitbucket
#
#   It takes one parameter: location of root directory for storing versions
#
#   Output: location of generated global version file
#
sdir=$(dirname $(readlink -f $0))
source $sdir/global_version_file_tools.source
set -uexo pipefail
set +e
home=$1
set -e
if [ "$home" = "" ]; then
    echo "Specify root directory for storing versions" >&2
    exit 1
fi
global_version=$(dbus-uuidgen)
mkdir -p $home/$global_version
global_version_file=$home/$global_version/global_version.txt
#
#   TeamCity
#
artifact=install.prod.tar.gz
buildType=GP_DEV_SoftwareCompilationArtifactGeneration_ReleaseWoDependencies
tmpRESTfulAPIxml=t.xml
wget -O $tmpRESTfulAPIxml -N https://teamcity.ncbi.nlm.nih.gov/guestAuth/app/rest/builds/?locator=buildType:$buildType,status:success,count:1
TC_VERSION=$(xpath $tmpRESTfulAPIxml '//build[@id]/@id' 2> /dev/null | cut -f2 -d= | cut -f2 -d'"' )
#
#   Github
#
owner=ncbi-gpipe
repo=pgap
wget -O $tmpRESTfulAPIxml -N https://api.github.com/repos/$owner/$repo/commits
set +e
GITHUB_VERSION=$(grep '"sha"' $tmpRESTfulAPIxml | head -1 | cut -f2 -d: | cut -f2 -d'"')
set -e
#
#   Bitbucket
#
project=gpext
repo=pgap
BITBUCKET_VERSION=$(git ls-remote  https://$USER@bitbucket.ncbi.nlm.nih.gov/scm/$project/$repo.git | grep HEAD | cut -f1)
#
#   Create global version file (manifest)
#
rm -f $global_version_file
add_global_version "$global_version_file" "$global_version"
add_tc_version "$global_version_file" "$TC_VERSION"
add_github_version "$global_version_file" "$GITHUB_VERSION"
add_bitbucket_version "$global_version_file" "$BITBUCKET_VERSION"



