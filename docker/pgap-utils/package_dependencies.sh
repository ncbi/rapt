#!/bin/bash

# Quick and dirty utility to gather in tar file a list of executables
# given via command line arguments and a non-redundant set of their
# shared library dependencies. It will search the default $PATH for
# each executable.
all_args=( "$@" )
bindir=$1
args="${all_args[@]:1}"
export PATH=$bindir:$PATH

files=$(for arg in $args; do
            ex=`which ${arg}`
            #echo $ex
            ldd $ex | awk '$1~/^\//{print $1}$3~/^\//{print $3}' | grep -v $bindir
        done | sort -u | tr '\n' ' ')
tar cvhpPf binaries/libraries.tar $files
