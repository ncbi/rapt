#!/bin/bash

branch="release"
version=$( curl -s https://api.github.com/repos/ncbi/pgap/releases/latest | grep \"name\" | cut -d\" -f4 )

buildname=$( echo "$version-$branch" | tr "." "-" )

packer build \
       -var "branch=$branch" \
       -var "version=$version" \
       -var "buildname=$buildname" \
       rapt.json
