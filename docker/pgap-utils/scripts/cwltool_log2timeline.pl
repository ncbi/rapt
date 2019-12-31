#!/usr/bin/env perl
#
#  This script takes output of cwltool --timestamps to produce timeline TSV output to examine time spent on each stage
#

use strict;
use warnings;
use Time::ParseDate;

{
    my $logfile = shift @ARGV;
    my $stack = [];
    open(IN, $logfile);
    my $header_printed = 0;
    while(!eof IN) {
        $_=<IN>; chomp;
        my $k={}; 
        ($$k{curtime}, $$k{step}, $$k{message}) = m{\[([^\]]+)\] \[([^\]]+)\] (.*)}g;
        next if !defined $$k{message};
        if ($$k{message} !~ /^completed/) { # new step
            $$k{start}=$$k{curtime};
            push @$stack, $k;
        }
        else {
            my $kl = $$stack[scalar(@$stack)-1];
            if ($$kl{step} ne $$k{step} ) {
                warn "'$$kl{step}' ne '$$k{step}': $_";
                next;
            }
            $$kl{stop} = $$kl{curtime} = $$k{curtime};
            $$kl{message} = $$k{message};
            if(!$header_printed) {  
                $header_printed = 1;
                print join "\t",  qw (step epoch_start seconds start stop message); print "\n";
            }
            $$kl{seconds}=parsedate($$kl{stop}) -parsedate($$kl{start});
            $$kl{epoch_start}=parsedate($$kl{start});
            print join "\t", map { $$kl{$_} } qw (step epoch_start seconds start stop message); print "\n";
            pop @$stack;
        }
    }
    close IN;
} exit 0;

