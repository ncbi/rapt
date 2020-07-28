# Read Assembly and Annotation Pipeline Tool (RAPT) – Documentation
RAPT is a NCBI pipeline designed for assembling and annotating Illumina genome sequencing reads obtained from a single bacterial or archaeal strain. RAPT consists of two major NCBI components, SKESA and PGAP. SKESA is a de-novo assembler for microbial genomes based on DeBruijn graphs. PGAP is a prokaryotic genome annotation pipeline that combines ab initio gene prediction algorithms with homology based methods. RAPT takes Illumina SRA run(s) or fastq files as input, as well as basic information on the sequenced organism and the user. The results of RAPT are an assembled and annotated genome. 
![RAPT](https://bitbucket.ncbi.nlm.nih.gov/projects/GPEXT/repos/rapt-public/raw/RAPT_context2.png?at=refs%2Fheads%2FDave%27s-documentation)

This repository contains documentation for the RAPT command line applications in a Docker image. We will demonstrate how to use the Docker image to run RAPT analysis on the Google Cloud Platform(GCP) using an example. 
Some basic knowledge of Unix/Linux commands, [NCBI-SKESA](https://github.com/ncbi/SKESA), and [NCBI-PGAP](https://github.com/ncbi/pgap) is useful in completing this tutorial.
Please see our [wiki page](https://bitbucket.ncbi.nlm.nih.gov/projects/GPEXT/repos/rapt-public/browse/docs/wiki?at=refs%2Fheads%2FDave%27s-documentation) for References, Licenses, FAQs, and In-depth Documentation and Examples. 


## System requirements
RAPT is designed to run on the Google Cloud Platform (GCP), it will run from the Google Shell or from a google instance with the following prerequisites:
- gcloud SDK (automatically enabled in Cloud Shell)
- gsutil tool (automatically enabled in Cloud Shell)
- Cloud Life Sciences - for help see [Quick start using a Cloud Shell](https://bitbucket.ncbi.nlm.nih.gov/projects/GPEXT/repos/rapt-public/browse/docs/wiki/In-depth%20Documentation%20and%20Examples.md?at=refs%2Fheads%2FDave%27s-documentation)
- Access to a GCP bucket for your data - for help see [Quick start using a Cloud Shell](https://bitbucket.ncbi.nlm.nih.gov/projects/GPEXT/repos/rapt-public/browse/docs/wiki/In-depth%20Documentation%20and%20Examples.md?at=refs%2Fheads%2FDave%27s-documentation)

RAPT will bring up and shut down Google instances as needed.   

## Quick start
Here are instructions to execute RAPT with a quick sample SRA run once your system is set up.  If you need more indepth instructions please go to our [wiki page](https://bitbucket.ncbi.nlm.nih.gov/projects/GPEXT/repos/rapt-public/browse/docs/wiki/In-depth%20Documentation%20and%20Examples.md?at=refs%2Fheads%2FDave%27s-documentation). 
1.	In a browser, sign into [GCP](https://console.cloud.google.com/)
2.  Invoke a Cloud Shell
3.	Download the RAPT command line interface, run_rapt_gcp.sh  
Cut and Paste or type these three commands at your Cloud Shell prompt

```bash
gsutil cp -r gs://ncbi-rapt/bin .
cd bin
chmod 755 ./run_rapt_gcp.sh
```
4.	Explore run_rapt_gcp.sh  
This command will provide instructions and options for running RAPT
```bash
./run_rapt_gcp.sh help
```

### Run RAPT with an example
To run RAPT, you need Illumina-sequenced reads for the genome you wish to assemble and annotate. These can be in a fasta file in a Google bucket, or they can be in a run in SRA.  
Important: Only reads sequenced on Illumina machines can be used by RAPT. 

- Starting from an SRA run  
To demonstrate how to run RAPT, we are going to use SRR3496277, a set of reads available in SRA for *Mycoplasma pirum*.  

This example takes about 1 hour and 50 minutes.

Run the following command where gs://your_results_bucket is your GCP bucket for RAPT output and logging data 
```bash
./run_rapt_gcp.sh submitjob -r SRR3496277 --bucket gs://your_results_bucket
```
Execution information:
```bash
$ ./run_rapt_gcp.sh submitjob -r SRR3496277 --bucket gs://your_results_bucket 
GCP Account: [1111111111111-compute@example.gserviceaccount.com]
Project: [example]
job id: [2565f37562]
job output: [gs://your_results_bucket/2565f37562]
Job is now running on GCP, and may take several hours
View the execution logs in https://console.cloud.google.com/logs/viewer?project=example&filters=text:2565f37562
Use joblist or jobdetails command to check the completion status
$ 
```
Check the status of the jobs executed in this project:
```bash
./run_rapt_gcp.sh joblist
```
Execution information:
```bash
$ ./run_rapt_gcp.sh joblist
GCP Account: [1111111111111-compute@example.gserviceaccount.com]
Project: [example]
JOB_ID          USER    LABEL   SRR     STATUS  START_TIME      END_TIME        OUTPUT_URI
2565f37562      tester SRR3496277      Running 2020-07-10T18:52:30     gs://dave_results_bucket/2565f37562
$ 
```

Please note that some runs may take up to 24 hours.

- Starting from fastq or fasta file  
You can use a fastq file produced by Illumina sequencers as input to RAPT. This file can contain single-end or paired-end reads, with two reads of a pair adjacent to each other in the file. Note that the quality scores are not necessary. The file needs to be copied to a Google bucket or to the Google Cloud shell from which you run run_rapt_gcp.sh.
The genus species of the sequenced organism needs to be provided on the command line. The strain is optional.
Here is an example command using a file in a Google bucket.

```
./run_rapt_gcp.sh submitjob -f gs://your_results_bucket/SRR3496277_frag.mapped.fastq -b gs://your_results_bucket --label wl_fastq_frag_test --organism "Mycoplasma pirum" --strain "ATCC 25960"
```
Execution information:
```bash
$ ./run_rapt_gcp.sh submitjob -f gs://your_results_bucket/M_pirum_25960.fastq -b gs://your_results_bucket --label M_pirum_25960 --organism "Mycoplasma pirum" --strain "ATCC 25960"
GCP Account: [1111111111111-compute@example.gserviceaccount.com]
Project: [example]
Job id: [4678b28657]
Job output: [gs://your_results_bucket/4678b28657]
Job is now running on GCP, and may take several hours
View the execution logs in https://console.cloud.google.com/logs/viewer?project=strides-documentation-testing&filters=text:4678b28657
Use joblist or jobdetails command to check the completion status
$ 
```


To get more execution details and examples in our [wiki page](https://bitbucket.ncbi.nlm.nih.gov/projects/GPEXT/repos/rapt/browse/docs/wiki/Detailed%20Examples%20for%20Running%20RAPT.md). 
- Setting up GCP with step by step guide
- Using fastq files as input

If you have other questions, please visit our FAQs page.

### Review the output
RAPT generates three files and puts them in the GCP bucket you specified. The starting 10 characters, "2894b72f9f" are from the job id assigned to your RAPT run. 
1. 2894b72f9f.log is file with the log of scripts and variables of your RAPT run
2. 2894b72f9f.verbose.log is a detailed log file of all the actions that RAPT performed for your run
3. 2894b72f9f.out is a tar-gzipped directory of the following output files
 - skesa.out.fa: multifasta files of the assembled contigs produced by SKESA
 - ani-tax-report.txt and ani-tax-report.xml: Taxonomy verification results in text or XML format   
 - PGAP annotation results in multiple formats  
• annot.gbk: annotated genome in GenBank flat file format  
• annot.gff: annotated genome in GFF3 format  
• annot.sqn: annotated genome in ASN format  
• annot.faa: multifasta file of the proteins annotated on the genome  
• annot.fna: multifasta file of the trancripts annotated on the genome  

See a [detailed description of the annotation output files](https://github.com/ncbi/pgap/wiki/Output-Files) for more information.

