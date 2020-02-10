#!/bin/bash

branch="release"
version=$( curl -s https://api.github.com/repos/ncbi/pgap/releases/latest | grep \"name\" | cut -d\" -f4 )

#branch="test"
#version="2019-10-29.build4114"

buildname=$( echo "$version-$branch" | tr "." "-" )

packer build \
       -var "branch=$branch" \
       -var "version=$version" \
       -var "buildname=$buildname" \
       pgapx-gcp.json
