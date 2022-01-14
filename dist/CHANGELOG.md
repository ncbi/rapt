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