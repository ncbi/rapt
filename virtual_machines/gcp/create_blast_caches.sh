#!/bin/bash
#
#   Prerequisites:
    # 
    # scripts mounted using VCS for buildTypeId:PrkAnnot_Ext_SoftwareCompilation_GcpImagesForPathogenProduction:
    #
    # 1/ TeamCity scripts from GCP Images for Pathogen production
    # 2/ TeamCity scripts from teamcity repository
    # 3/ github scripts/
#
# Input: VERSION file with current software version present in current directory
#
set -euxo pipefail
#
#   The TC build configurator should include VCS gpipe-teamcity for this to work
#
source ./teamcity-utils.sh
source ./mywait.sh
function die()
{
    echo "$@" >&2
    exit 1
}

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
#   1. Most straightforward place: check several existing installations corresponding to the build
#      
# PGAP_Release_build_number=$(echo "$VERSION" | cut -d. -f2 | grep -Po '\d+')
set +e
GP_HOME=$(/bin/ls -1d \
    /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/dev/automated_builds/installations/regr_pgap/"$VERSION" \
    /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/bacterial_pipeline/system_gb/"$VERSION" \
    /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/bacterial_pipeline/system/"$VERSION" )
set -e    
#
#   by the time of execution of this this directory might not even exist
#

unicoll_symlink="$GP_HOME/third-party/data/BacterialPipeline/uniColl"
if [ -e "$unicoll_symlink" ]; then 
    unicoll_version=$(readlink "$unicoll_symlink" | xargs basename)
# else
#    die "can't find unicoll_version based on current GP_HOME=$GP_HOME because most likely $GP_HOME was old and purged"
#  Please don't die! We have an option two!!!
#
fi
if [ -z "$unicoll_version" ]; then 
    #
    #   2. Extract this information from GPIPE_REGR_PGAP server which is much better at retaining this information.
    #       a) get the sample buildrun_id
    server=GPIPE_REGR_PGAP
    #
    #   for some enigmatic reason we can't just take any buildrun from the same batch, so lets do a brute force and do it for all taskruns, hopefully one of them sticks in applog database
    #
    sqsh-ms -S $server -D GPIPE_INIT -U anyone -P allowed -m bcp -L bcp_colsep=$'\t' -L bcp_rowsep= -C "
        SELECT DISTINCT TR.taskrun_id 
        FROM V_TaskRun TR 
        JOIN BuildRun BR ON BR.buildrun_id = TR.buildrun_id
        JOIN SwRelease SW ON BR.release_id = SW.release_id 
            AND SW.release_name = '$VERSION'
            AND TR.task_name = 'Create identification BLASTdb' " > taskruns
    #
    # this PERL monstrosity inliner is from ~badrazat/bin/sql_list
    #
    taskruns=$(cat taskruns | perl -pe 'if (/\S/) { if(/[^\d\n]/) {s/^/'"'"'/; s/$/'"'"'/; } s/\n/\, /;} else {$_=""} '  | perl -pe 's/,[\s\n]*$/\n/g')
    #       b) use applog query with given taskrun and server to extract the variable
    #   I hope it can take a list of 47 taskruns
    unicoll_version=$(basename $(time applog_client -N applogdb \
        -q "date BETWEEN 2020-01-01T00:00 AND 2020-12-31T23:59 AND app=gp_build_start and taskrun_id in ($taskruns)  AND server=$server" -group final_path | 
        grep -Pohi '/panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/ThirdParty/ExternalData/BacterialPipeline/uniColl/[^/]+') |  
        head -1 | tr 't' 'T')
fi        
#
#   3. Sure, but very slow thing: download it from S3
#
if [ -z "$unicoll_version" ]; then
    # unfortunately the supplementary data uniColl_path does not match exactly uniColl third party. 
    # this option is really a long shot
    die "aws s3 variant of getting the input data is not working for now and this is the last option"
    time aws s3 cp -r pgap/input-$VERSION.prod.tgz .
    time tar xzf input-$VERSION.prod.tgz 
fi


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
pids=$(pwd)/pids.$$
rm -f $pids
if true; then
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
        echo $! >> $pids
    popd
done
time mywait $pids
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
