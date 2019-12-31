#!/usr/bin/bash
# usage: [src] [dest] [prog] [arguments]

all_args=( "$@" )
src=$1
dest=$2
prog=$3
args="${all_args[@]:3}"
echo cp -r $src $dest
echo $prog $args
