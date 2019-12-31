#!/usr/bin/env perl
#
# Converts buildrun directory to user-specific input to CWL graph
#
# Input: buildrun path
# Output: directory with generated files and input.yaml
#

use strict;
use warnings;
use Getopt::Long;

sub usage
{
    print STDERR<<USAGE;
usage: $0 --brd brd  --input-yaml input.yaml --outdir outdir
USAGE
    exit 1;
}
{
    my $buildrun_dir;
    my $input_yaml;
    my $outdir;
    GetOptions(
        "brd=s", \$buildrun_dir,
        "input-yaml=s", \$input_yaml,
        "outdir=s", \$outdir,
    );
    usage() if !defined $buildrun_dir or !defined $input_yaml;
    my $taxid; ($taxid)=qx(grep -h ^taxid: $buildrun_dir/export*/README.txt | cut -f2 -d:); chomp $taxid;
    my $nucleotide_fa_source ; ($nucleotide_fa_source) = qx(/bin/ls -1d $buildrun_dir/export*/out/*.nucleotide.fa); chomp $nucleotide_fa_source;
    my $sqn; ($sqn)=qx(/bin/ls -1d $buildrun_dir/export*/out/*.sqn); chomp $sqn;
    my $sqn_blob=""; { local $/=undef; open(IN, $sqn); $sqn_blob=<IN>; close(IN); }
    my $sub=&get_balanced("sub", $sqn_blob);  $sub=~s/^\s*sub//;
    my $source=&get_balanced("source", $sqn_blob); 
    my $molinfo =&get_balanced("molinfo", $sqn_blob); 
    my $ass_name; ($ass_name)=qx(head -1 $nucleotide_fa_source | cut -f1 -d' '); chomp $ass_name; $ass_name=~s/^>//; $ass_name=~s/.*\|//g;
    my $nucleotide_fa_target="$outdir/$ass_name.fasta";
    my $template = "$outdir/$ass_name.template";
    qx(cp  $nucleotide_fa_source $nucleotide_fa_target);
    open(OUT, ">$template");
    print OUT<<OUT;
Submit-block ::= $sub   
Seqdesc ::= $source
Seqdesc ::= $molinfo
OUT
    close OUT;
    open(OUT, ">$input_yaml");
    print OUT<<OUT;
submit_block_template:
  class: File
  location: $template
fasta:
  class: File
  location: $nucleotide_fa_target
taxid: $taxid
gc_assm_name: $ass_name    
OUT
    close OUT;
} exit 0;

sub get_balanced
{
    my($prefix, $blob)=@_;
    my $sub=""; ($sub)=$blob=~/($prefix\s*\{.*)/gs; 
    if(!defined $sub or !$sub) {
        die "Could not extract '$prefix' from blob";
    }
    my @sub=split //, $sub; 
    $sub=""; my $count=0; for my $char(@sub) { 
        $sub.=$char;
        if ( $char eq "{" ) {
            $count++;
        }
        if ( $char eq "}" ) {
            $count--;
            last if $count==0;
        }
    }
    return $sub;
}
