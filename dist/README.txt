Read Assembly and Annotation Pipeline Tool (RAPT) v0.5.0

RAPT is a NCBI pipeline designed for assembling and annotating Illumina genome sequencing reads obtained from bacterial or archaeal isolates. RAPT consists of two major NCBI components, SKESA and PGAP. SKESA is a de-novo assembler for microbial genomes based on DeBruijn graphs. PGAP is a prokaryotic genome annotation pipeline that combines ab initio gene prediction algorithms with homology based methods. RAPT takes an Illumina SRA run or a fasta file as input and produces an assembled and annotated genome. 

If you are new to RAPT, please visit our wiki page at https://github.com/ncbi/rapt/wiki for detailed information.


This release should contain the following files:

* run_rapt_gcp.sh - script to run GCP RAPT
* run_rapt.py - script to run Stand-alone RAPT
* CHANGELOG.md
* release-notes.txt
* README.txt (this file)

== GCP RAPT ==
Users who have access to Google Cloud Platform (GCP) can run RAPT on GCP with the command line interface provided by the run_rapt_gcp.sh script. This option eliminates the hardware requirement (fairly high) to local machines (where you launch run_rapt_gcp.sh). Run the following command for basic usage:

~$ ./run_rapt_gcp.sh help

For further information regarding GCP RAPT, visit https://github.com/ncbi/rapt/wiki/GCP%20RAPT%20In-depth%20Documentation%20and%20Examples.md.

== Stand-alone RAPT ==
If you do not have access to GCP and do not plan to use it, the python script run_rapt.py can be used to run RAPT on the same computer where run_rapt.py is launched. The computer then must meet the following prerequisites:

* At least 4GB memory per CPU core  
* At least 8 CPU cores and 32 GB memory  
* Internet connection
* Python installed
* Container runner installed (docker/podman/singularity)

It is highly recommended to run Stand-alone RAPT in linux OS, including cloud instances. Windows 10 (Professional/Enterprise version) may also work with additional configuration effort. For details, please visit https://github.com/ncbi/rapt/wiki/Standalone%20RAPT%20In-depth%20Documentation%20and%20Recommendations.md.

Run the following command for basic usage:

~$ ./run_rapt.py -h

To check for our latest release, please go to https://github.com/ncbi/rapt/releases. 
