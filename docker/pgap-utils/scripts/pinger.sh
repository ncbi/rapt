#!/bin/bash
UUIDFILE=uuid.txt
if [ "$1" = "do_report" ]; then
    shift 1
else
    # Always create an output file
    touch $UUIDFILE
    echo "Sending usage metrics to NCBI is disabled"
    exit 0
fi

# The second argument is either a request to generate the UUID, or an
# input file containing an UUID.
if [ "$1" = "make_uuid" ]; then
    UUID=`uuidgen | tee uuid.txt`
else
    UUID=`cat $1 | tee uuid.txt`
fi
shift 1


if [[ -z "$PGAP_VERSION" ]]; then
    PGAP_VERSION="unknown"
fi

BASEURL="https://www.ncbi.nlm.nih.gov/stat?ncbi_app=pgapx&version=${PGAP_VERSION}"

URL="${BASEURL}&uuid=${UUID}"
while (( "$#" >= 2 )); do
    URL="$URL&$1=$2"
    shift 2
done

if curl -sf --output /dev/null -- "$URL"; then
    echo "Usage metrics sent to NCBI"
else
    echo "Failed to send usage metrics to NCBI"
fi
exit 0
