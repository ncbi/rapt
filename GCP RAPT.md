# Google Cloud Platform (GCP) RAPT – Documentation

This page contains instruction and examples for running *GCP RAPT*. `run_rapt_gcp.sh` is a shell script provides a command line interface to run *GCP RAPT*. Some basic knowledge of Unix/Linux commands, [SKESA](https://github.com/ncbi/SKESA), and [PGAP](https://github.com/ncbi/pgap) is useful in completing this tutorial.
Please see our [wiki page](https://github.com/ncbi/rapt/wiki) for References, Licenses, FAQs, and In-depth Documentation and Examples. 


## System requirements
*GCP RAPT* is designed to run on the Google Cloud Platform (GCP), it has no special hardware requirements for the local machine (the one where `run_rapt_gcp.sh` runs). It can be conveniently invoked from the Google Cloud Shell or any computer with the following prerequisites:
- gcloud SDK installed (automatically enabled in Cloud Shell)
- gsutil tool installed (automatically enabled in Cloud Shell)
- Cloud Life Sciences API enabled for your project - for help see [Quick start using a Cloud Shell](https://github.com/ncbi/rapt/wiki/GCP%20RAPT%20In-depth%20Documentation%20and%20Examples.md)
- Access to a Google storage bucket for your data - for help see [Quick start using a Cloud Shell](https://github.com/ncbi/rapt/wiki/GCP%20RAPT%20In-depth%20Documentation%20and%20Examples.md)

*GCP RAPT* will bring up and shut down Google instances as needed.<br>

## Quick start
Here are instructions to execute RAPT once your system is set up. Additional instructions are available on our [wiki page](wiki/GCP%20RAPT%20In-depth%20Documentation%20and%20Examples.md). 
1.	In a browser, sign into [GCP](https://console.cloud.google.com/)
2.  Invoke a Cloud Shell
3.	Download the latest release by executing the following commands:

    ```
    ~$ curl -sSLo rapt.tar.gz https://github.com/ncbi/rapt/releases/download/v2.2.6/rapt-v2.2.6.tar.gz
    ~$ tar -xzf rapt.tar.gz && rm -f rapt.tar.gz
    ```
4.	Run `run_rapt_gcp.sh help` to see the *GCP RAPT* usage information.

### Try an example
To run RAPT, you need Illumina-sequenced reads for the genome you wish to assemble and annotate. These can be in a fasta file in a Google storage bucket, or they can be in a run in SRA (an accession).<br>
Important: Only reads sequenced on **Illumina machines** can be used by RAPT. 

#### Starting from an SRA run<br>
To demonstrate how to run RAPT, we are going to use SRR3496277, a set of reads available in SRA for *Mycoplasma pirum*.<br>
This example takes about 1 hour.

Run the following command, where [gs://your_results_bucket](https://cloud.google.com/storage/docs/creating-buckets) is the Google storage bucket where the outputs and logs will be copied when the job finishes.

```bash
~$ ./run_rapt_gcp.sh submitacc SRR3496277 --bucket gs://your_results_bucket<br>
```


If the job is successfully created, the script will print out execution information similar to the following:
```
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
~$ 
```


Check the status of the jobs executed under this project, run:
```bash
~$ ./run_rapt_gcp.sh joblist

GCP Account: [1111111111111-compute@example.gserviceaccount.com]
Project: [example]
JOB_ID          USER    LABEL   SRR     STATUS  START_TIME      END_TIME        OUTPUT_URI
5541b09bb9      tester SRR3496277      Running 2020-07-10T18:52:30     gs://your_results_bucket/2565f37562
~$ 
```


The results for the job will be available in the bucket you specified after the job is marked 'Done'. Please note that some runs may take up to 24 hours.

#### Starting from fastq or fasta file<br>
You can use a fastq or a fasta file produced by Illumina sequencers as input to RAPT. This file can contain paired-end reads, with the two reads of a pair adjacent to each other in the file or single-end reads. Note that the quality scores are not necessary. The file needs to be copied to the Google storage bucket before you run `run_rapt_gcp.sh`.

The genus species of the sequenced organism needs to be provided on the command line. The strain is optional.
Here is an example command using a file available in the bucket named your_input_bucket:

```bash
~$ ./run_rapt_gcp.sh submitfastq gs://your_input_bucket/M_pirum_25960.fastq -b gs://your_results_bucket --label M_pirum_25960 --organism "Mycoplasma pirum" --strain "ATCC 25960"
```


If the job is successfully created, the script will print out execution information similar to the following:

```
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

~$ 
```


To get more execution details and examples in our [wiki page](https://github.com/ncbi/rapt/wiki/GCP%20RAPT%20In-depth%20Documentation%20and%20Examples.md). 
- Setting up GCP with step by step guide
- Using fastq files as input

If you have other questions, please visit our [FAQs page](https://github.com/ncbi/rapt/wiki/FAQ.md).

### Review the output
*GCP RAPT* generates a tarball named `output.tar.gz` in your designated bucket, under a "directory" named after the 10-character job-id assigned at the start of the execution (i.e. "2894b72f9f"). The tarball contains the following files:
1. concise.log is file with the log of major stages and status of your RAPT run<br>
2. verbose.log is a detailed log file of all the actions and console outputs that RAPT performed for your run<br>
3. skesa.out.fa: multifasta files of the assembled contigs produced by SKESA<br>
4. ani-tax-report.txt and ani-tax-report.xml: Taxonomy verification results in text or XML format<br>
5. PGAP annotation results in multiple formats:<br>
   * annot.gbk: annotated genome in GenBank flat file format<br>
   * annot.gff: annotated genome in GFF3 format<br>
   * annot.sqn: annotated genome in ASN format<br>
   * annot.faa: multifasta file of the proteins annotated on the genome<br>
   * annot.fna: multifasta file of the trancripts annotated on the genome<br>
   * calls.tab: tab-delimited file of the coordinates of detected foreign sequence. Empty if no foreign contaminant was found.

Along with the tarball there is also a `run.log` file generated automatically by the Google Life Sciences Pipeline where RAPT is invoked. This file catches all output to stdout and stderr by anything, and may be helpful to identify the problem should any happens.


