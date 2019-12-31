#!/bin/bash
#
#   Wrapper that massages input directory to an input manifest and output manifest into output directory
#
#   serves two types of commands
#   "store": cache_kmer -cache-path Path -kmer-files-manifest File -store  kmer-files-output-manifest File -k 18
#   Example from most recent dev TC buildrun:
/panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/dev/automated_builds/installations/regr_bct/2018-05-16.prod.build98/bin/cache_kmer \
#    -cache-path \
#    /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/ThirdParty/ExternalData/Pathogen/kmer-cache-minhash/ \
#    -k 18 \
#    -passthrough \
#    -kmer-files-output-manifest \
#    /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/regr/data_bct/Streptococcus_pneumoniae_JJA/19788-DENOVO-20180516-1506.461594/906797/kmer_cache_store.102709482/out/kmer_file_list.mft \
#    -kmer-files-manifest \
#    /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/regr/data_bct/Streptococcus_pneumoniae_JJA/19788-DENOVO-20180516-1506.461594/906797/kmer_cache_store.102709482/inp/kmer_file_list.mft

#   "retrieve": cache_kmer -cache-path Path -retrieve -k 18 -new-gc-ids-output File -new-gc-ids-output-manifest ManifestFile
#
set -euxo pipefail
die()
{
    echo "$1" >&2
    exit 1
}
cache_input_dir=
cache_output_dir=
input_manifest=
input_manifest_option="kmer-files-manifest"   
output_manifest_option="kmer-files-output-manifest"
export PATH="$PATH:$GP_HOME/arch/x86_64/bin"
executable=$(basename $0 _dir.sh)
declare -a ARGS
ARGS=()
# separate additional parameters from default parameters
while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        -cache-output-dir)
            cache_output_dir="$2"; shift; shift
            ;;
        -cache-input-dir)
            cache_input_dir="$2"; shift; shift
            ;;
        -$input_manifest_option|-$output_manifest_option)
            # we are scraping these options because we are using them internally
            input_manifest="$2"
            shift; shift;
            ;;
        *)
            # ARGS=( "${ARGS[@]}" "$1" ) #  ARGS[@]: unbound variable
            ARGS[${#ARGS[*]}]="$1"
            shift
            ;;
    esac
done    
#
#   input conversion and parameter specification
#
if [ "$cache_input_dir" != "" ]; then
    input_manifest=inp.mft
    find "$cache_input_dir" -type f > "$input_manifest"
    # ARGS=( "${ARGS[@]}" -$input_manifest_option "$input_manifest" )
    ARGS[${#ARGS[*]}]="-$input_manifest_option"
    ARGS[${#ARGS[*]}]="$input_manifest"
fi
if [ "$cache_output_dir" != "" ]; then
    output_manifest=out.mft
    ARGS[${#ARGS[*]}]="-$output_manifest_option"
    ARGS[${#ARGS[*]}]="$output_manifest"
fi
set +e
$executable "${ARGS[@]}" 
output_exit_code=$?
#
#   output conversion
#
if [ "$cache_output_dir" != "" ]; then
    mkdir -p $cache_output_dir/18; # hardcoded k !!!!!!
    if [ -r $output_manifest ]; then
        cp $(grep -vh '#' $output_manifest) $cache_output_dir/18;
    fi
fi    
exit $output_exit_code