# RAPT base image

# Using the Jupyter Notebook

Start the image on your cloud provider and open up a port for Jupyter

## Google Cloud Platform

(Based upon project)

gcloud compute --project=ncbi-rapt firewall-rules create allow-jupyter-8080 --description="Allow access to a Jupyter notebook running on port 8080 " --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:8080 --source-ranges=0.0.0.0/0

## AWS

TBD


## Start the Jupyter Notebook

jupyter-notebook --no-browser --ip=* --port=8080