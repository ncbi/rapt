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



gcloud compute firewall-rules create allow-egress-lo-tcp-www  --action allow  --rules tcp:443,22 --destination-ranges 130.14.29.110/32 --direction=EGRESS --priority ${priority}
gcloud compute firewall-rules create allow-ingress-lo-tcp-www --action allow  --rules tcp:443,22 --source-ranges 130.14.29.110/32 --direction=INGRESS --priority ${priority}

gcloud compute firewall-rules create allow-egress-lo-udp-24 --action allow  --rules udp:33001-33009 --destination-ranges 130.14.250.24/32 --direction=EGRESS --priority ${priority}
gcloud compute firewall-rules create allow-egress-lo-tcp-24 --action allow  --rules tcp:443,22 --destination-ranges 130.14.250.24/32 --direction=EGRESS --priority ${priority}
gcloud compute firewall-rules create allow-ingress-lo-udp-24 --action allow  --rules udp:33001-33009 --source-ranges 130.14.250.24/32 --direction=INGRESS --priority ${priority}
gcloud compute firewall-rules create allow-ingress-lo-tcp-24 --action allow  --rules tcp:443,22 --source-ranges 130.14.250.24/32 --direction=INGRESS --priority ${priority}

gcloud compute firewall-rules create allow-egress-lo-udp-25 --action allow  --rules udp:33001-33009 --destination-ranges 130.14.250.25/32 --direction=EGRESS --priority ${priority}
gcloud compute firewall-rules create allow-egress-lo-tcp-25 --action allow  --rules tcp:443,22 --destination-ranges 130.14.250.25/32 --direction=EGRESS --priority ${priority}
gcloud compute firewall-rules create allow-ingress-lo-udp-25 --action allow  --rules udp:33001-33009 --source-ranges 130.14.250.25/32 --direction=INGRESS --priority ${priority}
gcloud compute firewall-rules create allow-ingress-lo-tcp-25 --action allow  --rules tcp:443,22 --source-ranges 130.14.250.25/32 --direction=INGRESS --priority ${priority}

gcloud compute firewall-rules create allow-egress-lo-udp-26 --action allow  --rules udp:33001-33009 --destination-ranges 130.14.250.26/32 --direction=EGRESS --priority ${priority}
gcloud compute firewall-rules create allow-egress-lo-tcp-26 --action allow  --rules tcp:443,22 --destination-ranges 130.14.250.26/32 --direction=EGRESS --priority ${priority}
gcloud compute firewall-rules create allow-ingress-lo-udp-26 --action allow  --rules udp:33001-33009 --source-ranges 130.14.250.26/32 --direction=INGRESS --priority ${priority}
gcloud compute firewall-rules create allow-ingress-lo-tcp-26 --action allow  --rules tcp:443,22 --source-ranges 130.14.250.26/32 --direction=INGRESS --priority ${priority}

gcloud compute firewall-rules create allow-egress-lo-udp-27 --action allow  --rules udp:33001-33009 --destination-ranges 130.14.250.27/32 --direction=EGRESS --priority ${priority}
gcloud compute firewall-rules create allow-egress-lo-tcp-27 --action allow  --rules tcp:443,22 --destination-ranges 130.14.250.27/32 --direction=EGRESS --priority ${priority}
gcloud compute firewall-rules create allow-ingress-lo-udp-27 --action allow  --rules udp:33001-33009 --source-ranges 130.14.250.27/32 --direction=INGRESS --priority ${priority}
gcloud compute firewall-rules create allow-ingress-lo-tcp-27 --action allow  --rules tcp:443,22 --source-ranges 130.14.250.27/32 --direction=INGRESS --priority ${priority}

gcloud compute firewall-rules create allow-egress-lo-udp-231 --action allow  --rules udp:33001-33009 --destination-ranges 165.112.9.231/32 --direction=EGRESS --priority ${priority}
gcloud compute firewall-rules create allow-egress-lo-tcp-231 --action allow  --rules tcp:443,22 --destination-ranges 165.112.9.231/32 --direction=EGRESS --priority ${priority}
gcloud compute firewall-rules create allow-ingress-lo-udp-231 --action allow  --rules udp:33001-33009 --source-ranges 165.112.9.231/32 --direction=INGRESS --priority ${priority}
gcloud compute firewall-rules create allow-ingress-lo-tcp-231 --action allow  --rules tcp:443,22 --source-ranges 165.112.9.231/32 --direction=INGRESS --priority ${priority}

gcloud compute firewall-rules create allow-egress-lo-udp-232 --action allow  --rules udp:33001-33009 --destination-ranges 165.112.9.232/32 --direction=EGRESS --priority ${priority}
gcloud compute firewall-rules create allow-egress-lo-tcp-232 --action allow  --rules tcp:443,22 --destination-ranges 165.112.9.232/32 --direction=EGRESS --priority ${priority}
gcloud compute firewall-rules create allow-ingress-lo-udp-232 --action allow  --rules udp:33001-33009 --source-ranges 165.112.9.232/32 --direction=INGRESS --priority ${priority}
gcloud compute firewall-rules create allow-ingress-lo-tcp-232 --action allow  --rules tcp:443,22 --source-ranges 165.112.9.232/32 --direction=INGRESS --priority ${priority}
