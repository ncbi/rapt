#!/bin/bash
#
# Script compares classic PGAP output to external PGAP output
# takes two parameters
asn_classic=$1; shift
asn_external=$1; shift
output_prefix=$1; shift
if [ "$output_prefix" = "" ]; then
    echo usage: asn_classic asn_external output_prefix >&2
    exit 1;
fi
set -euxo pipefail
sdir=$(dirname $(readlink -f $0))
# production setting
# tmpdir=$(mktemp -d --tmpdir "tmp.${0##*/}.XXXXXXXXXXXXX")  
# trap '/bin/rm -rf -- "$tmpdir"' 0
# debug setting
tmpdir=.
fasta_classic=$tmpdir/classic.fasta
fasta_external=$tmpdir/external.fasta
asn2fasta -i $asn_external  -nucs-only -o  $fasta_external
asn2fasta -i $asn_classic  -nucs-only -enable-gi -o  $fasta_classic  
perl -i -pe 's{(>gi\|\d+)\S+}{$1}g' $fasta_classic

align1=$tmpdir/aws-tc.asn
align2=$tmpdir/tc-aws.asn
mft=$tmpdir/align.mft
rm -f $mft
readlink -f $align2 >> $mft
readlink -f $align1 >> $mft
mapper=$tmpdir/nucleotide-mapper
blastn -query $fasta_external -subject $fasta_classic -parse_deflines -outfmt 8  > $align1;
blastn -query $fasta_classic -subject $fasta_external -parse_deflines -outfmt 8  > $align2;

~/gpipe-arch-bin/align_sort -k query,-score -top 1 -group 1 -it -ifmt seq-annot  -i $align1 2> /dev/null |
~/gpipe-arch-bin/align_format -ifmt seq-align -tabular-fmt 'qexactseqid sexactseqid' 2> /dev/null  |
grep -v '#' > $mapper


~badrazat/gpipe-arch-bin/compare_annots \
    -q_scope_type annots \
    -s_scope_type annots \
    -q_scope_args $asn_classic \
    -s_scope_args $asn_external \
    -alns_filter   'reciprocity = 3' \
    -alns $mft \
    -o_asn $output_prefix.seq-annots.asn \
    -o_stat $output_prefix.counts.classes.by.feature-type.txt \
    -o_stat_xml $output_prefix.counts.classes.by.feature-type.xml \
    -o_tab $output_prefix.report.tsv \
     -compare_all_subtypes \
     -nogenbank
    # -diff-only 
    # -ignore_strand 
table_classic=$tmpdir/classic.tsv     
table_external=$tmpdir/external.tsv   
  
~/gpipe-arch-bin/asn2table -ifmt seq-entry -i $asn_classic -it 2> /dev/null |
 cfilter ' type ne "prot" and Pseudo eq "false" ' |
 ccut nucleotide,range_from,range_to,strand,type,title - |
 $sdir/table_mapper.pl --mapper $mapper |
 csort nucleotide range_from range_to strand type - \
 > $table_classic

 ~/gpipe-arch-bin/asn2table -ifmt seq-entry -i $asn_external -it 2> /dev/null |
 cfilter ' type ne "prot" and Pseudo eq "false" ' |
 ccut nucleotide,range_from,range_to,strand,type,title - |
 $sdir/table_mapper.pl --mapper $mapper |
 csort nucleotide range_from range_to strand type - \
 > $table_external

 diff -u $table_classic $table_external > $output_prefix.asn2table.diff