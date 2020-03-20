#!/bin/bash

branch="release"
version=$( curl -s https://api.github.com/repos/ncbi/pgap/releases/latest | grep \"name\" | cut -d\" -f4 )

buildname=$( echo "$version-$branch" | tr "." "-" )

echo "Building $buildname, note that this should take about 30 minutes on a good day."

packer build \
       -var "branch=$branch" \
       -var "version=$version" \
       -var "buildname=$buildname" \
       rapt.json
