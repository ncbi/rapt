# Set Up RAPT on a Google Cloud Platform Virtual Machine

This section includes instructions to create a Google virtual machine, install Docker, and run RAPT commands using the Docker image.
First, you need to set up a Google Cloud Platform (GCP) virtual machine (VM) for analysis.
Requirements
- A GCP account linked to a billing account
- A GCP VM running Ubuntu 18.04LTS

## Set up your GCP account and create a VM for analysis
### Open a GCP account
First, in a separate browser window or tab, sign in at https://console.cloud.google.com/ 
- If you need to create one, go to https://cloud.google.com/ and click “Get started for free” to sign up for a trial account.
- If you have multiple Google accounts, sign in using an Incognito Window (Chrome) or Private Window (Safari) or any other private browser window.
- GCP is currently offering a $300 credit, which expires 12 months from activation, to incentivize new cloud users. The following steps will show you how to activate this credit. You will be asked for billing information, but GCP will not auto-charge you once the trial ends; you must elect to manually upgrade to a paid account.

### Create a Virtual Machine (VM)
On the GCP welcome screen from the last step, click "Compute Engine" or navigate to the "Compute Engine" section by clicking on the navigation menu with the "hamburger icon" (three horizontal lines) on the top left corner.

![GCP_1](/projects/GPEXT/repos/rapt/browse/docs/wiki/GCP_1.png)

Click on the blue “CREATE INSTANCE” button on the top bar.
Create an image with the following parameters: (if parameter is not list below, keep the default setting) 
- Name: keep the default or enter a name
- Region: us-east4 (Northern Virginia)
- For Section 2, change these settings   
-- Machine Type:  n1-standard-8 (8 vCPU, 30 GB memory)  
-- Boot Disk: Click "Change," select Operating system Ubuntu, Version Ubuntu 18.04 LTS, with a boot disc size of 100 GB and click "Select".

At this point, you should see a cost estimate for this instance on the right side of your window.

![GCP_2](/projects/GPEXT/repos/rapt/browse/docs/wiki/GCP_2.png)


Click the blue “Create” button. This will create and start the VM.
Please note: Creating a VM in the same region as storage can provide better performance. We recommend creating a VM in the us-east4 region. If you have a job that will take several hours, but less than 24 hours, you can potentially take advantage of preemptible VMs.

## Access a GCP VM from a local machine
Once you have created a VM, you must access it from your local computer. There are many methods to access your VM, depending on the ways in which you would like to use it. On the GCP, the most straightforward way is to SSH from the browser.

Connect to your new VM instance by clicking the "SSH" button

![GCP_3](/projects/GPEXT/repos/rapt/browse/docs/wiki/GCP_3.png)

You now have a command shell running and you are ready to proceed.
Remember to stop or delete the VM after you are done, to prevent incurring additional cost.

## Install Docker
- Run these commands to install Docker and add non-root users to run Docker
```
sudo snap install docker
sudo apt update
sudo apt install -y docker.io
sudo usermod -aG docker $USER
exit
```
- exit and SSH back in for changes to take effect
- To confirm the correct installation of Docker, run the command:
```
docker run hello-world
```
If correctly installed, you should see "Hello from Docker!..."(https://docs.docker.com/samples/library/hello-world/)

## Install RAPT
There are two main components to this pipeline, the SKESA assembler and PGAP annotator.
- Install SKESA using the docker image
```
docker pull ncbi/skesa:v2.3.0
```
- Install PGAP using its control software, pgap.py 
```
curl -OL https://github.com/ncbi/pgap/raw/prod/scripts/pgap.py
chmod +x pgap.py
./pgap.py --taxcheck --update
```
You are now ready to assembled and annoted a genome!
See examples in XXXXXX

## After you are done, remember to stop or delete the VM to prevent incurring additional cost!
