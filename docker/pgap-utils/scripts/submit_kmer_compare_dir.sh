#!/bin/bash
#
#   Wrapper that massages input directory to an input manifest and output manifest into output directory
#
#   Example from most recent dev TC buildrun:
# /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/bacterial_pipeline/system/2018-05-13.build2788/bin/submit_kmer_compare \
#  -o|-output file.xml
#    -kmer-files-manifest \
#    /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/bacterial_pipeline/data58/Klebsiella_pneumoniae/6478898-DENOVO-20180514-0925.4675464/4922957/kmer_ref_compare_wnode.465851032/inp/kmer_file_list.mft \
#    -ref-kmer-files-manifest \
#    /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/bacterial_pipeline/data58/Klebsiella_pneumoniae/6478898-DENOVO-20180514-0925.4675464/4922957/kmer_ref_compare_wnode.465851032/inp/ref_kmer_file_list.mft
#   "retrieve": cache_kmer -cache-path Path -retrieve -k 18 -new-gc-ids-output File -new-gc-ids-output-manifest ManifestFile
#
set -euxo pipefail
die()
{
    echo "$1" >&2
    exit 1
}
cache_input_dir=
ref_cache_input_dir=
input_manifest=
ref_manifest=
input_manifest_option="kmer-files-manifest"   
ref_manifest_option="ref-kmer-files-manifest"   
export PATH="$PATH:$GP_HOME/arch/x86_64/bin"
executable=$(basename $0 _dir.sh)
declare -a ARGS
ARGS=()
# separate additional parameters from default parameters
while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        -cache-input-dir)
            cache_input_dir="$2"; shift; shift
            ;;
        -ref-cache-input-dir)
            ref_cache_input_dir="$2"; shift; shift
            ;;
        -$input_manifest_option)
            # we are scraping these options because we are using them internally
            shift; shift;
            ;;
        -$ref_manifest_option)
            # we are scraping these options because we are using them internally
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
    input_manifest=kmer-input.mft
    find "$cache_input_dir" -type f > "$input_manifest"
    ARGS[${#ARGS[*]}]="-$input_manifest_option"
    ARGS[${#ARGS[*]}]="$input_manifest"
fi
if [ "$ref_cache_input_dir" != "" ]; then
    ref_manifest=ref-input.mft
    find "$ref_cache_input_dir" -type f > "$ref_manifest"
    ARGS[${#ARGS[*]}]="-$ref_manifest_option"
    ARGS[${#ARGS[*]}]="$ref_manifest"
fi
set +e
$executable "${ARGS[@]}" 
output_exit_code=$?
exit $output_exit_code