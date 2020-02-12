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

class pgap_control:

    def __init__(self):
        self.home_dir = os.path.expanduser('~pgap')
        self.work_dir = f"{self.home_dir}/work"
        self.debug_dir = f"{self.work_dir}/debug"
        self.blast_cache_dir = f"{self.home_dir}/blast_hits_cache"
        self.headers = { 'Metadata-Flavor' : 'Google' }
        self.url = "http://metadata/computeMetadata/v1/instance/"
        self.debug = False
        self.has_blast_cache = False

    def has_run(self):
        return os.path.exists(self.work_dir)

    def setup(self):
        os.makedirs(self.debug_dir, exist_ok=True)
        self.get_metadata()
        self.get_version()
        self.get_dockerimage()
        self.fetch_input()
        self.fetch_blast_cache()
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
        url = self.attributes['input']
        self.inputfile = os.path.basename(url)
        cmd = ["gsutil", "cp", "-r", url, self.work_dir]
        r = subprocess.run(cmd, stderr=subprocess.PIPE, check=True)

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
            f"{self.home_dir}/cwl/wf_common.cwl", "input.yaml"
        ]
        debug_options = [
            "--tmpdir-prefix", "debug/tmpdir/",
            "--leave-tmpdir",
            "--tmp-outdir-prefix", "debug/tmp-outdir/",
            "--copy-outputs",
            "--debug"
        ]
        logging = [ "|& tee debug/cwltool.log | grep '^\[' > /var/log/cwltool.log"]

        if self.debug:
            defaults += debug_options
        cmdlist = defaults + inputs + logging
        cmd = " ".join(cmdlist)

        print(cmd)
        r = subprocess.run(cmd, stdout=sys.stdout, shell=True, check=True, env=os.environ)

    def upload_results(self):
        tarlist = "output"
        if self.debug:
            os.rename("input.yaml", "debug/input.yaml")
            os.rename("submol.json", "debug/submol.json")
            tarlist += " debug"
        tarfile = str(uuid.uuid4())
        cmd = f"tar cvzf {tarfile} {tarlist}"
        r = subprocess.run(cmd, shell=True, stdout=sys.stdout, stderr=sys.stderr)

        url = self.attributes['output']
        cmd = ["gsutil", "cp", "-r", tarfile, url]
        r = subprocess.run(cmd, stdout=sys.stdout, stderr=sys.stderr)

@atexit.register
def shutdown():
    os.system("/usr/bin/sudo /usr/sbin/shutdown -h now")

def main():
    # Ensure we can write to log, while we are still root
    p = pathlib.Path('/var/log/cwltool.log')
    p.touch()
    p.chmod(0o666)

    # GCP startup scripts default to running as root
    # So let's change to the pgap user
    p = pwd.getpwnam('pgap')
    os.initgroups(p.pw_name, p.pw_gid)
    os.setgid(p.pw_gid)
    os.setuid(p.pw_uid)
    os.chdir(p.pw_dir)
    os.environ['HOME'] = p.pw_dir
    os.environ['NCBI_CONFIG__GENBANK__PREOPEN'] = 'false'

    # Run the pipeline
    pgap = pgap_control()

    if pgap.has_run():
        atexit.unregister(shutdown) # In this case, we don't want to kill the instance
        print("Work products exist, exiting startup script")
        sys.exit(0)

    try:
        pgap.setup()
        pgap.run_cwl()
    except subprocess.CalledProcessError as err:
        print(f"Failed Command: {err.cmd}, Returned: {err.returncode}")
        print(f"Stderr: {err.stderr.decode('utf-8')}")
    finally:
        pgap.upload_results()

# These functions are hidden down here because
# they contain giant strings and are ugly
# You're welcome

def write_submol(self):
    text = """{
   "authors" : [
      {
         "author" : {
            "middle_initial" : "T",
            "last_name" : "Schwarzenegger",
            "first_name" : "Arnold"
         }
      },
      {
         "author" : {
            "last_name" : "Hamilton",
            "first_name" : "Linda"
         }
      }
   ],
   "contact_info" : {
      "country" : "Lappland",
      "department" : "Department of Using NCBI",
      "street" : "1234 Main St",
      "phone" : "301-555-0245",
      "last_name" : "Doe",
      "email" : "jane_doe@gmail.com",
      "city" : "Docker",
      "postal_code" : "12345",
      "organization" : "NCBI",
      "first_name" : "Jane"
   }
}
"""
    f = open(f"{self.work_dir}/submol.json", "w")
    f.write(text)
    f.close()

def write_input_yaml(self):
    blast_cache=""
    if self.has_blast_cache:
        blast_cache=f"""blast_hits_cache_data:
    class: Directory
    location: {self.blast_cache_dir}
"""
    text = f"""entries:
    class: File
    location: {self.inputfile}
taxid: {self.attributes['taxid']}
gc_assm_name: {self.attributes['accession']}
supplemental_data:
    class: Directory
    location: {self.input_dir}
submol_block_json:
    class: File
    location: submol.json
go:
    - true
contact_as_author_possible: false
ignore_all_errors: true
report_usage: false
{blast_cache}
xpath_fail_initial_asndisc: >
    //*[@severity="FATAL"
        and not(contains(@name, "CITSUBAFFIL_CONFLICT"))
    ]
xpath_fail_initial_asnvalidate: >
    //*[( @severity="ERROR" or @severity="REJECT" )
        and not(contains(@code, "GENERIC_MissingPubRequirement"))
        and not(contains(@code, "SEQ_DESCR_BacteriaMissingSourceQualifier"))
        and not(contains(@code, "SEQ_DESCR_ChromosomeLocation"))
        and not(contains(@code, "SEQ_DESCR_MissingLineage"))
        and not(contains(@code, "SEQ_DESCR_NoTaxonID"))
        and not(contains(@code, "SEQ_DESCR_UnwantedCompleteFlag"))
        and not(contains(@code, "SEQ_FEAT_ShortIntron"))
        and not(contains(@code, "SEQ_INST_InternalNsInSeqRaw"))
        and not(contains(@code, "SEQ_INST_ProteinsHaveGeneralID"))
        and not(contains(@code, "SEQ_PKG_ComponentMissingTitle"))
        and not(contains(@code, "SEQ_PKG_NucProtProblem"))
    ]
xpath_fail_final_asndisc: >
    //*[@severity="FATAL"
        and not(contains(@name, "CITSUBAFFIL_CONFLICT"))
    ]
xpath_fail_final_asnvalidate: >
    //*[( @severity="ERROR" or @severity="REJECT" )
        and not(contains(@code, "GENERIC_MissingPubRequirement"))
        and not(contains(@code, "SEQ_DESCR_BacteriaMissingSourceQualifier"))
        and not(contains(@code, "SEQ_DESCR_ChromosomeLocation"))
        and not(contains(@code, "SEQ_DESCR_MissingLineage"))
        and not(contains(@code, "SEQ_DESCR_NoTaxonID"))
        and not(contains(@code, "SEQ_DESCR_UnwantedCompleteFlag"))
        and not(contains(@code, "SEQ_FEAT_ShortIntron"))
        and not(contains(@code, "SEQ_INST_InternalNsInSeqRaw"))
        and not(contains(@code, "SEQ_INST_ProteinsHaveGeneralID"))
        and not(contains(@code, "SEQ_PKG_ComponentMissingTitle"))
        and not(contains(@code, "SEQ_PKG_NucProtProblem"))
    ]
"""
    f = open(f"{self.work_dir}/input.yaml", "w")
    f.write(text)
    f.close()


if __name__ == "__main__":
    # Add the two obscured functions to the class
    setattr(pgap_control, "write_submol", write_submol)
    setattr(pgap_control, "write_input_yaml", write_input_yaml)
    main()


