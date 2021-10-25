#!/usr/bin/env python
from __future__ import print_function
import sys
import os
import argparse
import subprocess
import uuid
import platform
import shutil
from distutils.spawn import find_executable

##to be compatible with python2
from abc import ABCMeta, abstractmethod

IMAGE_URI="ncbi/rapt:v0.4.2"

RAPT_VERSION="rapt-35244699"

DEFAULT_REF_DIR = '.rapt_refdata'

ACT_FUNC_TEST = 'functest'
ACT_VERSION = 'version'
FLG_SKESA_ONLY = 'skesa_only'
FLG_NO_REPORT = 'no_report'
FLG_STOP_ON_ERRORS = 'stop_on_errors'

CONCISE_LOG='concise.log'
VERBOSE_LOG='verbose.log'

RAPT_FLAVOR='raptdocker'

##################################################################
#    Environment variable names used
##################################################################
ENV_RAPT_NCBI_APP='rapt_ncbi_app'

ENV_UUID = 'rapt_uuid'    ##uuid, mainly for pgap log.
ENV_JOBID = 'rapt_jobid'    ##jobid is related to uuid, but still receive from wrapper script so that we do not dup the algorithm that compute jobid from uuid
ENV_LOG = 'rapt_log'    ##concise log location.
ENV_VLOG_DST = 'rapt_vlog_dst'    ##verbose log location. Different interpretation in GCP and non-GCP
##actions.
ENV_REFDATA_SRC = 'rapt_refsrc'
EVN_ACT = 'rapt_act'
ENV_OPTS = 'rapt_opts'

ENV_MEM_AVAIL = 'rapt_mem'
ENV_SRR = 'rapt_srr'
ENV_FASTQ = 'rapt_fastq'
ENV_FASTQ_FWD = 'rapt_fastq_fwd'
ENV_FASTQ_REV = 'rapt_fastq_rev'


ENV_GEN_SP = 'rapt_fastq_org'
ENV_STRAIN = 'rapt_fastq_strain'

# Entering pre-downloaded tarball mount path
ENV_PGAP_REF = 'pgap_ref'
ENV_ANI_REF = 'ani_ref'

ARGDEST_ACXN = 'acxn'
ARGDEST_FASTQ = 'fastq'
ARGDEST_ACT = 'act'
ARGDEST_ORGA = 'orga'
ARGDEST_STRAIN = 'strain'
ARGDEST_FLAGS = 'flags'
ARGDEST_OUTDIR = 'outdir'
ARGDEST_REFDATA = 'refdata_hub'
ARGDEST_PGAP_REF = 'pgap_ref'
ARGDEST_ANI_REF = 'ani_ref'
ARGDEST_DOCKER = 'dockerbin'
ARGDEST_ITUSER = 'it_user'
ARGDEST_MAXMEM = 'maxmem'
ARGDEST_MAXCPU = 'maxcpu'
ARGDEST_NETWORK = 'docker_network'

ARGDEST_DO_VERBOSE_STD = 'verbose_std'
META_CURR_USR = '__curr_user__'


##################################################################
#    Mount points
##################################################################

REF_DATA_MOUNT = '/dkm_ref_data'
INPUT_MOUNT = '/dkm_input_dir'
INPUT_MOUNT_PAIR = '/dkm_pair_input_dir'
OUTPUT_MOUNT = '/dkm_output_dir'

def get_arg(args, n):
    try:
        return args.__dict__[n]
    except:
        return None

def get_ug_ids(usr=None):
    try:
        return '{}:{}'.format(os.getuid(), os.getgid())
    except:
        return None

def get_uuid():
    return str(uuid.uuid1())

def uuid2jobid(__uuid):
    return ''.join(__uuid.split('-'))[1:11]

def eprint(msg):
    print(msg, file=sys.stderr)

##my abstract class
class ContainerRunner(object):
    __metaclass__ = ABCMeta

    def __init__(self, bin_path, args, parser):
        self.bin_path=bin_path
        self.parser=parser
        self.envs=[]
        self.mounts=[]
        self.runmode=[]
        self.cmdltail=[]
        self.is_null=True
        self.is_version=False
        ##used to suppress stdout and stderr
        self.verbose_out=False
        self.std_out=None
        self.std_err=None
        self.rc = 0


        ##internal use
        self.add_env(ENV_RAPT_NCBI_APP, RAPT_FLAVOR)  # applog rapt flavor
        self.add_env(ENV_REFDATA_SRC, 's3')  # explicit: download refdata from gcs
        self.verbose_out = get_arg(args, ARGDEST_DO_VERBOSE_STD)
        if not self.verbose_out:
            ##The lengthy output to console are all on stderr, by the stream handler of python logger. We leave stdout open in case we need to output some message from inside the image.
            ##Stream handler is necessary for RAPT-GCP
            ##self.std_out = open(os.devnull, 'w')
            # self.std_err = open(os.devnull, 'w')
            self.std_err = subprocess.PIPE
        ##option
        flags = get_arg(args, ARGDEST_FLAGS)
        if flags:
            self.add_env(ENV_OPTS, ':'.join(flags))

        action = get_arg(args, ARGDEST_ACT)
        if action:
            self.add_env(EVN_ACT, action)
            self.is_null=False
            if action == ACT_VERSION:
                self.is_version=True
        else:
            acxn = get_arg(args, ARGDEST_ACXN)
            if acxn:
                self.add_env(ENV_SRR, acxn)
                self.is_null=False
            else:
                fastq = get_arg(args, ARGDEST_FASTQ)
                if fastq:
                    # added to handle two paird files: /path/to/file_1,/path/to/file_2
                    fq_files = fastq.split(',')
                    nfiles = len(fq_files)

                    # if path contains ~, must expand
                    pathparse = fq_files[0].split(os.sep)
                    if '~' == pathparse[0][0:1]:
                        # if user does not exist, it returns the original string(treat ~ as literal)
                        pathparse[0] = os.path.expanduser(pathparse[0])
                        fq_files[0] = os.sep.join(pathparse)

                    if not os.path.exists(fq_files[0]):
                        eprint('FASTQ input file {} does not exist.'.format(fq_files[0]))
                        self.rc = 1
                        return

                    absfastq = os.path.abspath(fq_files[0])
                    fq_path = os.path.dirname(absfastq)

                    self.add_mount(fq_path, INPUT_MOUNT)
                    fq_files[0] = os.path.join(INPUT_MOUNT, os.path.basename(fq_files[0]))

                    # handle paired file
                    if nfiles > 1:
                        fq_pair_path = os.path.dirname(fq_files[1])

                        pair_basename = os.path.basename(fq_files[1])

                        # if no path in the second file, try the same path first
                        if not fq_pair_path:
                            abspair_path = os.path.join(fq_path, pair_basename)
                            if os.path.exists(abspair_path):
                                fq_files[1] = abspair_path
                            else:
                                abspair_path = os.path.abspath(fq_files[1])
                        else:  # has path
                            pathparse = fq_files[1].split(os.sep)
                            if '~' == pathparse[0][0:1]:
                                # if user does not exist, it returns the original string(treat ~ as literal)
                                pathparse[0] = os.path.expanduser(pathparse[0])
                                fq_files[1] = os.sep.join(pathparse)

                            abspair_path = os.path.abspath(fq_files[1])

                        if not os.path.exists(abspair_path):
                            eprint('FASTQ input file {} does not exist.'.format(fq_files[1]))
                            self.rc = 1
                            return
                        fq_pair_path = os.path.dirname(abspair_path)

                        if fq_pair_path != fq_path:
                            self.add_mount(fq_pair_path, INPUT_MOUNT_PAIR)
                            fq_files[1] = os.path.join(INPUT_MOUNT_PAIR, pair_basename)
                        else:
                            fq_files[1] = os.path.join(INPUT_MOUNT, pair_basename)
                        self.add_env(ENV_FASTQ_FWD, fq_files[0])
                        self.add_env(ENV_FASTQ_REV, fq_files[1])
                    else:  # single file
                        self.add_env(ENV_FASTQ, fq_files[0])

                    orga = get_arg(args, ARGDEST_ORGA)
                    if not orga:
                        eprint('For FASTQ input, \'--organism "<Genus specis>"\' is required')
                        self.rc = 1
                        return

                    self.is_null=False
                    self.add_env(ENV_GEN_SP, orga)

                    strain = get_arg(args, ARGDEST_STRAIN)
                    if strain:
                        self.add_env(ENV_STRAIN, strain)

        curr_usr = get_ug_ids()
        itusr = get_arg(args, ARGDEST_ITUSER)
        if itusr:    ##interactive mode
            if curr_usr:
                if 'root' == itusr:
                    curr_usr = "0:0"
            self.is_null=False
        self.set_runmode(curr_usr, itusr is not None)

        maxmem = get_arg(args, ARGDEST_MAXMEM)
        if maxmem:
            self.set_maxmem(maxmem)
            self.add_env(ENV_MEM_AVAIL, maxmem)    ##notify skesa as well

        maxcpu = get_arg(args, ARGDEST_MAXCPU)
        if maxcpu:
            self.set_maxcpus(maxcpu)

        dk_network = get_arg(args, ARGDEST_NETWORK)
        if dk_network:
            self.set_network(dk_network)

        run_uuid = get_uuid()
        jobid = uuid2jobid(run_uuid)

        self.add_env(ENV_UUID, run_uuid)
        self.add_env(ENV_JOBID, jobid)

        if not self.is_version:  # only create output directory when action is not version
            outdir = get_arg(args, ARGDEST_OUTDIR)

            if not outdir:  # If user did not specify, we create one.
                outdir = os.path.join(os.getcwd(), 'raptout_{}'.format(jobid))
            outdir = os.path.abspath(outdir)
            ##for python2 compatibility
            if os.path.exists(outdir):
                shutil.rmtree(outdir)  # clear old data
            try:
                os.makedirs(outdir, 0o755)
            except Exception as e:
                eprint('Unable to create output directory {}: {}'.format(outdir, e))
                self.rc = 1
                return

            self.add_mount(outdir, OUTPUT_MOUNT)
            self.prog_msg = 'RAPT is now running, it may take a long time to finish. To see the progress, track the verbose log file {}/{}.'.format(outdir, VERBOSE_LOG)

        # Support using pre-downloaded refdata tarball, but no way to match pgap build, assume user get it right.
        abs_predl_dir = None
        mount_point = '/predl_dir'

        pgap_ref = get_arg(args, ARGDEST_PGAP_REF)
        if pgap_ref:
            abs_predl_pgap = os.path.abspath(pgap_ref)
            abs_predl_dir = os.path.dirname(abs_predl_pgap)
            self.add_mount(abs_predl_dir, mount_point)
            self.add_env(ENV_PGAP_REF, os.path.join(mount_point, os.path.basename(abs_predl_pgap)))

        ani_ref = get_arg(args, ARGDEST_ANI_REF)
        if ani_ref:
            asb_predl_ani = os.path.abspath(ani_ref)
            abs_predl_ani_dir = os.path.dirname(asb_predl_ani)
            if abs_predl_ani_dir != abs_predl_dir:  # different dir, need mount
                mount_point = '/predl_ani_dir'
                self.add_mount(abs_predl_ani_dir, mount_point)

            self.add_env(ENV_ANI_REF, os.path.join(mount_point, os.path.basename(asb_predl_ani)))

        refdir = get_arg(args, ARGDEST_REFDATA)
        if not refdir:
            refdir = os.path.join(os.getcwd(), DEFAULT_REF_DIR)

        refdir = os.path.abspath(refdir)
        if not os.path.exists(refdir):
            try:
                os.makedirs(refdir, 0o755)
            except Exception as e:
                eprint('Unable to create reference data directory {}: {}'.format(refdir, e))
                self.rc = 1
                return

        self.add_mount(refdir, REF_DATA_MOUNT)

        ##we do not need to specify log files anymore, they are always created inside the output dir.

    def run(self):

        if self.rc != 0:
            return self.rc
        elif self.is_null:
            eprint('No effective input')
            self.parser.print_help()
            return 1
        if not self.verbose_out and not self.is_version:
            print(self.prog_msg)
        subp = self.run_container()
        subp_std = subp.communicate()

        if 0 != subp.returncode and self.std_err:  # we have suppressed stdderr
            err_msgs = subp_std[1]
            try:  # try python3 first
                err_msgs = err_msgs.decode('utf-8')
            except Exception:  # assume python 2
                pass
            if err_msgs:
                err_msgs = err_msgs.split('\n')
                total_lines = len(err_msgs)
                if total_lines > 10:
                    err_msgs = err_msgs[-10:]

                for m in err_msgs:
                    eprint(m)
        return subp.returncode


    @abstractmethod
    def add_env(self, name, val):
        pass

    @abstractmethod
    def add_mount(self, hpath, cpath):
        pass

    @abstractmethod
    def set_maxmem(self, maxmem):
        pass

    @abstractmethod
    def set_maxcpus(self, maxcpus):
        pass

    @abstractmethod
    def set_network(self, network):
        pass

    @abstractmethod
    def set_runmode(self, user, is_it=False):
        pass

    @abstractmethod
    def run_container(self):
        pass

class DockerCompatibleRunner(ContainerRunner):
    ENV_SWITCH = '-e'
    BIND_SWITCH = '-v'
    RUN_CMD = 'run'

    def __init__(self, bin_path, args, parser):
        super(DockerCompatibleRunner, self).__init__(bin_path, args, parser)
        self.clean_up = '--rm'

    def add_env(self, name, val):
        self.envs.extend([DockerCompatibleRunner.ENV_SWITCH, '{}={}'.format(name, val)])

    def add_mount(self, hpath, cpath):
        self.mounts.extend([DockerCompatibleRunner.BIND_SWITCH, '{}:{}'.format(hpath, cpath)])

    def set_maxmem(self, maxmem):
        self.runmode.extend(['--memory', maxmem + 'g'])

    def set_maxcpus(self, maxcpus):
        ##if 'Windows' == platform.system()
        self.runmode.extend(['--cpu-count' if 'Windows' == platform.system() else '--cpus', maxcpus])

    def set_network(self, network):
        self.runmode.extend(['--network', network])

    def set_runmode(self, user, is_it=False):
        if is_it:
            self.clean_up = None
            self.runmode.extend(['-it'])
            self.cmdltail.append('/bin/bash')

    def run_container(self):
        cmdl=[self.bin_path, DockerCompatibleRunner.RUN_CMD]
        if self.clean_up:
            cmdl.append(self.clean_up)
        cmdl.extend(self.runmode)
        cmdl.extend(self.envs)
        cmdl.extend(self.mounts)
        cmdl.extend([IMAGE_URI])
        cmdl.extend(self.cmdltail)
        ##print('Running command:\n{}'.format(' '.join(cmdl)))
        subp = subprocess.Popen(cmdl, stdout=self.std_out, stderr=self.std_err)
        # subp.wait()
        return subp
        # return subprocess.call(cmdl, stdout=self.std_out, stderr=self.std_err)

class DockerRunner(DockerCompatibleRunner):
    RUN_BINARY = 'docker'
    def __init__(self, bin_path, args, parser):
        super(DockerRunner, self).__init__(bin_path, args, parser)
        # test run docker, see if it is accessible
        test_run = subprocess.Popen([bin_path, 'info'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        test_run.wait()
        if test_run.returncode != 0:
            eprint('===============================================\nIt seems the docker daemon is not running. Try to start the docker service\n(by running "sudo systemctl start docker" or "sudo service docker start"\ndepends on your system) and add your user id to the docker group (by running\n"sudo usermod -a -G docker $USER"), then log out and log back in. If you do not\nhave superuser privilege, ask your system admins for help. \n===============================================')
            eprint('Error message:\n{}'.format(test_run.stdout.read().decode('utf-8')))
            self.rc = 1


    def set_runmode(self, user, is_it=False):
        super(DockerRunner, self).set_runmode(user, is_it)
        if user and user != "0:0":
            self.runmode.extend(['-u', user])

class PodmanRunner(DockerCompatibleRunner):
    RUN_BINARY = 'podman'
    def __init__(self, bin_path, args, parser):
        super(PodmanRunner, self).__init__(bin_path, args, parser)

class SingularityRunner(ContainerRunner):
    ##PULL_BINARY = 'sregistry'
    RUN_BINARY = 'singularity'
    ENV_SWITCH = 'SINGULARITYENV_'
    BIND_SWITCH = '--bind'
    RUN_CMD = 'run'
    RUN_CMD_IT = 'shell'

    def __init__(self, bin_path, args, parser):
        super(SingularityRunner, self).__init__(bin_path, args, parser)
        self.run_cmd=SingularityRunner.RUN_CMD

    def add_env(self, name, val):
        self.envs.extend(['{}{}={}'.format(SingularityRunner.ENV_SWITCH, name, val)])

    def add_mount(self, hpath, cpath):
        self.mounts.extend([SingularityRunner.BIND_SWITCH, '{}:{}'.format(hpath, cpath)])
    ##dummy -- singularity does not support run-time resource limit
    def set_maxmem(self, maxmem):
        pass

    def set_maxcpus(self, maxcpus):
        pass

    def set_network(self, network):
        self.runmode.extend(['--net', '--network', network])

    def set_runmode(self, user, is_it=False):
        if is_it:
            self.run_cmd = SingularityRunner.RUN_CMD_IT

    def run_container(self):
        ##check if the image is in gcr -- need sregistry to retrieve it
        imgurl=''
        imgurl_parse = IMAGE_URI.split('/')

        ##imgreg = imgurl_parse[0].split('.')

        if 'docker.io' == imgurl_parse[0]:        ##omit the 'docker.io'
            imgurl = 'docker://' + '/'.join(imgurl_parse[1:])

        else:    ##not omit non-docker io domains
            imgurl = 'docker://' + IMAGE_URI

        ##make up environments
        sub_env = os.environ.copy()
        for e in self.envs:
            kv = e.split('=')
            sub_env[kv[0]] = kv[1]

        cmdl = [self.bin_path]
        cmdl.append(self.run_cmd)
        cmdl.extend(self.mounts)
        cmdl.append(imgurl)

        subp = subprocess.Popen(cmdl, env=sub_env, stdout=self.std_out, stderr=self.std_err)
        # subp.wait()

        return subp
        #
        #return 0

VALID_RUNNERS = [DockerRunner, PodmanRunner, SingularityRunner]

def find_docker_prog():
    for r in VALID_RUNNERS:
        p = r.RUN_BINARY
        ploc = find_executable(p)
        if ploc:
            return ploc
    return None

def detect_real_prog(ploc):
    ##some may disguise other as docker, so run with --version command and parse output
    tproc = subprocess.Popen([ploc, '--version'], stdout=subprocess.PIPE)
    tproc.wait()

    real_prog = tproc.stdout.read().decode('utf-8').split()[0].lower()

    for r in VALID_RUNNERS:
        if real_prog.startswith(r.RUN_BINARY):
            return r

    eprint('WARNING: {} support as {} alternative has not been tested'.format(real_prog, DockerRunner.RUN_BINARY))

    return DockerRunner


def main(args, parser):

    ##must determine the container system first
    bin_path=None

    bin_name=None

    dockerbin = get_arg(args, ARGDEST_DOCKER)

    if dockerbin:
        bin_name = os.path.basename(dockerbin)
        ploc = os.path.dirname(dockerbin)

        if ploc:    ##not empty string
            if os.path.exists(dockerbin):
                bin_path = dockerbin
        else:
            bin_path = find_executable(bin_name)

    else:
        bin_path = find_docker_prog()

    if not bin_path:
        msg='Cannot find docker compatible program'
        if bin_name:
            msg+=' {}'.format(bin_name)
        eprint(msg)
        return 1


    my_run_class = detect_real_prog(bin_path)
    my_runner = my_run_class(bin_path, args, parser)

    return my_runner.run()

if '__main__' == __name__:
    ##prog=os.path.basename(__file__)

    parser = argparse.ArgumentParser(description='Read Assembly and Annotation Pipeline Tool (RAPT)')

    excl_1 = parser.add_mutually_exclusive_group(required=False)

    excl_1.add_argument('-a', '--submitacc', dest=ARGDEST_ACXN, help='Run RAPT on an SRA run accession (sra_acxn).')

    excl_1.add_argument('-q', '--submitfastq', dest=ARGDEST_FASTQ, help='Run RAPT on Illumina reads in FASTQ or FASTA format. The file must be readable from the computer that runs RAPT. If forward and reverse readings are in two separate files, specify as "path/to/forward.fastq,path/to/reverse.fastq", or "path/to/forward.fastq,reverse.fastq" if they are in the same directory. The --organism argument is mandatory for this type of input, while the --strain argument is optional.')

    excl_1.add_argument('-v', '--version', dest=ARGDEST_ACT, action='store_const', const=ACT_VERSION, help='Display the current RAPT version')

    excl_1.add_argument('--test', dest=ARGDEST_ACT, action='store_const', const=ACT_FUNC_TEST, help='Run a test suite. When RAPT does not produce the expected results, it may be     helpful to use this command to ensure RAPT is functioning normally.')

    parser.add_argument('--organism', dest=ARGDEST_ORGA, help='Specify the binomial name or, if the species is unknown, the genus for the sequenced organism. This identifier must be valid in NCBI Taxonomy.')

    parser.add_argument('--strain', dest=ARGDEST_STRAIN, help='Specify the strain of the organism')

    ##flags
    parser.add_argument('--skesa-only', dest=ARGDEST_FLAGS, action='append_const', const=FLG_SKESA_ONLY, help='Only assemble sequences to contigs, but do not annotate.')

    parser.add_argument('--no-usage-reporting', dest=ARGDEST_FLAGS, action='append_const', const=FLG_NO_REPORT, help='Prevents usage report back to NCBI. By default, RAPT sends usage information back to NCBI for statistical analysis. The information collected are a unique identifier for the RAPT process, the machine IP address, the start and end time of RAPT, and its three modules: SKESA, taxcheck and PGAP. No personal or project-specific information (such as the input data) are collected')

    parser.add_argument('--stop-on-errors', dest=ARGDEST_FLAGS, action='append_const', const=FLG_STOP_ON_ERRORS, help='Do not run PGAP annotation pipeline when the genome sequence is misassigned or contaminated')

    parser.add_argument('-o', '--output-dir', dest=ARGDEST_OUTDIR, help='Directory to store results and logs. If omitted, use current directory')

    ##general switches
    parser.add_argument('--refdata-dir', dest=ARGDEST_REFDATA, help='Specify a location to store reference data used by RAPT. If omitted, use output directory')

    parser.add_argument('--pgap-ref', dest=ARGDEST_PGAP_REF, help='Full path to pre-downloaded PGAP reference data tarball, if applicable. File is usually named like input-<PGAP-BUILD>.prod.tgz')

    parser.add_argument('--ani-ref', dest=ARGDEST_ANI_REF, help='Full path to pre-downloaded ANI reference data tarball, if applicable. File is usually named like input-<PGAP-BUILD>.prod.ani.tgz')

    parser.add_argument('-c', '--cpus', dest=ARGDEST_MAXCPU, help='Specify the maximal CPU cores the container should use.')

    parser.add_argument('-m', '--memory', dest=ARGDEST_MAXMEM, help='Specify the maximal memory (number in GB) the container should use.')

    parser.add_argument('-D', '--docker', dest=ARGDEST_DOCKER, choices=[r.RUN_BINARY for r in VALID_RUNNERS], help='Use specified docker compatible program to run RAPT image')

    parser.add_argument('-n', '--network', dest=ARGDEST_NETWORK, help='Specify the network the container should use. Note: this parameter is passed directly to the --network parameter to the container. RAPT does not check the validity of the argument.')

    ##special action for -it
    class ItAct(argparse.Action):
        def __init__(self, option_strings, dest, nargs=None, const=None, default=None, type=None, choices=None, required=False, help=None, metavar=None):
            super(ItAct, self).__init__(option_strings, dest, nargs, const, default, type, choices, required, help, metavar)

        def __call__(self, parser, ns, values, option_string=None):
            if values:
                setattr(ns, self.dest, values)
            else:
                setattr(ns, self.dest, META_CURR_USR)
    ##internal debug use, will delete in real release
    parser.add_argument('-it', dest=ARGDEST_ITUSER, nargs='?', action=ItAct, help=argparse.SUPPRESS)
    parser.add_argument('--do-verbose-std', dest=ARGDEST_DO_VERBOSE_STD, action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()

    sys.exit(main(args, parser))

