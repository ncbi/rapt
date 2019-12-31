#!/bin/bash 
#
# This script must be maintained according to following principles:
#   - cloud-agnostic way:
#       - one should be able to run it both on the cloud and locally at premises
#   - platform-agnostic way:
#       - primary purpose is to run from TeamCity, but developers should be able to run it as well for testing
#
# Preconditions:
#   Implies that previous steps from a given TeamCity build (see directory of this file in repo for buildType)
#   are performed and data is present locally
#
set -euxo pipefail
use_case="$1"; shift # ani pgap ani-pgap
branch_flag="$1"; shift # in TeamCity it should be %teamcity.build.branch%
pgap_version="$1"; shift # in TeamCity it should be %pgap_version%
genome_dir="$1"; shift # in TeamCity it should be %genome_dir%
input_yaml="$1"; shift # in TeamCity it should be %input_yaml%

vmstat -t -a -n -SM 1 > vmstat.log &
vmstatid1=$!
vmstat -t -a -n -SM 120 &
vmstatid120=$!
#
#   make sure that we wrap up background vms stuff when we exit
#
function finish()
{
    echo EXITING ; 
    kill $vmstatid1 ; 
    kill $vmstatid120
}
function die()
{
    echo "$1" >&2;
    exit 1;
}

trap finish EXIT
use_case_param=
case "$use_case" in
    pgap)  
          ;;
    tax-check)
          use_case_param=--tax-check-only
          ;;
    pgap-tax-check)
          use_case_param=--tax-check
          ;;
    *)
        die "wrong use_case argument"
        ;;
esac
          
./pgap.py --"$branch_flag" \
  "$use_case_param" \
  --debug \
  --quiet \
  --use-version "$pgap_version"  \
  --report-usage-false \
  --ignore-all-errors \
  ./"$branch_flag"/test_genomes-"$pgap_version"/"$genome_dir"/"$input_yaml"          
kill $vmstatid1
kill $vmstatid120
#
#   reset abnormal exit cleanup because we are done with vms at this point
#
trap '' EXIT
vmstat -t -a -n -SM


