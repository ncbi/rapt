#!/bin/bash
#
#   Prerequisites:
    # In addition to VCS that contains current script:
    #
    # TeamCity script for step Create BLAST caches of configuration GCP Images for Pathogen production
    # buildTypeId:PrkAnnot_Ext_SoftwareCompilation_GcpImagesForPathogenProduction
#
# Input: VERSION file with current software version present in current directory
#
set -euxo pipefail
#
#   The TC build configurator should include VCS gpipe-teamcity for this to work
#
source ./teamcity-utils.sh
function set_variables() 
{
    taxgroup_production_dir="$1";
    taxgroup=$(dirname $taxgroup_production_dir | xargs basename)
    regex='^[0-9]+$'
    if [[ "$taxgroup" =~ $regex ]]; then
        true;
    else
        false;
    fi
    blast_cache_dir="blast_hits_cache-$taxgroup.$VERSION"
    blast_cache_dir_scratch="$blast_cache_dir.scratch"
}

sdir=$(readlink -f .)
#
#   Find current unicoll version 
#
unicoll_version=
read VERSION < VERSION
#
#   VERSION variable is different from unicoll_version variable and it is quite omnipresent in PGAPx.
#
#   We grab it from PGAP Release TeamCity build number 
#   and we use it from thereon to label everything: docker, supplemental data, release versions
#   example of VERSION: 2020-02-06.build4373 
#
#   For fast development cycle and for faster TeamCity builds we are going to try to extract first the unicoll_version
#   from in-house directories:
#
#   1. Most straightforward place: existing installation corresponding to the build
#      
# PGAP_Release_build_number=$(echo "$VERSION" | cut -d. -f2 | grep -Po '\d+')
GP_HOME=/panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/dev/automated_builds/installations/regr_pgap/"$VERSION"
unicoll_symlink="$GP_HOME/third-party/data/BacterialPipeline/uniColl"
if [ -e "$unicoll_symlink" ]; then 
    unicoll_version=$(readlink "$unicoll_symlink" | xargs basename)
fi
#
#   2. Sure, but very slow thing: download it from S3
#
#    ... TODO
#

#
#   Now that we have unicoll_version, proceed to generating caches
#
fastaroot=/panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/ThirdParty/ExternalData/BacterialPipeline/OrfsAndProteins/taxgroup
#
#   Step 1. Submit BLAST jobs via gp_build_starts construct genus files
#
taxgroup=
blast_cache_dir=
blast_cache_dir_scratch=
if false; then
for taxgroup_production_dir in $fastaroot/*/production; do
    set_variables "$taxgroup_production_dir"
    mkdir -p "$blast_cache_dir_scratch"
    pushd "$blast_cache_dir_scratch"
        #
        #   copy here the input for fasta2cache.sh
        #
        cp "$taxgroup_production_dir"/[OP].lenwei.fasta .
        #
        #   generate genus-list files
        #
        /panfs/pan1/gpipe/bacterial_pipeline/system/current/bin/gp_sh bact /panfs/pan1/gpipe/bacterial_pipeline/system/current/bin/gp_sql -server PATHOGEN_DETECT -database PathogenDetectGp -output /dev/stdout -sql-query "
            SELECT DISTINCT
                TP.rank_taxid
            FROM TaxGroupContents TGC
            JOIN GCExtract.dbo.V_TaxidParentRank TP ON TP.taxid = TGC.species_taxid
                AND TGC.taxgroup_id = $taxgroup
                AND TGC.is_outgroup = 0
                AND TP.rank='genus'
        " | grep -v rank_taxid > genus-list
        #
        # submit BLAST jobs via gpipe system on the farm
        #
        "$sdir/fasta2cache.sh" "$unicoll_version" >& fasta2cache.log &
    popd
done
wait
fi

#
#   Step 2. Store BLAST alignments in SQLITE3 database
#
for taxgroup_production_dir in $fastaroot/*/production; do
    set_variables "$taxgroup_production_dir"
    pushd "$blast_cache_dir_scratch"
        "$sdir/create.cache.sh"  >& create.cache.log &
    popd
done
wait
#
#   Step 3. Copy files to final directory
#
for taxgroup_production_dir in $fastaroot/*/production; do
    set_variables "$taxgroup_production_dir"
    mkdir -p "$blast_cache_dir"
    cp "$blast_cache_dir_scratch"/{blast_hits.sqlite,genus-list} "$blast_cache_dir"/ &
done
wait
