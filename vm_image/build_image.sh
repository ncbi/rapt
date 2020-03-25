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

# The following gcloud command sets the image created above to be public
# Need to get the image name first before this can be used
# gcloud compute images add-iam-policy-binding image-name --member='allAuthenticatedUsers' --role='roles/compute.imageUser'
