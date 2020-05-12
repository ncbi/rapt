#Block firewall openings
#Syntax is for setting firewalls in gcp. ncbi testing purposes only, no need for others to set these.  Priority of denials is lower than priority of allows
#gcp vm execution requires auth login.  
#host:port info https://github.com/ncbi/sra-tools/wiki/Firewall-and-Routing-Information

gcloud compute firewall-rules create block-egress-lo-tcp-www  --action allow  --rules tcp --destination-ranges 130.14.29.110/32 --direction=EGRESS --priority 60000
gcloud compute firewall-rules create block-ingress-lo-tcp-www --action allow  --rules tcp --source-ranges 130.14.29.110/32 --direction=INGRESS --priority 60000

gcloud compute firewall-rules create block-egress-lo-udp-24 --action deny  --rules udp --destination-ranges 130.14.250.24/32 --direction=EGRESS --priority 60000
gcloud compute firewall-rules create block-egress-lo-tcp-24 --action deny  --rules tcp --destination-ranges 130.14.250.24/32 --direction=EGRESS --priority 60000
gcloud compute firewall-rules create block-ingress-lo-udp-24 --action deny  --rules udp --source-ranges 130.14.250.24/32 --direction=INGRESS --priority 60000
gcloud compute firewall-rules create block-ingress-lo-tcp-24 --action deny  --rules tcp --source-ranges 130.14.250.24/32 --direction=INGRESS --priority 60000

gcloud compute firewall-rules create block-egress-lo-udp-25 --action deny  --rules udp --destination-ranges 130.14.250.25/32 --direction=EGRESS --priority 60000
gcloud compute firewall-rules create block-egress-lo-tcp-25 --action deny  --rules tcp --destination-ranges 130.14.250.25/32 --direction=EGRESS --priority 60000
gcloud compute firewall-rules create block-ingress-lo-udp-25 --action deny  --rules udp --source-ranges 130.14.250.25/32 --direction=INGRESS --priority 60000
gcloud compute firewall-rules create block-ingress-lo-tcp-25 --action deny  --rules tcp --source-ranges 130.14.250.25/32 --direction=INGRESS --priority 60000

gcloud compute firewall-rules create block-egress-lo-udp-26 --action deny  --rules udp --destination-ranges 130.14.250.26/32 --direction=EGRESS --priority 60000
gcloud compute firewall-rules create block-egress-lo-tcp-26 --action deny  --rules tcp --destination-ranges 130.14.250.26/32 --direction=EGRESS --priority 60000
gcloud compute firewall-rules create block-ingress-lo-udp-26 --action deny  --rules udp --source-ranges 130.14.250.26/32 --direction=INGRESS --priority 60000
gcloud compute firewall-rules create block-ingress-lo-tcp-26 --action deny  --rules tcp --source-ranges 130.14.250.26/32 --direction=INGRESS --priority 60000

gcloud compute firewall-rules create block-egress-lo-udp-27 --action deny  --rules udp --destination-ranges 130.14.250.27/32 --direction=EGRESS --priority 60000
gcloud compute firewall-rules create block-egress-lo-tcp-27 --action deny  --rules tcp --destination-ranges 130.14.250.27/32 --direction=EGRESS --priority 60000
gcloud compute firewall-rules create block-ingress-lo-udp-27 --action deny  --rules udp --source-ranges 130.14.250.27/32 --direction=INGRESS --priority 60000
gcloud compute firewall-rules create block-ingress-lo-tcp-27 --action deny  --rules tcp --source-ranges 130.14.250.27/32 --direction=INGRESS --priority 60000

gcloud compute firewall-rules create block-egress-lo-udp-231 --action deny  --rules udp --destination-ranges 165.112.9.231/32 --direction=EGRESS --priority 60000
gcloud compute firewall-rules create block-egress-lo-tcp-231 --action deny  --rules tcp --destination-ranges 165.112.9.231/32 --direction=EGRESS --priority 60000
gcloud compute firewall-rules create block-ingress-lo-udp-231 --action deny  --rules udp --source-ranges 165.112.9.231/32 --direction=INGRESS --priority 60000
gcloud compute firewall-rules create block-ingress-lo-tcp-231 --action deny  --rules tcp --source-ranges 165.112.9.231/32 --direction=INGRESS --priority 60000

gcloud compute firewall-rules create block-egress-lo-udp-232 --action deny  --rules udp --destination-ranges 165.112.9.232/32 --direction=EGRESS --priority 60000
gcloud compute firewall-rules create block-egress-lo-tcp-232 --action deny  --rules tcp --destination-ranges 165.112.9.232/32 --direction=EGRESS --priority 60000
gcloud compute firewall-rules create block-ingress-lo-udp-232 --action deny  --rules udp --source-ranges 165.112.9.232/32 --direction=INGRESS --priority 60000
gcloud compute firewall-rules create block-ingress-lo-tcp-232 --action deny  --rules tcp --source-ranges 165.112.9.232/32 --direction=INGRESS --priority 60000
