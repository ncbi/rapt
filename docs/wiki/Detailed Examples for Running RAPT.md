# Detailed Examples for Running RAPT

The pipeline can be run on data in NCBI's SRA project or using your own provided fasta/fastq files. The following example uses a run from SRA, in which case, the data is downloaded automatically.

## Run on a single set of reads available in SRA

Once you have opened session:

### Set the parameters
To make it easier, set these variables
```
export SRR="SRR4835107"
export GENUS_SPECIES="Salmonella enterica"
export TOPOLOGY="linear"
```

### Run SKESA 
Here are the important options for running skesa. 
```
  --reads arg                   Input fasta/fastq file(s) for reads (could be 
                                used multiple times for different runs, could 
                                be gzipped) [string]
  --use_paired_ends             Indicates that a single (not comma separated) 
                                fasta/fastq file contains paired reads [flag]
  --sra_run arg                 Input sra run accession (could be used multiple
                                times for different runs) [string]
```
In this example, the input data is in SRA, and we are using a single run, so we will use ```--sra_run SRR4835107```. The SRA run will be fetched from SRA automatically for SKESA to assemble the reads.

Run these commands.
```
echo $SRR
docker run --rm ncbi/skesa:v2.3.0 skesa --sra_run $SRR > ${SRR}.skesa.fa

```
This task takes ~5 minutes to complete.

### Create the YAML Input files 
To run PGAP, we must first create two YAML files to describe the input. The following Python code creates YAML files containing the minimum set of information needed by RAPT, based upon the variables set above. You don't need to use it; any text editor can create the files as well. The information provided is integrated in the output files. If you’d like to have more metadata in the output, see the documentation at https://github.com/ncbi/pgap/wiki/Input-Files. If you wish to submit the output to GenBank, please read the following XXXXX.

```
cat << EOF_input > ${SRR}_input.yaml
fasta:
    class: File
    location: ${SRR}.skesa.fa
submol:
    class: File
    location: ${SRR}_submol.yaml
report_usage: True
EOF_input

echo "Created ${SRR}_input.yaml"

cat << EOF_submol > ${SRR}_submol.yaml
topology: ${TOPOLOGY}
organism:
    genus_species: '${GENUS_SPECIES}'
contact_info:
    last_name: 'Doe'
    first_name: 'Jane'
    email: 'jane_doe@gmail.com'
    organization: 'My home institution'
    department: 'Department of Microbiology'
    street: '1234 Main St'
    city: 'Docker'
    postal_code: '12345'
    country: 'Lappland'
authors:
    - author:
        first_name: 'Jane'
        last_name: 'Doe'
        middle_initial: 'T'
EOF_submol

echo "Created ${SRR}_submol.yaml"
```
### Run PGAP 
We run pgap using the previously downloaded pgap.py utility and also check the taxon using an optional feature which compares the Average Nucleotide Identity to type assemblies. Note that this is the same process described in https://github.com/ncbi/pgap/wiki/Quick-Start

```
./pgap.py --taxcheck -o ${SRR}_results ${SRR}_input.yaml
```

Output will be placed in: /home/username/SRR4835107_results.

This task takes about 4 hours to complete.

## Run on multiple read sets available in SRA

### PROVIDE COMMAND LINE HERE  This need to be done

## Run on fastq files

Please note:  The assembler in RAPT is only capable of using Illumina short reads. 

### Copy the fastq file(s) to your working directory. 
In on GCP, you can upload file to your VM by selecting the gear icon from SSH browset window and then selecting "upload"
    
![Upload function](/projects/GPEXT/repos/rapt/browse/docs/wiki/upload.png)
### Assemble the genome 
-- single-end reads
```bash
docker run --rm -v $PWD:$PWD:rw -w $PWD ncbi/skesa:v2.3.0 skesa --fastq Run1.fastq > Run1.fa
```

-- paired-end reads
```bash 
docker run --rm -v $PWD:$PWD:rw -w $PWD ncbi/skesa:v2.3.0 skesa --fastq Run2_1.fastq Run2_2.fastq --use_paired_ends > Run2.fa
```
- Prepare the YAML input files as in the first example

### Annotate
```bash 
./pgap.py --taxcheck -o Run1_results Run1_input.yaml
```

## Omit genome validation
RAPT runs several verifications after the assembly step but before the annotation starts. *(TEXT NEEDS WORK)*
These include:
- Check that the organism name assigned to the genomic data is correct, using the average nucleotide identity method
- Making sure that the genome is in teh range of other GenBank assemblies for the same organism
- Verify that the assembled genome does not include vector or adaptor sequence

By default the annotation will not start if these checks fail.
You can override the failure by setting the [taxcheck](https://github.com/ncbi/pgap/wiki/Taxonomy-Check) flag --ignore-all errors:

```bash 
./pgap.py --ignore-all-errors --taxcheck -o Run1_results Run1_input.yaml
```

## What information is reported to NCBI when I run RAPT? 

For each run of the pipeline, two reports will be generated. One at the beginning, and one at the end. These reports help us measure our impact on the community, which in turns helps us get funds, so please report your usage. We collect:

        Date and time.
        A randomly generated UUID for each run.
        IP address.
        Pipeline version.

## How do I turn off reporting to NCBI?

```bash
./pgap.py -n or --no-usage-report  Run1_results Run1_input.yaml
```
    
## For other PGAP related FAQs

Please visit PGAP [page](https://github.com/ncbi/pgap/wiki/FAQ).

