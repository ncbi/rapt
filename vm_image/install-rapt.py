#!/bin/env python3
import sys
import os
import subprocess

version=sys.argv[1]

os.umask(0o002)

# Get CWL code
os.makedirs("cwl", exist_ok=True)
remote_file=f"https://api.github.com/repos/ncbi/pgap/tarball/{version}"
subprocess.run(["curl", "-sLO", remote_file], check=True)
subprocess.run(["tar", "xvzf", version, "-C", "cwl", "--strip-components=1"], check=True)
os.remove(version)

subprocess.run(["ln", "-s", "cwl/scripts/pgap.py"], check=True)
    
# Get PGAP docker images
repos = [ "pgap-utils" , "pgap" ]
for repo in repos:
    image=f"ncbi/{repo}:{version}"
    subprocess.run(["sudo", "docker", "pull", "-q", image], check=True)

# Get Skesa
subprocess.run(["sudo", "docker", "pull", "-q", "ncbi/skesa:v2.3.0"], check=True)
subprocess.run(["sudo", "rm", "-rf", ".docker"], check=True)

# Get input data
url=f"https://s3.amazonaws.com/pgap/input-{version}.tgz"
subprocess.run([f"curl -s {url} | tar xvzf -"], shell=True, check=True)
open(f'input-{version}/.pgap_complete', 'a').close()

# Get ANI data
url=f"https://s3.amazonaws.com/pgap/input-{version}.ani.tgz"
subprocess.run([f"curl -s {url} | tar xvzf -"], shell=True, check=True)
open(f'input-{version}/.ani_complete', 'a').close()

