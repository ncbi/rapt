#!/bin/bash  
#check whether sra retrieval uses cloud or ncbi storage, verifies retrieval function.
#returns 0 if cloud retrieval works, 1 otherwise

sra_run_acc='SRR4835107'
while getopts ":a:v" opt; do
   case $opt in 
      a )
        sra_run_acc=${OPTARG}
        ;;
      v )
        verbose=1
   esac
done
shift $((OPTIND -1))

cloud_substr='ncbi.nlm.nih.gov/sdlr'
noncloud_substr='sra-download-internal'
run_path=$(srapath ${sra_run_acc})
rc=$?

if [ 0 != ${rc} ] ; then
   echo 'problem retrieving sra path'
   exit 1
fi

if grep -q "${cloud_substr}" <<< "${run_path}"; then 
   echo "cloud retrieval"

   run_fasta=$(fastq-dump -X 5 --stdout --fasta 0 ${sra_run_acc})
   rc=$?
   # weird warning on docker on vm: 
   # 2020-04-30T04:11:15 fastq-dump.2.10.5 sys: unknown while writing file within network system module - mbedtls_ssl_write returned -78 ( NET - Sending information through the socket failed )
   # retrieval works though (data is present), and rc is 0

   if [ 0 != ${rc} ] ; then
      echo 'problem retrieving fasta'
      exit 1
   fi

   if grep -q "${sra_run_acc}" <<< "${run_fasta}"; then 
      echo "sequence retrieval ok"
      exit 0
   else 
      echo "unexpected retrieval"
      echo ${run_fasta}
   fi
 
elif grep -q "${noncloud_substr}" <<< "${run_path}"; then 
   echo "noncloud retrieval"
else 
   echo "unexpected path, can't tell"
   echo ${run_path}
fi

exit 1
