# Standalone RAPT – Documentation

This repository contains instruction and examples for running RAPT.`run_rapt.py` is a python script that provides an interface to run the RAPT Docker image on a local machine. "Local" means the same machine as where run_rapt.py is executed. It could be a physical machine on premise, or more conveniently, a cloud VM instance.
Some basic knowledge of Unix/Linux commands, [SKESA](https://github.com/ncbi/SKESA), and [PGAP](https://github.com/ncbi/pgap) is useful in completing this tutorial.
Please see our [wiki page](https://bitbucket.ncbi.nlm.nih.gov/projects/GPEXT/repos/rapt-public/browse/wiki) for References, Licenses, FAQs, and In-depth Documentation and Examples. 


## System requirements

The machine must satisfy the following minimal requirements:  
•	At least 4GB memory per CPU core  
•	At least 8 CPU cores and 32 GB memory  
•	Linux OS preferred, Windows 10 (pro or enterprise version) will also work but extra configuration is required  
•	Internet connection  
•	Container runner installed (currently supports Docker/Podman/Singularity), Docker is recommended  
•	Python installed  
•	100GB free storage space on disk  


### Additional tips if using Windows 10 (pro/enterprise version)
1.	Right now it seems to only work on a real physical machine (L0, metal) with CPUs support virtualization (Like INTEL VT-x technology); Make sure this feature is enabled in BIOS
2.	Windows 10 only, must be at least Professional or Enterprise version (hypervisor capability)
3.	Install python and Docker Desktop
4.	Start Docker service with hyper-V enabled
5.	Make sure Docker has switched to 'Linux containers'. It should do so by default if hyper-V is up and running.

## Quick start
Here are instructions to execute RAPT once your system is set up. Additional instructions are available on our [wiki page](wiki/Standalone%20RAPT%20In-depth%20Documentation%20and%20Recommendations.md). 
1.	Go to your machine or instance command line
2.	Download the RAPT command line interface, ```run_rapt.py```    
Cut and paste or type these three commands at your Cloud Shell prompt:

```bash
curl -o run_rapt.py https://raw.githubusercontent.com/ncbi/rapt/master/dist/run_rapt.py
chmod a+x run_rapt.py
```
3.	Explore ```run_rapt.py```  
This command will provide instructions and options for running RAPT:
```bash
./run_rapt.py -h
```

### Try an example 
To run RAPT, you need Illumina-sequenced reads for the genome you wish to assemble and annotate. These can be in a fasta file on the machine where you wish to run RAPT, or they can be in a run in the NCBI Sequence Read Archive (SRA).  
Important: Only reads sequenced on Illumina machines can be used by RAPT. 

#### Starting from an SRA run   
To demonstrate how to run RAPT, we are going to use SRR3496277, a set of reads available in SRA for *Mycoplasma pirum*.  
This example takes about 1 hour.

Run the following command, the outputs and logs will be located in the current directory when the job finishes.
```bash
./run_rapt.py -a srr34961277
```
Execution information:
```bash
$ ./run_rapt.py -a srr34961277
RAPT is now running, it may take a long time to finish. To see the progress, track the verbose log file /home/username/raptout_e26d552147/verbose.log.
$ 
```

The results for the job will be located in the current directory when the job finishes. Please note that some runs may take up to 24 hours.

#### Starting from fastq or fasta file   
You can use a fastq or a fasta file produced by Illumina sequencers as input to RAPT. This file can contain paired-end reads, with the two reads of a pair adjacent to each other in the file or single-end reads. Note that the quality scores are not necessary. The file needs to be on the local file system.
The genus species of the sequenced organism needs to be provided on the command line. The strain is optional.
Here is an example command using a file available in the bucket named your_input_bucket:

```bash
$ ./run_rapt.py -q path/to/srr34961277.fastq --organism "Mycoplasma pirum" --strain "ATCC 25960"
```

Execution information:
```bash
$ ./run_rapt.py -q path/to/srr34961277.fastq --organism "Mycoplasma pirum" --strain "ATCC 25960"
RAPT is now running, it may take a long time to finish. To see the progress, track the verbose log file /home/username/raptout_d3e7956148/verbose.log.
$ 
```
 
To get more execution details and examples, see our [wiki page](wiki/Standalone%20RAPT%20In-depth%20Documentation%20and%20Examples.md). 
- Help Documentation  
- Reference data location  
- Advanced Options

If you have other questions, please visit our [FAQs page](wiki/FAQ.md).

### Review the output  

RAPT generates 12 output files.  The default location of result output is in the current directory. Each run of RAPT will create a subdirectory bearing the name raptout_<RUNID> where <RUNID> is a random 10-character string. The --tag JOBID switch can be used to specify a human-readable job id which will be appended after the random RUNID for easy recognition.
To store the output in location other than the current directory, use the -o or --output-dir switch to specify the desired location:
```bash
./run_rapt.py -q path/to/srr34961277.fastq --organism "Mycoplasma pirum" --strain "ATCC 25960" --output-dir path/to/output-dir
```
Logging
All messages from RAPT are logged, with time stamps, in a file named verbose.log in the output directory. Meanwhile they are also emitted to stdout so the progress can be easily monitored. A simpler version log file, concise.log, is also created with only entries mark the main stages.


1. concise.log is file with the log of scripts and variables of your RAPT run   
2. verbose.log is a detailed log file of all the actions that RAPT performed for your run   
3. skesa.out.fa: multifasta files of the assembled contigs produced by SKESA   
4. ani-tax-report.txt and ani-tax-report.xml: Taxonomy verification results in text or XML format   
5. PGAP annotation results in multiple formats:   
        * annot.gbk: annotated genome in GenBank flat file format     
        * annot.gff: annotated genome in GFF3 format     
        * annot.sqn: annotated genome in ASN format     
        * annot.faa: multifasta file of the proteins annotated on the genome   
        * annot.fna: multifasta file of the trancripts annotated on the genome   
        * calls.tab: tab-delimited file of the coordinates of detected foreign sequence. Empty if no foreign contaminant was found.

See a [detailed description of the annotation output files](https://github.com/ncbi/pgap/wiki/Output-Files) for more information.