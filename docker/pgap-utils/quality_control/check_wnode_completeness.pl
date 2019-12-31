#!/usr/bin/env perl
#
#   Presumptions:
#       - cwd is the directory with temporary files directory (outdir, etc)
#       - temporary file directory has only one level
#       - cwltool is run with  --timestamps parameter
#

use strict;
use warnings;
use List::Util qw(max);

{
    my($logf) = shift @ARGV;
    my($file_tag)=shift @ARGV;
    open(INLOG, $logf);
    my $jobf="";
    my $node=""; # CWL graph node
    my $app="";
    my $jobids={};
    my $header_printed = 0;
    while(!eof(INLOG)){
        $_=<INLOG>; 
        my @f;
        #
        #   New block
        #
        if(@f=m{^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[(job|step|workflow) ([^\]]*)\]}g) {
            my $new_node = join " ", @f;
            if($jobf ne "") {
                my $njobs; ($njobs)=qx(cat $jobf|wc -l); chomp $njobs;
                if($njobs != scalar(keys %$jobids)) {
                    if(!$header_printed) { $header_printed = 1;
                        print join "\t", qw(severity file node app diag_code N1 N2); print "\n";
                    }
                    print join "\t", "WARNING", $file_tag, $node, $app, "njobs_mismatch", $njobs, scalar(keys %$jobids); print "\n";
                }
                if(max(keys %$jobids) != $njobs) {
                    if(!$header_printed) { $header_printed = 1;
                        print join "\t", qw(severity file node app diag_code N1 N2); print "\n";
                    }
                    print join "\t", "FATAL", $file_tag, $node, $app, "max_mismatch", $njobs, max(keys %$jobids); print "\n";
                }
            }
            $jobf="";
            $app="";
            $jobids={};
            $node=$new_node;
            next;
        }
        if(@f=m{^\s+\-\-volume\=[^:]+/([^/]+/[^/]+/job[\w\-\.]*\.xml)}g) { 
            $jobf = $f[0];
            next;
        }
        if(m{^\s+\w+/\w+:\S+\s+\\\s*$}g) { #     ncbi/gpdev:latest or ncbi/pgap:2018-08-20.build2980
            $_=<INLOG>; 
            ($app)=m{(\w+)}g;
            next;
        }
        if(@f=m{^\d+/\d+/\d+/[A-Z]+\s.*\bjob_id=(\d+)}g) {
            $$jobids{$f[0]}++;
            next;
        }
    }
    close(INLOG);
} exit 0;

