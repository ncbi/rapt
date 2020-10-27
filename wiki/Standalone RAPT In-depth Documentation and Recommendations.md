# In-depth Documentation and Examples

This wiki contains step by step examples of installing and running Standalonee RAPT command line Docker image on a local machine.  Some basic knowledge of Unix/Linux commands, [NCBI-SKESA](https://github.com/ncbi/SKESA), and [NCBI-PGAP](https://github.com/ncbi/pgap) is useful in completing this tutorial.

# System Requirements
The machine must satisfy the following minimal requirements:  
•	At least 4GB memory per CPU core  
•	At least 8 CPU cores and 32 GB memory  
•	Linux OS preferred, Windows 10 (pro or enterprise version) will also work but extra configuration is required  
•	Internet connection  
•	Container runner installed (currently supports Docker/Podman/Singularity), Docker is recommended, below is a method to install Docker on a For a Ubuntu Linux machine, with version 18.04 LTS. Your operating system may require different commands. Please visit [Docker](https://docs.docker.com/engine/install/) for details.
```bash
sudo snap install docker
sudo apt update
sudo apt install -y docker.io
sudo usermod -aG docker $USER
exit
**re-log into your machine**
docker run hello-world
```

•	Python installed, below is a method to install python on a linux machine
```bash
sudo apt install python
```

•	100GB free storage space on disk  


**You are now ready to install and run RAPT**   

Cut and paste or type in the following commands at the command line prompt
```bash
curl -o run_rapt.py https://raw.githubusercontent.com/ncbi/rapt/master/dist/run_rapt.py
chmod a+x run_rapt.py
```
Explore ```run_rapt.py```  
This command will provide instructions and options for running RAPT:
```bash
./run_rapt.py -h
```

Execution information:
```bash
~$ ./run_rapt.py -h
usage: run_rapt.py [-h] [-a ACXN | -q FASTQ | -v | --test] [--organism ORGA]
                   [--strain STRAIN] [--skesa-only] [--no-usage-reporting]
                   [-o OUTDIR] [--refdata-dir REFDATA_HUB] [-c MAXCPU]
                   [-m MAXMEM] [--tag JOBID] [-D {docker,podman,singularity}]

Read Assembly and Annotation Pipeline Tool (RAPT)

optional arguments:
  -h, --help            show this help message and exit

  -a ACXN, --submitacc ACXN
                        Run RAPT on an SRA run accession (sra_acxn).
  -q FASTQ, --submitfastq FASTQ
                        Run RAPT on Illumina reads in FASTQ or FASTA format.
                        The file must be readable from the computer that runs
                        RAPT. The --organism argument is mandatory for this
                        type of input, while the --strain argument is
                        optional.
  -v, --version         Display the current RAPT version
  --test                Run a test suite. When RAPT does not produce the
                        expected results, it may be helpful to use this
                        command to ensure RAPT is functioning normally.
  --organism ORGA       Specify the binomial name or, if the species is
                        unknown, the genus for the sequenced organism. This
                        identifier must be valid in NCBI Taxonomy.
  --strain STRAIN       Specify the strain of the organism
  --skesa-only          Only assemble sequences to contigs, but do not
                        annotate.
  --no-usage-reporting  Prevents usage report back to NCBI. By default, RAPT
                        sends usage information back to NCBI for statistical
                        analysis. The information collected are a unique
                        identifier for the RAPT process, the machine IP
                        address, the start and end time of RAPT, and its three
                        modules: SKESA, taxcheck and PGAP. No personal or
                        project-specific information (such as the input data)
                        are collected
  -o OUTDIR, --output-dir OUTDIR
                        Directory to store results and logs. If omitted, use
                        current directory
  --refdata-dir REFDATA_HUB
                        Specify a location to store reference data used by
                        RAPT. If omitted, use output directory
  -c MAXCPU, --cpus MAXCPU
                        Specify the maximal CPU cores the container should
                        use.
  -m MAXMEM, --memory MAXMEM
                        Specify the maximal memory (number in GB) the
                        container should use.
  --tag JOBID           Specify a custom string to tag the job
  -D {docker,podman,singularity}, --docker {docker,podman,singularity}
                        Use specified docker compatible program to run RAPT
                        image
```


### Reference data
The default location of reference data is in the current working directory. RAPT will detect whether the proper version of reference data is available and automatically download if not. Downloaded reference data are stored in a version-named sub-directory,  such as input-2020-07-09.build4716, so that multiple versions of reference data can exist side-by-side.  Users who run RAPT regularly may want to store the reference data in a dedicated location, in which case the --refdata-dir switch can be used to specify a location other than the current directory:
```bash
run_rapt.py -q path/to/srr34961277.fastq --organism "Mycoplasma pirum" --strain "ATCC 25960" --refdata-dir path/to/refdata-dir
```

### Advanced options
-D docker|podman|singularity: If multiple runners are installed (highly discouraged), user can specify a particular one to use. If full path to the binary is provided, RAPT will use the path. Otherwise it must be specified in $PATH environment so that RAPT can find it.
-c MAXCPU, --cpus MAXCPU: Specify the maximal number of CPUs the container should use. 
-m MAXMEM, --memory MAXMEM: Specify the maximal amount of memory (in GB) the container should use.
Note: Singularity does not support dynamic resource limitation so the above options have no effect.


If you have other questions, please visit our [FAQs page](wiki/FAQ.md).