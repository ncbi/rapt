### Release v0.3.2
- change default machine type from n1-himem-16 to n1-himem-8
- attach ncbi_user to pinger events if run by web-rapt

### Release v0.3.1
- Added --network command line to specify custom network for container
- Some exit codes merged and combined
- Exclude dummy strings for taxonomy names
- Remove redundent errors.xml file from pgap output
- Updated SKESA version and ngs/vdb libs
- Added docker daemon status check

### Release v0.3.0
- new PGAP version
- sends email notifications
- accepts forward and reverse reads in two files
- monitors user quotas
- verifies taxonomic data
- accepts an argument to stop upon taxonomic disagreement
- bug fixes, including invalid SRA index
- improved logging
- improved error messaging
- cleaned up output files

### Release v2.2.6
 - GCP-RAPT: added `--project` option to specify custom project.
 - GCP-RAPT: log file names are fixed to concise.log and verbose.log
 - GCP-RAPT: log files are included in the output archive
 - GCP-RAPT: added *metadata.events* to `jobdetails` command output
 - GCP-RAPT: `joblist` command displays job status as *Done* instead of *Finished* and *Failed* instead of *Aborted* to reflect the actual job status
 - Standalone RAPT: suppress stderr log stream by default and add option to enable it
 - PINGER ncbi_app name changed from _rapt_ to _raptdocker_. 
 - Fix verbose log capture bug
 - Includes RAPT build id at the beginning of log files
 - Added variation analysis to annotation by new version of PGAPX.
 - Simplified PINGER usage report data

### Release v0.2.2
 - Code refactoring, remove duplicated codes
 - All codes are subject to lint with NCBI rules
 - Add message to show data-download retrying
 - Stand-alone RAPT: Default in silence mode, but print error messages if container returns non-zero status
 - Fix NCBI PINGER ```ncbi_app``` values for different flavors (GCP-RAPT, Stand-alone RAPT and web-rapt)
 - Remove duplicated sequence file ```annot.fna``` from output
 - Added input sequence assemble statistics
 - Added retry logic to ```srapath``` to address sporadic failures
 - Fix final status error

### Release v0.2.0
 - GCP-RAPT: added `--project` option to specify custom project.
 - GCP-RAPT: log file names are fixed to concise.log and verbose.log
 - GCP-RAPT: log files are included in the output archive
 - GCP-RAPT: added *metadata.events* to `jobdetails` command output
 - GCP-RAPT: `joblist` command displays job status as *Done* instead of *Finished* and *Failed* instead of *Aborted* to reflect the actual job status
 - Standalone RAPT: suppress stderr log stream by default and add option to enable it
 - PINGER ncbi_app name changed from _rapt_ to _raptdocker_. 
 - Fix verbose log capture bug
 - Includes RAPT build id at the beginning of log files
 - Added variation analysis to annotation by new version of PGAPX.
 - Simplified PINGER usage report data

### Initial release v0.1.0
 - Change help text for --no-usage-reporting switch
 - Removed --location option in run_rapt_gcp.sh
 - append status code at the bottom of log files
 - env and timeout mod to enable running succesfully
 - changes to allow submitting a job and saving output
 - cancel, get, error check methods
 - Corrected py_binary rules