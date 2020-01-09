#!/bin/bash
set -euxo pipefail

#TC Parameters
# %system.teamcity.buildType.id%
# %AWS_INSTANCE_TYPE%

remote_user=gp_aws

echo "##teamcity[blockOpened name='StartRemote' description='Start Remote Instance']"
prefix=`echo %system.teamcity.buildType.id% | tr '_' '-'`
name=${prefix}-%build.number%
# e.g. ami-09e11fa9958af7993
imageid=`cat ami-id.txt`

curdate=`date -u --rfc-3339=seconds | tr ' ' T | cut -f1 -d+`Z
tags="ResourceType=instance,Tags=[\
{Key=Name,Value=$name},\
{Key=Created,Value=$curdate},\
{Key=Owner,Value=slottad},\
{Key=Project,Value=Gpipe},\
{Key=billingcode,Value=pgapx}]"

aws ec2 run-instances \
    --image-id $imageid \
    --count 1 \
    --instance-type %AWS_INSTANCE_TYPE% \
    --key-name gpipe-aws \
    --security-group-ids sg-3014d956 sg-029f1b75 \
    --subnet-id subnet-a43744d3 \
    --block-device-mapping "DeviceName=/dev/xvda,Ebs={VolumeSize=300}" \
echo "##teamcity[blockClosed name='StartRemote']"

echo "##teamcity[blockOpened name='WaitInstance' description='Wait for instance to be usable.']"
aws ec2 wait instance-status-ok --instance-ids %remote_instance%
ip=`aws --output text ec2 describe-instances --instance-ids %remote_instance% --query Reservations[].Instances[].PublicIpAddress`
echo "Remote Host IP Address = ${ip}"
echo "Setting local TeamCity remote_host parameter."
remote_host= ${ip}
echo "##teamcity[blockClosed name='WaitInstance']"


echo "##teamcity[blockOpened name='UploadScripts' description='Upload Scripts']"
scp -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no pgap.py ${remote_user}@${remote_host}:
scp -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no run-pipeline.sh ${remote_user}@${remote_host}:
VERSION=$(cat VERSION)
cat <<EOF
EOF
##teamcity[setParameter name='pgap_version' value='${VERSION}']
EOF
EOF
echo "##teamcity[blockClosed name='UploadScripts']"


echo "##teamcity[blockOpened name='FetchFiles' description='Fetch required files']"
ssh ${remote_user}@${remote_host} ./pgap.py --%teamcity.build.branch% --teamcity --use-version %pgap_version%
echo "##teamcity[blockClosed name='FetchFiles']"


echo "##teamcity[blockOpened name='RunANI' description='Run ANI']"
./run-pipeline.sh \
    tax-check \
    %teamcity.build.branch% \
    %pgap_version% \
    %genome_dir% \
    %input_yaml%
echo "##teamcity[blockClosed name='RunANI']"


echo "##teamcity[blockOpened name='RunPipeline' description='Run Pipeline']"
vmstat -t -a -n -SM 1 > vmstat.log &
vmstatid1=$!
vmstat -t -a -n -SM 120 &
vmstatid120=$!
#
#   make sure that we wrap up background vms stuff when we exit
#
trap "echo EXITING ; kill $vmstatid1 ; kill $vmstatid120" EXIT
branch_flag=%teamcity.build.branch%
add_flags=""
if [ $branch_flag = "PGAPX-453" ]; then
    branch_flag=dev
    add_flags="$add_flags --no-internet"
fi
./pgap.py --$branch_flag \
          --debug \
          --quiet \
          --use-version %pgap_version% \
          --report-usage-false \
          --ignore-all-errors \
          $add_flags \
          ./%teamcity.build.branch%/test_genomes-%pgap_version%/%genome_dir%/%input_yaml%
kill $vmstatid1
kill $vmstatid120
#
#   reset abnormal exit cleanup because we are done with vms at this point
#
trap '' EXIT
vmstat -t -a -n -SM
echo "##teamcity[blockClosed name='RunPipeline']"


echo "##teamcity[blockOpened name='CompressOutput' description='Compress Output']"
gzip vmstat.log

mkdir debug-extra
mv output/debug/tmp* debug-extra
tar cvzf output.tgz output
XZ_OPT="-9 --threads=0" tar cvJf debug-extra.txz debug-extra
echo "##teamcity[blockClosed name='CompressOutput']"

echo "##teamcity[blockOpened name='RetrieveOutput' description='Retrieve output']"
#scp -q -i %gpipe_aws_key% \
#    %remote_user%@%remote_host%:output.tgz .
#scp -q -i %gpipe_aws_key% \
#    %remote_user%@%remote_host%:vmstat.log.gz .
scp -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
    %remote_user%@%remote_host%:%teamcity.build.branch%/test_genomes-%pgap_version%/%genome_dir%/%input_yaml% .
scp -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
    %remote_user%@%remote_host%:output.tgz .
scp -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
    %remote_user%@%remote_host%:debug-extra.txz .
scp -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        %remote_user%@%remote_host%:vmstat.log.gz .
echo "##teamcity[blockClosed name='RetrieveOutput']"


echo "##teamcity[blockOpened name='StopInstance' description='Stop remote instance']"
aws ec2 stop-instances --instance-ids %remote_instance%
echo "##teamcity[blockClosed name='StopInstance']"


echo "##teamcity[blockOpened name='' description='']"
aws ec2 terminate-instances --instance-ids %remote_instance%
echo "##teamcity[blockClosed name='']"
