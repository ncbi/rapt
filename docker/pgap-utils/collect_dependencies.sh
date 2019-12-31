#!/bin/bash

initial_dir=`pwd`
script_name=`basename $0`
script_dir=`dirname $0`
script_dir=`(cd "${script_dir}"; pwd)`
cd ${initial_dir}


Usage()
{
    cat <<EOF 1>&2
USAGE: cat file_list | $script_name source_root dest_root
SYNOPSIS:
 copy files and shared libraries from source_root into dest_root
ARGUMENTS:
  source_root -- existing directory
  dest_root   -- destination directory
  file_list   -- list of files with paths relative to source_root
EOF
    test -z "$1"  ||  echo ERROR: $1 1>&2
    exit 1
}

if test $# -eq 0; then
  Usage "No arguments provided"
fi
if test ! -d $1; then
  Usage "Not a directory: $1"
fi
if test $# -lt 2; then
  Usage "Destination not specified"
fi

src_root=`(cd "$1"; pwd)`
cd ${initial_dir}
dest_root=${initial_dir}/$2

#from (file) to (file)
copyfile()
{
  dest=`dirname $2`
  if test ! -d ${dest}; then
    mkdir -p  ${dest}
  fi
  if test $1 -nt $2; then
    cp -a $1 $2
  fi
}

#from (dir) to (dir)
copydir()
{
  dest=`dirname $2`
  if test ! -d ${dest}; then
    mkdir -p  ${dest}
  fi
  cp -ar $1 ${dest}
}

while read line; do    
  echo ${line}
  if test  -d ${src_root}/${line}; then
    copydir ${src_root}/${line} ${dest_root}/${line}
    continue
  fi
  if test -h ${src_root}/${line}; then
    cp -av ${src_root}/${line} ${dest_root}/${line}
    continue
  fi
  if test ! -e ${src_root}/${line}; then
    echo "File not found: ${src_root}/${line}"
    continue
  fi
  copyfile ${src_root}/${line} ${dest_root}/${line}
  srctype=`file ${src_root}/${line} | awk 'BEGIN{FS=","};{print $1}' | grep "ELF" | grep "executable"`
  if test -n "${srctype}"; then
    dependencies=`ldd ${src_root}/${line} | awk 'BEGIN{ORS=" "}$1~/^\//{print $1}$3~/^\//{print $3}'`
    for dep in ${dependencies}; do
      loc=`echo ${dep} | grep "${src_root}"`
      if test -n "${loc}"; then
        dep=`echo ${dep} | sed "s:/${src_root}/::"`
        copyfile ${src_root}/${dep} ${dest_root}/${dep}
      fi 
    done
  fi
done
