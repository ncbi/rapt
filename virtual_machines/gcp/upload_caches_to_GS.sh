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
key_file=$(grep -l '"project_id": "'"$project"'"' /panfs/pan1/gpipe/etc/.gpipe_gcp/*.json)

gcloud auth activate-service-account --project="$project" --key-file="$key_file"

gsutil -m cp -r blast_hits_cache-*.$VERSION gs://"$bucket"/

