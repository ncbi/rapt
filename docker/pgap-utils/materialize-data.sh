#!/bin/bash
#
#  TeamCity step Materialize Data
#
set -uexo pipefail

VERSION=`cat binaries/VERSION`

input=input-links  # third party data from upstream artifact from classic PGAP software build ("Release", etc)
output=input-${VERSION}
##
## Process links from third party data
##
rm -f $input/uniColl_path/Naming.fa # 4Gb shaved off
rm -rf $output
#
#   remove self-links. 
#       1/ At this point we possess them as part of local input-links structure (not as part of link to global third party directory where we cannot and should not edit anything)
#       2/ We are also not relying on their existence, since we resolved first round of self-reference
#       in fetch-data.shaved
#
find "$input/" -type l | xargs ls -ld | grep -Poh '\S+ \-\> \.$' | cut -f1 -d' ' | xargs rm 

cp -rL $input $output
#
#   Process kmer things
#
cp -rL /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/ThirdParty/ExternalData/Pathogen/kmer-cache-minhash/18.sqlite/production/* \
    $output/
    
/panfs/pan1/gpipe/bacterial_pipeline/system/current/bin/gp_sh bact /panfs/pan1/gpipe/bacterial_pipeline/system/current/bin/gp_sql \
    -database GCExtract \
    -output kmer_uri_list.raw \
    -server GPIPE_BCT \
    -sql-file /panfs/pan1/gpipe/bacterial_pipeline/system/current/etc/ani/kmer.bacterial.reference.sql 

# there is a high probability of slight desync between kmer.sqlite and reference list, 
# we need to set intersect now to take care of it here
   
sqlite3 $output/kmer.sqlite "select key from KmerMetadata" > sqlite.keys
join <(sort sqlite.keys) <(sort kmer_uri_list.raw) > $output/kmer_uri_list
rm -f kmer_uri_list.raw sqlite.keys

rm -f $output/assemblies.fasta # 41G shaved off
rm -f $output/uniColl_path/Naming.fa # 4Gb shaved off

#
#    Special case of POSIX-noncompliancy: UNIX backup files, do not abort, just delete
#
find "$output" -name \*'~' -type f | while read file; do
    rm -f -- "$file"
done

##
##  Process other data that we need
##
gunzip --stdout  /am/ftp-genomes/ASSEMBLY_REPORTS/species_genome_size.txt.gz > "$output"/species_genome_size.txt
#
#   I do not like "+" in name and cwltool proved to be capricious about filenames in the past. PGAPX-420
#
cp -r /panfs/pan1/gpipe/ThirdParty/ExternalData/Contamination/production/CommonContaminants/adaptors_for_screening_proks+euks.fa "$output"/adaptor_fasta.fna
mkdir -p "$output"/contam_in_prok_blastdb_dir
cp /panfs/pan1/gpipe/ThirdParty/ExternalData/Contamination/production/CommonContaminants/contam_in_prok.??? "$output"/contam_in_prok_blastdb_dir/
USERNAME=ncbi
IMAGE="$1"
VERSION=$(cat binaries/VERSION)
docker_tag="$USERNAME/$IMAGE:$VERSION"
docker run -i -w /tmp/t \
    --volume=$(readlink -f "$output"):/tmp/t:ro \
    --volume=$(readlink -f ./):/tmp/scripts:ro \
     "$docker_tag"  /tmp/scripts/checksum.sh > "$output/checksum.md5"

##
##   Last steps
##

##
##   md5 check sum
##



##
##   Catch-all: abort if non-UNIX compliant
##
compliant=true
find "$output" | while read path; do
    set +e
    if  echo "$path" | grep --quiet -P '[\|\&\;\<\>\(\)\$\`\\\"'"'"' \t\*\?\[\]\#\~\=\%]'; then
        echo ERROR: path "'$path'" contains one of POSIX shell metacharacters or characters not allowed for Internationalized Domain Names for Applications >&2
        compliant=false
    fi
    set -e
done

if ! $compliant; then
    echo ERROR: some of the files contain one of POSIX shell metacharacters or characters not allowed for Internationalized Domain Names for Applications >&2
    exit 1
else
    exit 0
fi


