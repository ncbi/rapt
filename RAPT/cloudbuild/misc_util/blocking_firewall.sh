#Block firewall openings
#Syntax is for setting firewalls in gcp. ncbi testing purposes only, no need for others to set these.  Priority of denials is lower than priority of allows
#gcp vm execution requires auth login.  
#host:port info https://github.com/ncbi/sra-tools/wiki/Firewall-and-Routing-Information

gcloud compute firewall-rules create block-egress-lo-tcp-www  --action deny  --rules tcp --destination-ranges 130.14.29.110/32 --direction=EGRESS --priority 60000
gcloud compute firewall-rules create block-ingress-lo-tcp-www --action deny  --rules tcp --source-ranges 130.14.29.110/32 --direction=INGRESS --priority 60000

for ip in 130.14.250.{24,25,26,27} 165.112.9.{231,232} 

   do
      echo ${ip}
      IFS=.  
      read ip0 ip1 ip2 ip3 <<< "$ip"  
      
      gcloud compute firewall-rules create allow-egress-lo-udp-${ip3} --action deny  --rules udp --destination-ranges ${ip}/32 --direction=EGRESS --priority ${priority}
      gcloud compute firewall-rules create allow-egress-lo-tcp-${ip3} --action deny  --rules tcp --destination-ranges ${ip}/32 --direction=EGRESS --priority ${priority}
      gcloud compute firewall-rules create allow-ingress-lo-udp-${ip3} --action deny  --rules udp --source-ranges ${ip}/32 --direction=INGRESS --priority ${priority}
      gcloud compute firewall-rules create allow-ingress-lo-tcp-${ip3} --action deny  --rules tcp --source-ranges ${ip}/32 --direction=INGRESS --priority ${priority}

   done
