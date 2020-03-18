#!/bin/bash
#
# input: two fasta files: [OP].lenwei.fasta present in current directory
# output: [OP].{blast.asn,seqids,LDS} present in current directory
#

set -euxo pipefail
sdir=$(dirname $(readlink -f "$0"))
unicoll_version="$1" ;shift # example: "2019-09-28T10:21:57"
blastdb_mft=blastdb.mft
#
#   gpipe installation where blast searches will be performed
#
#   unfortunately, we do not have other option
#
GP_ep=badrazat
GP_HOME=/panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/home/badrazat/local-install/current
GP_SQL_SRVR=$("$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/gp_get_attr GP_SQL_SRVR)
source "$sdir/mywait.sh"
pids=$(pwd)/pids.$$
rm -f $pids

if true; then
    for type in O P; do
    rm -f "$type".LDS
    ~/gpipe-arch-bin/protein_extract \
        -input "$type".lenwei.fasta \
        -ifmt fasta \
        -olds2 "$type".LDS \
        -o "$type.protein.asn" \
        -nogenbank \
        -oseqids "$type".seqids >& "$type".protein_extract.log &
        echo $! >> $pids
    done
    mywait $pids
    # for type in O P; do
        # sqlite3 "$type".LDS "update file set file_name= '$type.protein.asn'"
    # done
    rm -f -- "$blastdb_mft"
    echo /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/ThirdParty/ExternalData/BacterialPipeline/uniColl/"$unicoll_version"/current/NamingDatabase >> "$blastdb_mft"
    echo /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/ThirdParty/ExternalData/BacterialPipeline/uniColl/"$unicoll_version"/current/BlastRules >> "$blastdb_mft"

fi

for type in O P; do
    readlink -f "$type".LDS > "$type".LDS.mft
    readlink -f "$type".seqids > $type.seqids.mft
    
    rm -f -- "$type".task-test.input 
    readlink -f "$blastdb_mft" >> "$type".task-test.input 
    readlink -f $type.seqids.mft >> "$type".task-test.input 
    readlink -f "$type".LDS.mft >> "$type".task-test.input 
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/test_task -t blastp_wnode_naming -taxid 28901 < "$type".task-test.input >& "$type".test_task.log
    tr=$(grep -Poh 'taskrun \d+' "$type".test_task.log | head -1 | grep -Poh '\d+')
    br=$(grep -Poh 'gp_build_start \d+' "$type".test_task.log | head -1 | grep -Poh '\d+')
    #
    #   cluster_blastp_wnode
    #
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param align_filter \
        -value 'score>0 && pct_identity_gapopen_only > 35'
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param asn_cache \
        -value /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/ThirdParty/ExternalData/BacterialPipeline/uniColl/"$unicoll_version"/current/cache
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param backlog \
        -value 1
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param comp_based_stats \
        -value F  
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param dbsize \
        -value 6000000000        
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param delay \
        -value 0                
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param evalue \
        -value 0.1             
    if [ "$type" = "O" ]; then
        "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param extra_coverage 	 \
            -value 20          
    fi
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param max_jobs \
        -value 1             
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param max_target_seqs \
        -value 50             
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param ofmt \
        -value asn-binary             
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param seg \
        -value no             
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param service \
        -value '${GP_qservice}'             
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param threshold \
        -value 21             
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param top_by_score \
        -value 10             
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param word_size \
        -value 6             
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param workers \
        -value 20             
    if [ "$type" = "O" ]; then
        "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param no_merge \
            -tag T      
    fi
    if [ "$type" = "P" ]; then
        "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param allow_intersection \
            -tag T             
        "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param compart \
            -tag T             
    fi
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog cluster_blastp_wnode -param nogenbank \
        -tag T             
    #
    #  gp_register_stats
    #
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog gp_register_stats -param ifmt \
        -value seq-align-set             
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog gp_register_stats -param input_manifest \
        -value '${GP_omanifest}'  
    #
    #   gpx_qdump
    #
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog gpx_qdump -param output \
        -value '${GP_qdump_output}'             
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog gpx_qdump -param output_manifest \
        -value '${GP_qdump_omanifest}'             
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog gpx_qdump -param unzip \
        -value '*'  
    #
    #   gpx_qsubmit
    #
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog gpx_qsubmit -param affinity \
        -value subject             
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog gpx_qsubmit -param asn_cache 	 \
        -value '${GP_cache_dir}'             
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog gpx_qsubmit -param max_batch_length 	 \
        -value 10000             
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog gpx_qsubmit -param nogenbank \
        -tag T             
    #
    #   fault_tolerance_policy
    #
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog fault_tolerance_policy -param execution_policy \
        -value limited-retry-long  
    #
    #   resource_requirements
    #
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog resource_requirements -param core_count \
        -value 4             
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/taskrun_upd_param -taskrun "$tr" -prog resource_requirements -param memory_per_core \
        -value 6   
    #
    #   GOOOOOOOOOOOOOOOOOOOOOOOOOOOO!
    #
    "$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/gp_build_start "$br" >& gp_build_start."$type"."$br".log &
    echo $! >> $pids
    echo "$br" > "$type.br"
done
time mywait $pids
#
#   create symlinks for BLAST output
#
for type in O P; do
    read br < "$type.br"
    target="$type.blast.asn"
    
    ln -s $("$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/gp_sql -server "$GP_SQL_SRVR" -database GPIPE_INIT -output /dev/stdout -sql-query "select taskrun_path+'/out/blast.asn' as blast_path from V_TaskRun where buildrun_id = $br and taskrun_status='SUCCESS'" | tail -1) "$target"
    test -r "$target"
done

