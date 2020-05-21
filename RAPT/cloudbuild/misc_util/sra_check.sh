#!/bin/bash -x  
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

ncbi_base='www.ncbi.nlm.nih.gov'
cloud_suf='/sdlr'
test_port='443'
# https 443 test_port='443'
cloud_substr=${ncbi_base}${cloud_suf}
#in addition to documented ncbi download host also possible is https://sra-downloadb.be-md.ncbi.nlm.nih.gov (and maybe colo eq)
noncloud_substr='sra-download'

# test port access.  If port is closed  using /dev/tcp hangs, so wrap attempt in timeout
timeout 1s bash -c "echo EOF > /dev/tcp/${ncbi_base}/${test_port}" 2> /dev/null || \
(echo "port closed" > /dev/stderr; exit 2)
rc=$?

if [ 0 != ${rc} ] ; then
   echo 'problem with tcp access to ncbi.gov sdl host'
   exit 1
fi


run_path=$(srapath ${sra_run_acc})
rc=$?
if [ 0 != ${rc} ] ; then
   echo 'problem retrieving sra path'
   exit 1
fi

if grep -q "${cloud_substr}" <<< "${run_path}"; then 
   echo "cloud retrieval"

   # download host ip address from https://github.com/ncbi/sra-tools/wiki/Firewall-and-Routing-Information
   timeout 1s bash -c "echo EOF > /dev/tcp/130.14.250.24/22" 2> /dev/null || \
   (echo "port closed" > /dev/stderr; exit 2)
   rc=$?
   if [ 0 != ${rc} ] ; then
      echo 'problem with tcp access to ncbi.gov download host'
      exit 1
   fi

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
