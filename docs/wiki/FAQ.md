### Can I use reads that are not produced by an Illumina sequencing machine?

At this time RAPT only supports FASTQ files from Illumina and SRR files from SRA.

### Can I assemble and annotate a metagenomic sample?
No, RAPT is only designed to work on data from singe strains.

### I do not wish to run SKESA. Can I use a different read assembler?

At this time, RAPT only supports [SKESA](https://www.ncbi.nlm.nih.gov/pubmed/30286803). If you wish to annotate an already assembled genome, please use [PGAP](https://github.com/ncbi/pgap)

### Who do I contact for help or feedback?

Please send questions or comments to:  [prokaryote-tools@nih.gov](prokaryote-tools@nih.gov)
I THINK WE SHOULD ENCOURAGE USERS TO OPEN GITHUB ISSUE FIRST. NO?

### What environments are supported with RAPT?

Although RAPT is a docker image and will work in theory where every docker works, at this time we only support the Google platform.
We reccomend a n1-standard-8 (8 vCPUs, 30 GB memory) GCP instance with at least 100GB of storage.

### Can I submit the annotation I just produced with RAPT?

It depends. You can if the starting material (raw reads) are in SRA and owned by you, or are not in SRA. In addition, you may not be able to submit the annotation if you have used the ```--ignore-all-errors``` flag, to override taxonomic assignemnt or assembly validation issues.

### What information is reported to NCBI?

For each run of the pipeline, two reports will be generated. One at the beginning, and one at the end. These reports help us measure our impact on the community, which in turns helps us get funds, so please report your usage. We collect:

        Date and time.
        A randomly generated UUID for each run.
        IP address.
        Pipeline version.

### How do I turn of the NCBI reporting feature?

Although we recomend always reporting information back to NCBI because this helps us build a better product by understanding usage and errors, you can disable this by adding the following to your cammand line:

'-n' or '--no-usage-report' 


### See also the [PGAP FAQs](https://github.com/ncbi/pgap/wiki/FAQ)
