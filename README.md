# Read Assembly and Annotation Pipeline Tool (RAPT) – Documentation
RAPT is a NCBI pipeline designed for assembling and annotating Illumina genome sequencing reads obtained from a single bacterial or archaeal strain. RAPT consists of two major NCBI components, SKESA and PGAP. SKESA is a de-novo assembler for microbial genomes based on DeBruijn graphs. PGAP is a prokaryotic genome annotation pipeline that combines ab initio gene prediction algorithms with homology based methods. RAPT takes Illumina SRA run(s) or fastq files as input, as well as basic information on the sequenced organism and the user. The results of RAPT are an assembled and annotated genome. 
![RAPT](/projects/GPEXT/repos/rapt/browse/RAPT_context2.png)

This repository contains documentation for the RAPT command line applications in a Docker image. We will demonstrate how to use the Docker image to run RAPT analysis on the Google Cloud Platform(GCP) using an example. 
Some basic knowledge of Unix/Linux commands, [NCBI-SKESA](https://github.com/ncbi/SKESA), and [NCBI-PGAP](https://github.com/ncbi/pgap) is useful in completing this tutorial.
Other examples, and information on [GCP and Docker](https://bitbucket.ncbi.nlm.nih.gov/projects/GPEXT/repos/rapt/browse/docs/wiki/Set%20Up%20RAPT%20on%20a%20Google%20Cloud%20Platform%20Virtual%20Machine.md) can be found on the wiki page (ADD LINK). 


## System requirements
RAPT can run anywhere: on your own machine, a local computer grid, or a cloud environment, as long as the machine has the following:
- Python (version 3.6 or higher)
- The ability to run Docker (see wiki for more details)
- About 100GB of storage for the supplemental data and working space
- 2GB-4GB of memory available per CPU used by your container
- The CPU must have SSE 4.2 support (released in 2008).
Note: Debian 10 is currently not supported.

## Quick start
Here are instructions to execute RAPT with a quick sample SRA run once your system is set up.
### Prepare the input
To run RAPT, you need:
- Identify the SRA run(s) or Illumina sequenced reads for the genome you wish to assemble and annotate – LINK TO THE SKESA DOC HERE?
- Prepare a YAML file containing the metadata associated with raw reads. More information is found [here](https://github.com/ncbi/pgap/wiki/Input-Files#metadata-files).

To demonstrate how to run RAPT, we are going to use SRR3496277, a set of reads available in SRA for *Mycoplasma pirum*.  Also, we are going to create minimal YAML files with standard linux commands.
### Create YAML files
Inputs to RAPT must be provided as two YAML files
* The input YAML file 
* The metatdata YAML file

```bash
NEEDS TO BE MODIFIED AFTER INTEGRATION OF SKESA.
cat << EOF_input > SRR3496277_input.yaml
fasta:
    class: File
    location: SRR3496277.skesa.fa
submol:
    class: File
    location: SRR3496277_submol.yaml
report_usage: True
EOF_input

echo "Created SRR3496277_input.yaml"

cat << EOF_submol > SRR3496277_submol.yaml
topology: linear  <============ MAY BE OPTIONAL (IF NOT SPECIFIED DEFAULTS TO LINEAR)
organism:
    genus_species: 'Mycoplasma pirum'
    strain: 'ATCC 25960' <============ OPTIONAL. REMOVE??
contact_info:
    last_name: 'Doe'
    first_name: 'Jane'
    email: 'jane_doe@gmail.com'
    organization: 'My home institution'
    department: 'Department of Microbiology'
    street: '1234 Main St'
    city: 'Docker'
    postal_code: '12345'
    country: 'Lapland'
authors:
    - author:
        first_name: 'Jane'
        last_name: 'Doe'
EOF_submol

echo "Created SRR3496277_submol.yaml"
```

### Download RAPT 
Download SKESA
```bash
docker pull ncbi/skesa:v2.3.0
```
Download the PGAP convenience script
```bash
curl -OL https://github.com/ncbi/pgap/raw/prod/scripts/pgap.py
chmod +x pgap.py
./pgap.py --taxcheck --update
```
### Run RAPT
Here is how to run RAPT utilizing the SRA read and YAML file created above.
```bash
docker run --rm ncbi/skesa:v2.3.0 skesa --sra_run SRR3496277 > SRR3496277.skesa.fa
./pgap.py --taxcheck -o SRR3496277_results SRR3496277_input.yaml
```
This example takes about 1 hour and 40 minutes on a n1-standard-8 (8 vCPUs, 30 GB memory) GCP instance.

To get more execution details and examples in our [wiki page](https://bitbucket.ncbi.nlm.nih.gov/projects/GPEXT/repos/rapt/browse/docs/wiki/Detailed%20Examples%20for%20Running%20RAPT.md). 
- Using more than one SRA run as input
- Using fastq files as input
- Running without validation

### Review the output
RAPT currently generates the following files in the result directory, SRR3496277_results for this example.
1.	Assembled contigs in FASTA format: SRR3496277.skesa.fa: multifasta files of the assembled contigs produced by SKESA
2.	Taxonomy verification results: ani-tax-report.txt and ani-tax-report.xml (if run with the --taxcheck flag): Taxonomy check report in text and xml format
3.	PGAP annotation results in multiple formats 
- annot.gbk: annotated genome in GenBank flat file format
- annot.gff: annotated genome in GFF3 format
- annot.sqn: annotated genome in ASN format
- annot.faa: multifasta file of the proteins annotated on the genome
- annot.fna: multifasta file of the trancripts annotated on the genome 
See a [detailed description of the annotation output files](https://github.com/ncbi/pgap/wiki/Output-Files).

