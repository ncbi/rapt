#!/bin/env python3
import sys
import os
import subprocess

version=sys.argv[1]
branch=sys.argv[2]
is_release=branch not in ["dev", "test", "prod"]

# Get CWL code
if is_release:
    os.makedirs("cwl", exist_ok=True)
    remote_file=f"https://api.github.com/repos/ncbi/pgap/tarball/{version}"
    subprocess.run(["curl", "-sLO", remote_file], check=True)
    subprocess.run(["tar", "xvzf", version, "-C", "cwl", "--strip-components=1"], check=True)
    os.remove(version)
else:
    subprocess.run(["git", "clone", "--branch", branch, "https://github.com/ncbi/pgap.git", "cwl"], check=True)

# Get Docker image
if is_release:
    repo="pgap-utils"
else:
    repo=f"pgap-{branch}"
image=f"ncbi/{repo}:{version}"
subprocess.run(["sudo", "docker", "pull", "-q", image], check=True)
subprocess.run(["sudo", "rm", "-rf", ".docker"], check=True)

# Get input data
if is_release:
    url=f"https://s3.amazonaws.com/pgap/input-{version}.tgz"
else:
    url=f"https://s3.amazonaws.com/pgap/input-{version}.{branch}.tgz.tgz"
subprocess.run([f"curl -s {url} | tar xvzf -"], shell=True, check=True)

# Get ANI data
if is_release:
    url=f"https://s3.amazonaws.com/pgap/input-{version}.ani.tgz"
else:
    url=f"https://s3.amazonaws.com/pgap/input-{version}.{branch}.ani.tgz"
subprocess.run([f"curl -s {url} | tar xvzf -"], shell=True, check=True)
