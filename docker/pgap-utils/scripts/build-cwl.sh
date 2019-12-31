#!/bin/bash
#
#
#  Prepares workflows in the location specified by root directory parameter (home) and input global version file
#
#

sdir=$(dirname $(readlink -f $0))
source $sdir/global_version_file_tools.source

global_version_file="$1"; shift
home="$1"; shift

set -euxo pipefail

if [ "$home" = "" ]; then
    echo "usage: $0 global_version_file home" >&2
    die "Specify all params" 
fi
global_version=$(get_global_version "$global_version_file")
owner=ncbi-gpipe
repo=pgap
workflows_root="$home/$global_version/$repo" # it will be added by checkout
rm -rf "$workflows_root"
mkdir -p "$workflows_root"
GITHUB_VERSION=$(get_github_version "$global_version_file")
docker_tag=$(get_docker_tag "$global_version_file")


cd "$workflows_root"
git init
git remote add origin https://github.com/$owner/$repo.git # note that we are NOT using SSH, because we do not need to git push
git pull origin master
git checkout  --detach "$GITHUB_VERSION"
#
#   We need to use precisely the same version of docker image as specified in global version manifest
#
perl -i -pe 's{dockerPull: .*}{dockerPull: '"$docker_tag"'}g' *.cwl */*.cwl
#
#   Create input/ directory
#
ln -s ../input .

# we are ready to run!