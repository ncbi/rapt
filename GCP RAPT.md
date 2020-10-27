# Google Cloud Platform (GCP) RAPT – Documentation

This repository contains instruction and examples for running RAPT. 
Some basic knowledge of Unix/Linux commands, [SKESA](https://github.com/ncbi/SKESA), and [PGAP](https://github.com/ncbi/pgap) is useful in completing this tutorial.
Please see our [wiki page](https://github.com/ncbi/rapt/wiki) for References, Licenses, FAQs, and In-depth Documentation and Examples. 


## System requirements
RAPT is designed to run on the Google Cloud Platform (GCP), it will run from the Google Shell or from a google instance with the following prerequisites:
- gcloud SDK (automatically enabled in Cloud Shell)
- gsutil tool (automatically enabled in Cloud Shell)
- Cloud Life Sciences - for help see [Quick start using a Cloud Shell](wiki/GCP%20RAPT%20In-depth%20Documentation%20and%20Examples.md)
- Access to a Google storage bucket for your data - for help see [Quick start using a Cloud Shell](wiki/GCP%20RAPT%20In-depth%20Documentation%20and%20Examples.md)

RAPT will bring up and shut down Google instances as needed.   

## Quick start
Here are instructions to execute RAPT once your system is set up. Additional instructions are available on our [wiki page](wiki/GCP%20RAPT%20In-depth%20Documentation%20and%20Examples.md). 
1.	In a browser, sign into [GCP](https://console.cloud.google.com/)
2.  Invoke a Cloud Shell
3.	Download the latest release ([zipball](https://github.com/ncbi/rapt/releases/download/v0.2.0/rapt-v0.2.0.zip) or [tarball](https://github.com/ncbi/rapt/releases/download/v0.2.0/rapt-v0.2.0.tar.gz)) and extract the GCP RAPT interface script ```run_rapt_gcp.sh``` 
4.	Explore ```run_rapt_gcp.sh```  
This command will provide instructions and options for running RAPT:
```bash
./run_rapt_gcp.sh help
```

### Try an example
To run RAPT, you need Illumina-sequenced reads for the genome you wish to assemble and annotate. These can be in a fasta file in a Google storage bucket, or they can be in a run in SRA.  
Important: Only reads sequenced on Illumina machines can be used by RAPT. 

#### Starting from an SRA run   
To demonstrate how to run RAPT, we are going to use SRR3496277, a set of reads available in SRA for *Mycoplasma pirum*.  
This example takes about 1 hour.

Run the following command, where [gs://your_results_bucket](https://cloud.google.com/storage/docs/creating-buckets) is the Google storage bucket where the outputs and logs will be copied when the job finishes.
```bash
./run_rapt_gcp.sh submitacc SRR3496277 --bucket gs://your_results_bucket  
```
Execution information:
```bash
$ ./run_rapt_gcp.sh submitacc SRR3496277 --bucket gs://your_results_bucket

RAPT job has been created successfully.
----------------------------------------------------
Job-id:             5541b09bb9
Output storage:     gs://your_results_bucket/5541b09bb9
GCP account:        1111111111111-compute@developer.gserviceaccount.com
GCP project:        example
----------------------------------------------------

[**Attention**] RAPT jobs may take hours to finish. Progress of this job can be viewed in GCP stackdriver log viewer at:

        https://console.cloud.google.com/logs/viewer?project=strides-documentation-testing&filters=text:5541b09bb9

For current status of this job, run:

        run_rapt_gcp.sh joblist | fgrep 5541b09bb9

For technical details of this job, run:

        run_rapt_gcp.sh jobdetails 5541b09bb9
$ 
```
Check the status of the jobs executed in this project.
```bash
./run_rapt_gcp.sh joblist
```
Execution information:
```bash
$ ./run_rapt_gcp.sh joblist
GCP Account: [1111111111111-compute@example.gserviceaccount.com]
Project: [example]
JOB_ID          USER    LABEL   SRR     STATUS  START_TIME      END_TIME        OUTPUT_URI
5541b09bb9      tester SRR3496277      Running 2020-07-10T18:52:30     gs://your_results_bucket/2565f37562
$ 
```

The results for the job will be available in the bucket you specified after the job is marked 'Finished'. Please note that some runs may take up to 24 hours.

#### Starting from fastq or fasta file   
You can use a fastq or a fasta file produced by Illumina sequencers as input to RAPT. This file can contain paired-end reads, with the two reads of a pair adjacent to each other in the file or single-end reads. Note that the quality scores are not necessary. The file needs to be copied to a Google storage bucket or to the Google Cloud shell from which you run ```run_rapt_gcp.sh```.
The genus species of the sequenced organism needs to be provided on the command line. The strain is optional.
Here is an example command using a file available in the bucket named your_input_bucket:

```bash
$ ./run_rapt_gcp.sh submitfastq gs://your_input_bucket/M_pirum_25960.fastq -b gs://your_results_bucket --label M_pirum_25960 --organism "Mycoplasma pirum" --strain "ATCC 25960"
```

Execution information:
```bash
$ ./run_rapt_gcp.sh submitfastq gs://your_input_bucket/M_pirum_25960.fastq -b gs://your_results_bucket --label M_pirum_25960 --organism "Mycoplasma pirum" --strain "ATCC 25960"

RAPT job has been created successfully.
----------------------------------------------------
Job-id:             b2ac02d7c7
Output storage:     gs://your_results_bucket/b2ac02d7c7
GCP account:        1111111111111-compute@developer.gserviceaccount.com
GCP project:        example
----------------------------------------------------

[**Attention**] RAPT jobs may take hours to finish. Progress of this job can be viewed in GCP stackdriver log viewer at:

        https://console.cloud.google.com/logs/viewer?project=strides-documentation-testing&filters=text:b2ac02d7c7

For current status of this job, run:

        run_rapt_gcp.sh joblist | fgrep b2ac02d7c7

For technical details of this job, run:

        run_rapt_gcp.sh jobdetails b2ac02d7c7

$ 
```

To get more execution details and examples in our [wiki page](wiki/GCP%20RAPT%20In-depth%20Documentation%20and%20Examples.md). 
- Setting up GCP with step by step guide
- Using fastq files as input

If you have other questions, please visit our [FAQs page](wiki/FAQ.md).

### Review the output
RAPT generates three output files and puts them in the GCP bucket you specified. These files are named after the 10-character job-id assigned at the start of the execution (i.e. "2894b72f9f"). 
1. 2894b72f9f.log is file with the log of scripts and variables of your RAPT run   
2. 2894b72f9f.verbose.log is a detailed log file of all the actions that RAPT performed for your run   
3. 2894b72f9f_output.tar.gz is a tar-gzipped directory of the following output files:   
    a. skesa.out.fa: multifasta files of the assembled contigs produced by SKESA   
    b. ani-tax-report.txt and ani-tax-report.xml: Taxonomy verification results in text or XML format   
    c. PGAP annotation results in multiple formats:   
        * annot.gbk: annotated genome in GenBank flat file format     
        * annot.gff: annotated genome in GFF3 format     
        * annot.sqn: annotated genome in ASN format     
        * annot.faa: multifasta file of the proteins annotated on the genome   
        * annot.fna: multifasta file of the trancripts annotated on the genome   
        * calls.tab: tab-delimited file of the coordinates of detected foreign sequence. Empty if no foreign contaminant was found.

See a [detailed description of the annotation output files](https://github.com/ncbi/pgap/wiki/Output-Files) for more information.
