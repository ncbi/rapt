#!/bin/bash

branch="release"
version="$1"; shift

buildname=$( echo "$version-$branch" | tr "." "-" )

packer build \
       -var "branch=$branch" \
       -var "version=$version" \
       -var "buildname=$buildname" \
       pgapx-gcp.json
