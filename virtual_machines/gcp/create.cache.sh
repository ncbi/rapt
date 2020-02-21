#!/bin/bash
#
# script converts BLAST results asn files as they come from cluster_blastp_wnode to BLAST cache file
#
#   Input: files [OP].{blast.asn,seqids,LDS} present in current directory
#   Output: blast_hits.sqlite database in current directory
#

set -euxo pipefail

#
#   gpipe installation where blast searches will be performed
#
#   unfortunately, we do not have other option
#
GP_ep=badrazat
GP_HOME=/panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/home/badrazat/local-install/current


"$GP_HOME"/bin/gp_sh "$GP_ep" "$GP_HOME"/bin/orf_hits_cache_store -orfs P.seqids -hits P.blast.asn -blast-type predicted-protein -blast-hits-sqlite-cache blast_hits.sqlite -lds2 P.LDS > P.orf_hits_cache_store.1.log &
~/regr_bct_sys/current/arch/x86_64/bin/orf_hits_cache_store -orfs O.seqids -hits O.blast.asn -blast-type orf -blast-hits-sqlite-cache blast_hits.sqlite -lds2 O.LDS >O.orf_hits_cache_store.1.log &

wait

