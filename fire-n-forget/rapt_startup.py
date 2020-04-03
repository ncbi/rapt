#!/usr/bin/python3
import pwd
import os
import sys
import glob
import atexit
import pathlib
import requests
import subprocess
import uuid

class rapt_control:

    def __init__(self):
        self.home_dir = os.path.expanduser('~rapt')
        self.work_dir = f"{self.home_dir}/work"
        self.debug_dir = f"{self.work_dir}/debug"
        self.blast_cache_dir = f"{self.home_dir}/blast_hits_cache"
        self.headers = { 'Metadata-Flavor' : 'Google' }
        self.url = "http://metadata/computeMetadata/v1/instance/"
        self.debug = False
        self.has_blast_cache = False
        self.has_sra_id = False

    def has_run(self):
        return os.path.exists(self.work_dir)

    def setup(self):
        os.makedirs(self.debug_dir, exist_ok=True)
        os.makedirs(f"{self.work_dir}/output", exist_ok=True)
        self.get_metadata()
        self.get_version()
        self.get_dockerimage()
        self.fetch_input()
        self.fetch_blast_cache()
        self.write_uuid()
        self.write_submol()
        self.write_input_yaml()

    def get_metadata(self):
        r = requests.get(self.url, params={'recursive': True}, headers=self.headers)
        with open(f"{self.work_dir}/debug/metadata.json", 'w') as f:
            f.write(r.text)
        md = r.json()
        self.hostname = md['hostname'].split(".")[0]
        self.attributes = md['attributes']
        if 'debug' in self.attributes:
            self.debug = ( self.attributes['debug'] == "true" )

    def get_version(self):
        self.input_dir = glob.glob(f"{self.home_dir}/input-*")[0]
        name = os.path.basename(self.input_dir)
        self.version = name.replace("input-", "")

    def get_dockerimage(self):
        cmd = "docker images | grep -m1 ncbi | awk '{$0=$1\":\"$2;print}'"
        r = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, encoding='utf-8')
        self.docker_image = r.stdout.strip()

    def fetch_input(self):
        if "input" in self.attributes:
            url = self.attributes['input']
            self.skesa_inputfile = os.path.basename(url)
            cmd = ["gsutil", "cp", "-r", url, self.work_dir]
            r = subprocess.run(cmd, stderr=subprocess.PIPE, check=True)
        elif "url" in self.attributes:
            url = self.attributes['url']
            self.skesa_inputfile = os.path.basename(url)
            cmd = [f"curl -L {url} > {skesa_inputfile}", self.work_dir]
            r = subprocess.run(cmd, shell=True, stderr=subprocess.PIPE, check=True)
        elif "sra_id" in self.attributes:
            self.skesa_inputfile = self.attributes['sra_id']
            self.has_sra_id = True
        self.inputfile = f"{self.skesa_inputfile}.skesa.fa"

    def fetch_blast_cache(self):
        if "blast_cache" in self.attributes and "taxgroup" in self.attributes:
            os.makedirs(self.blast_cache_dir, exist_ok=True)
            url = f"{self.attributes['blast_cache']}/blast_hits_cache-{self.attributes['taxgroup']}.{self.version}/*"
            cmd = ["gsutil", "cp", "-r", url, self.blast_cache_dir]
            try:
                r = subprocess.run(cmd, stderr=subprocess.PIPE, check=True)
                self.has_blast_cache = True
            except subprocess.CalledProcessError as err:
                print(f"Failed Command: {err.cmd}")
                print(f"Stderr: {err.stderr.decode('utf-8')}")
                self.has_blast_cache = False

    def write_uuid(self):
        cmd = f"uuidgen > {self.work_dir}/uuid.txt"
        subprocess.run(cmd, shell=True, stdout=sys.stdout, stderr=sys.stderr)

    def run_skesa(self):
        os.chdir(self.work_dir)

        if self.has_sra_id:
            opt = f"--sra_run "
        else:
            opt = f"--reads"

        cmd = f"docker run --rm ncbi/skesa:v2.3.0 skesa {opt} {self.skesa_inputfile} > {self.inputfile}"
        with open(f"{self.work_dir}/debug/cwltool.log", 'a') as cwllog:
            cwllog.write("Running SKESA command:\n" + cmd + "\n")
            r = subprocess.run(cmd, stderr=cwllog, stdout=sys.stdout, shell=True, check=True)

    def run_ani(self):
        os.chdir(self.work_dir)
        defaults = [
            "/usr/local/bin/cwltool",
            "--default-container", self.docker_image,
            "--timestamps",
            "--preserve-entire-environment",
            "--disable-color",
            "--outdir", "output"
        ]
        inputs = [
            f"{self.home_dir}/cwl_taxcheck/taxcheck.cwl", "input.yaml"
        ]
        debug_options = [
            "--tmpdir-prefix", "debug/ani-tmpdir/",
            "--leave-tmpdir",
            "--tmp-outdir-prefix", "debug/ani-tmp-outdir/",
            "--copy-outputs",
            "--debug"
        ]
        logging = [ "|& tee -a debug/cwltool.log | grep '^\[' >> /var/log/cwltool.log"]

        if self.debug:
            defaults += debug_options
        cmdlist = defaults + inputs + logging
        cmd = " ".join(cmdlist)

        with open(f"{self.work_dir}/debug/cwltool.log", 'a') as cwllog:
            cwllog.write("Running TAXCHECK command:\n" + cmd + "\n")
            r = subprocess.run(cmd, stderr=cwllog, stdout=sys.stdout, shell=True, check=True, env=os.environ)

    def run_cwl(self):
        os.chdir(self.work_dir)
        defaults = [
            "/usr/local/bin/cwltool",
            "--default-container", self.docker_image,
            "--timestamps",
            "--preserve-entire-environment",
            "--disable-color",
            "--outdir", "output"
        ]
        inputs = [
            f"{self.home_dir}/cwl_pgap/pgap.cwl", "input.yaml"
        ]
        debug_options = [
            "--tmpdir-prefix", "debug/pgap-tmpdir/",
            "--leave-tmpdir",
            "--tmp-outdir-prefix", "debug/pgap-tmp-outdir/",
            "--copy-outputs",
            "--debug"
        ]
        logging = [ "|& tee -a debug/cwltool.log | grep '^\[' >> /var/log/cwltool.log"]

        if self.debug:
            defaults += debug_options
        cmdlist = defaults + inputs + logging
        cmd = " ".join(cmdlist)

        with open(f"{self.work_dir}/debug/cwltool.log", 'a') as cwllog:
            cwllog.write("Running PGAP command:\n" + cmd + "\n")
            r = subprocess.run(cmd, stderr=cwllog, stdout=sys.stdout, shell=True, check=True, env=os.environ)

    def upload_results(self):
        tarlist = "output"
        if self.debug:
            os.rename(f"{self.inputfile}", f"debug/{self.inputfile}")
            os.rename("uuid.txt", "debug/uuid.txt")
            os.rename("input.yaml", "debug/input.yaml")
            os.rename("submol.yaml", "debug/submol.yaml")
            tarlist += " debug"
        tarfile = str(uuid.uuid4())
        cmd = f"tar cvzf {tarfile} {tarlist}"
        r = subprocess.run(cmd, shell=True, stdout=sys.stdout, stderr=sys.stderr)

        url = self.attributes['output']
        cmd = ["gsutil", "cp", "-r", tarfile, url]
        r = subprocess.run(cmd, stdout=sys.stdout, stderr=sys.stderr)

#@atexit.register
#def shutdown():
#    os.system("/usr/bin/sudo /usr/sbin/shutdown -h now")

def main():
    # Ensure we can write to log, while we are still root
    p = pathlib.Path('/var/log/cwltool.log')
    p.touch()
    p.chmod(0o666)

    # GCP startup scripts default to running as root
    # So let's change to the rapt user
    p = pwd.getpwnam('rapt')
    os.initgroups(p.pw_name, p.pw_gid)
    os.setgid(p.pw_gid)
    os.setuid(p.pw_uid)
    os.chdir(p.pw_dir)
    os.environ['HOME'] = p.pw_dir
    os.environ['NCBI_CONFIG__GENBANK__PREOPEN'] = 'false'

    # Run the pipeline
    rapt = rapt_control()

    if rapt.has_run():
        atexit.unregister(shutdown) # In this case, we don't want to kill the instance
        print("Work products exist, exiting startup script")
        sys.exit(0)

    try:
        rapt.setup()
        rapt.run_skesa()
        rapt.run_ani()
        #rapt.run_cwl()
    except subprocess.CalledProcessError as err:
        print(f"Failed Command: {err.cmd}, Returned: {err.returncode}")
        print(f"Stderr: {err.stderr.decode('utf-8')}")
    finally:
        rapt.upload_results()

# These functions are hidden down here because
# they contain giant strings and are ugly
# You're welcome

def write_submol(self):
    text = """contact_info:
    last_name: 'Doe'
    first_name: 'Jane'
    email: 'jane_doe@gmail.com'
    organization: 'Institute of Klebsiella foobarensis research'
    department: 'Department of Using NCBI'
    phone: '301-555-0245'
    street: '1234 Main St'
    city: 'Docker'
    postal_code: '12345'
    country: 'Lappland'
    
authors:
    - author:
        first_name: 'Arnold'
        last_name: 'Schwarzenegger'
        middle_initial: 'T'
    - author:
        first_name: 'Linda'
        last_name: 'Hamilton'
"""
    if "bioproject" in self.attributes:
        text = text + "bioproject: {self.attributes['bioproject']}\n"
    if "biosample" in self.attributes:
        text = text + "biosample: {self.attributes['biosample']}\n"
    if "topology" in self.attributes:
        text = text + "topology: {self.attributes['topology']}\n"
    if "genus_species" in self.attributes:
        text = text + f"""organism:
    genus_species: {self.attributes['genus_species']}
    strain: 'replaceme'
"""
    f = open(f"{self.work_dir}/submol.yaml", "w")
    f.write(text)
    f.close()

def write_input_yaml(self):
    text = f"""fasta:
    class: File
    location: {self.inputfile}
supplemental_data:
    class: Directory
    location: {self.input_dir}
submol:
    class: File
    location: submol.yaml
uuid_in:
    class: File
    location: uuid.txt
go:
    - true
contact_as_author_possible: false
ignore_all_errors: true
report_usage: true
"""
    if "taxid" in self.attributes:
        text = text + "taxid: {self.attributes['taxid']}\n"
    if self.has_blast_cache:
        text = text + f"""blast_hits_cache_data:
    class: Directory
    location: {self.blast_cache_dir}
"""
    f = open(f"{self.work_dir}/input.yaml", "w")
    f.write(text)
    f.close()


if __name__ == "__main__":
    # Add the two obscured functions to the class
    setattr(rapt_control, "write_submol", write_submol)
    setattr(rapt_control, "write_input_yaml", write_input_yaml)
    main()


