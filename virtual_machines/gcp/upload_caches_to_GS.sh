#!/bin/bash

set -euxo pipefail
#
# Uploads blast caches in current directory to the GS URI specified by two positional parametrs:
#    1: GS project name (ncbi-pgapx for testing the script, ncbi-pathogen for production)
#    2: GS bucket (pgap-cache for testing the script, pgap-cache-prod for production)
#

project="$1"; shift
bucket="$1"; shift
read VERSION < VERSION

gcloud auth activate-service-account --project="$project" --key-file=/panfs/pan1/gpipe/etc/.gpipe_gcp/"$project"-*.json

gcp -m scp -r blast_hits_cache-*.$VERSION gs://"$bucket"/

