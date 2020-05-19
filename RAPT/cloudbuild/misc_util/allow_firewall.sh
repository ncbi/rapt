#!/bin/bash
#allow firewall openings
#syntax is for setting firewalls in gcp, other environments will differ in their details but not in which access is necessary
#gcp vm execution requires auth login.  
#host:port info https://github.com/ncbi/sra-tools/wiki/Firewall-and-Routing-Information

priority=50000
while getopts ":p" opt; do
   case $opt in
      p )
        priority=${OPTARG}
        ;;
   esac
done
shift $((OPTIND -1))



gcloud compute firewall-rules create allow-egress-lo-tcp-www  --action allow  --rules tcp:443,tcp:22 --destination-ranges 130.14.29.110/32 --direction=EGRESS --priority ${priority}
gcloud compute firewall-rules create allow-ingress-lo-tcp-www --action allow  --rules tcp:443,tcp:22 --source-ranges 130.14.29.110/32 --direction=INGRESS --priority ${priority}

for ip in 130.14.250.{24,25,26,27} 165.112.9.{231,232} 

   do
      echo ${ip}
      IFS=.  
      read ip0 ip1 ip2 ip3 <<< "$ip"  
      #echo ${ip3}
      #gcloud compute firewall-rules create allow-egress-lo-udp-${ip3} --action allow  --rules udp:33001-33009 --destination-ranges ${ip}/32 --direction=EGRESS --priority ${priority}
      #gcloud compute firewall-rules create allow-egress-lo-tcp-${ip3} --action allow  --rules tcp:443,tcp:22 --destination-ranges ${ip}/32 --direction=EGRESS --priority ${priority}
      gcloud compute firewall-rules create allow-ingress-lo-udp-${ip3} --action allow  --rules udp:33001-33009 --source-ranges ${ip}/32 --direction=INGRESS --priority ${priority}
      gcloud compute firewall-rules create allow-ingress-lo-tcp-${ip3} --action allow  --rules tcp:443,tcp:22 --source-ranges ${ip}/32 --direction=INGRESS --priority ${priority}

   done
