#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;

{
    my $mapperf;
    GetOptions(
        "mapper=s", \$mapperf,
    );
    open(IN, $mapperf);
    my $mapper={};
    while(!eof IN) {
        $_=<IN>; chomp;
        my @f=split/\t/;
        $$mapper{$f[0]}=$f[1];
    }
    close IN;
    for (<>) {
        chomp; my @f=split(/\t/);
        grep { $_=$$mapper{$_} if defined $$mapper{$_} } @f;
        print join "\t", @f; print "\n";
    }
} exit 0;
