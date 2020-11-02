#!/usr/bin/env python
from __future__ import print_function
import sys
import os
import argparse
import subprocess
import uuid
import platform
from distutils.spawn import find_executable

##to be compatible with python2
from abc import ABCMeta, abstractmethod

IMAGE_URI="ncbi/rapt:v0.1.0"

RAPT_VERSION="rapt-28973346"

ACT_FUNC_TEST = 'functest'
ACT_VERSION = 'version'
FLG_SKESA_ONLY = 'skesa_only'
FLG_NO_REPORT = 'no_report'

##################################################################
#	Environment variable names used
##################################################################
ENV_RAPT_BUILD = 'rapt_build'	##rapt version
ENV_UUID = 'rapt_uuid'	##uuid, mainly for pgap log.
ENV_JOBID = 'rapt_jobid'	##jobid is related to uuid, but still receive from wrapper script so that we do not dup the algorithm that compute jobid from uuid
ENV_LOG = 'rapt_log'	##concise log location.

##actions. 
EVN_ACT = 'rapt_act'
ENV_OPTS = 'rapt_opts'

ENV_MEM_AVAIL = 'rapt_mem'
ENV_SRR = 'rapt_srr'
ENV_FASTQ = 'rapt_fastq'
ENV_GEN_SP = 'rapt_fastq_org'
ENV_STRAIN = 'rapt_fastq_strain'

ARGDEST_ACXN = 'acxn'
ARGDEST_FASTQ = 'fastq'
ARGDEST_ACT = 'act'
ARGDEST_ORGA = 'orga'
ARGDEST_STRAIN = 'strain'
ARGDEST_FLAGS = 'flags'
ARGDEST_OUTDIR = 'outdir'
ARGDEST_REFDATA = 'refdata_hub'
ARGDEST_JOBID = 'jobid'
ARGDEST_DOCKER = 'dockerbin'
ARGDEST_ITUSER = 'it_user'
ARGDEST_MAXMEM = 'maxmem'
ARGDEST_MAXCPU = 'maxcpu'

META_CURR_USR = '__curr_user__'

##################################################################
#	Mount points
##################################################################

REF_DATA_MOUNT = '/dkm_ref_data'
INPUT_MOUNT = '/dkm_input_dir'
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
	print(msg, file=sys.stderr, flush=True)

##my abstract class
class ContainerRunner(object):
	__metaclass__ = ABCMeta

	def __init__(self, args, parser):
		self.parser=parser
		self.envs=[]
		self.mounts=[]
		self.runmode=[]
		self.cmdltail=[]
		self.is_null=True
		self.rc = 0

		##option
		flags = get_arg(args, ARGDEST_FLAGS)
		if flags:
			self.add_env(ENV_OPTS, ':'.join(flags))

		action = get_arg(args, ARGDEST_ACT)
		if action:
			self.add_env(EVN_ACT, action)
			self.is_null=False
		else:
			acxn = get_arg(args, ARGDEST_ACXN)
			if acxn:
				self.add_env(ENV_SRR, acxn)
				self.is_null=False
			else:
				fastq = get_arg(args, ARGDEST_FASTQ)
				if fastq:
					if not os.path.exists(fastq):
						eprint('FASTQ input file {} does not exist.'.format(fastq))
						self.rc = 1
						return
					orga = get_arg(args, ARGDEST_ORGA)
					if not orga:
						eprint('For FASTQ input, \'--organism "<Genus specis>"\' is required')
						self.rc = 1
						return

					self.is_null=False
					absfastq = os.path.abspath(fastq)

					self.add_mount(os.path.dirname(absfastq), INPUT_MOUNT)
					self.add_env(ENV_FASTQ, os.path.basename(absfastq))
					self.add_env(ENV_GEN_SP, orga)

					strain = get_arg(args, ARGDEST_STRAIN)
					if strain:
						self.add_env(ENV_STRAIN, strain)

		curr_usr = get_ug_ids()
		itusr = get_arg(args, ARGDEST_ITUSER)
		if itusr:	##interactive mode
			if curr_usr:
				if 'root' == itusr:
					curr_usr = "0:0"
			self.is_null=False
		self.set_runmode(curr_usr, itusr is not None)

		maxmem = get_arg(args, ARGDEST_MAXMEM)
		if maxmem:
			self.set_maxmem(maxmem)
			self.add_env(ENV_MEM_AVAIL, maxmem)	##notify skesa as well

		maxcpu = get_arg(args, ARGDEST_MAXCPU)
		if maxcpu:
			self.set_maxcpus(maxcpu)

		run_uuid = get_uuid()
		jobid = uuid2jobid(run_uuid)

		usrtag = get_arg(args, ARGDEST_JOBID)
		if usrtag:
			jobid += '_' + usrtag

		self.add_env(ENV_UUID, run_uuid)
		self.add_env(ENV_JOBID, jobid)

		outdir = get_arg(args, ARGDEST_OUTDIR)

		if not outdir:
			outdir = os.getcwd()
		else:
			outdir = os.path.abspath(outdir)

		self.add_mount(outdir, OUTPUT_MOUNT)

		refdir = get_arg(args, ARGDEST_REFDATA)
		if refdir:
			refdir = os.path.abspath(refdir)
			self.add_mount(refdir, REF_DATA_MOUNT)

		self.add_env(ENV_RAPT_BUILD, RAPT_VERSION)
		self.add_env(ENV_LOG, 'concise.log')

	def run(self):
		if self.rc != 0:
			return self.rc
		elif self.is_null:
			eprint('No effective input')
			self.parser.print_help()
			return 1
		return self.run_container()

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
	def set_runmode(self, user, is_it=False):
		pass

	@abstractmethod
	def run_container(self):
		pass

class DockerCompatibleRunner(ContainerRunner):
	ENV_SWITCH = '-e'
	BIND_SWITCH = '-v'
	RUN_CMD = 'run'

	def __init__(self, args, parser):
		super(DockerCompatibleRunner, self).__init__(args, parser)

	def add_env(self, name, val):
		self.envs.extend([DockerCompatibleRunner.ENV_SWITCH, '{}={}'.format(name, val)])

	def add_mount(self, hpath, cpath):
		self.mounts.extend([DockerCompatibleRunner.BIND_SWITCH, '{}:{}'.format(hpath, cpath)])

	def set_maxmem(self, maxmem):
		self.runmode.extend(['--memory', maxmem + 'g'])

	def set_maxcpus(self, maxcpus):
		##if 'Windows' == platform.system()
		self.runmode.extend(['--cpu-count' if 'Windows' == platform.system() else '--cpus', maxcpus])

	def set_runmode(self, user, is_it=False):
		if is_it:
			self.runmode.extend(['-it'])
			self.cmdltail.append('/bin/bash')

	def run_container(self):
		cmdl=[type(self).RUN_BINARY, DockerCompatibleRunner.RUN_CMD]
		cmdl.extend(self.runmode)
		cmdl.extend(self.envs)
		cmdl.extend(self.mounts)
		cmdl.extend([IMAGE_URI])
		cmdl.extend(self.cmdltail)
		print('Running command:\n{}'.format(' '.join(cmdl)))
		return subprocess.call(cmdl)
		#print('{}'.format(' '.join(cmdl)))
		#return 0

class DockerRunner(DockerCompatibleRunner):
	RUN_BINARY = 'docker'
	def __init__(self, args, parser):
		super(DockerRunner, self).__init__(args, parser)

	def set_runmode(self, user, is_it=False):
		super(DockerRunner, self).set_runmode(user, is_it)
		if user and user != "0:0":
			self.runmode.extend(['-u', user])

class PodmanRunner(DockerCompatibleRunner):
	RUN_BINARY = 'podman'
	def __init__(self, args, parser):
		super(PodmanRunner, self).__init__(args, parser)

class SingularityRunner(ContainerRunner):
	##PULL_BINARY = 'sregistry'
	RUN_BINARY = 'singularity'
	ENV_SWITCH = 'SINGULARITYENV_'
	BIND_SWITCH = '--bind'
	RUN_CMD = 'run'
	RUN_CMD_IT = 'shell'

	def __init__(self, args, parser):
		super(SingularityRunner, self).__init__(args, parser)
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

	def set_runmode(self, user, is_it=False):
		if is_it:
			self.run_cmd = SingularityRunner.RUN_CMD_IT

	def run_container(self):
		##check if the image is in gcr -- need sregistry to retrieve it
		imgurl=''
		imgurl_parse = IMAGE_URI.split('/')

		##imgreg = imgurl_parse[0].split('.')

		if 'docker.io' == imgurl_parse[0]:		##omit the 'docker.io'
			imgurl = 'docker://' + '/'.join(imgurl_parse[1:])

		else:	##not omit non-docker io domains
			imgurl = 'docker://' + IMAGE_URI

		##make up environments
		sub_env = os.environ.copy()
		for e in self.envs:
			kv = e.split('=')
			sub_env[kv[0]] = kv[1]

		cmdl = [SingularityRunner.RUN_BINARY]
		cmdl.append(self.run_cmd)
		cmdl.extend(self.mounts)
		cmdl.append(imgurl)

		print('Running command:\n{} with environments {}'.format(' '.join(cmdl), ';'.join(self.envs)))

		subp = subprocess.Popen(cmdl, env=sub_env)
		subp.wait()

		return subp.returncode
		#
		#return 0

VALID_RUNNERS = [DockerRunner, PodmanRunner, SingularityRunner]

def find_docker_prog():
	for r in VALID_RUNNERS:
		p = r.RUN_BINARY
		ploc = find_executable(p)
		if ploc:
			return r, ploc
	return None, None

def main(args, parser):

	##must determine the container system first
	bin_name=None
	bin_path=None

	##bin_name = 'docker'
	##bin_path = '/usr/bin/docker'

	dockerbin = get_arg(args, ARGDEST_DOCKER)

	my_run_class=None
	if dockerbin:
		bin_name = os.path.basename(dockerbin)
		ploc = os.path.dirname(dockerbin)

		if ploc:	##not empty string
			if os.path.exists(dockerbin):
				bin_path = dockerbin
		else:
			bin_path = find_executable(bin_name)

	else:
		my_run_class, bin_path = find_docker_prog()

	if not bin_path:
		eprint('Cannot find docker compatible program {}'.format(bin_name))
		return 1

	if not my_run_class:
		bin_name = bin_name.split('.')[0].lower()

		for r in VALID_RUNNERS:
			if bin_name == r.RUN_BINARY:
				my_run_class = r
				break
		if not my_run_class:
			eprint('{} is not a supported container technology'.format(bin_name))
			return 1

	my_runner = my_run_class(args, parser)

	return my_runner.run()

if '__main__' == __name__:
	##prog=os.path.basename(__file__)

	parser = argparse.ArgumentParser(description='Read Assembly and Annotation Pipeline Tool (RAPT)')

	excl_1 = parser.add_mutually_exclusive_group(required=False)

	excl_1.add_argument('-a', '--submitacc', dest=ARGDEST_ACXN, help='Run RAPT against an SRA run accession.')

	excl_1.add_argument('-q', '--submitfastq', dest=ARGDEST_FASTQ, help='Run RAPT against sequences in a custom FASTQ formatted file.')

	excl_1.add_argument('-v', '--version', dest=ARGDEST_ACT, action='store_const', const=ACT_VERSION, help='Display version information')

	excl_1.add_argument('--test', dest=ARGDEST_ACT, action='store_const', const=ACT_FUNC_TEST, help='Run a set of internal tests.')

	parser.add_argument('--organism', dest=ARGDEST_ORGA, nargs='?', help='Specify the name (Genus<space>species) of the organism with which the sequences in the FASTQ file are associated, Required with \'-q\' command')

	parser.add_argument('--strain', dest=ARGDEST_STRAIN, help='Specify the strain of the organism')

	##flags
	parser.add_argument('--skesa-only', dest=ARGDEST_FLAGS, action='append_const', const=FLG_SKESA_ONLY, help='Run assembly part (skesa) only, do not run pgap')

	parser.add_argument('--no-usage-reporting', dest=ARGDEST_FLAGS, action='append_const', const=FLG_NO_REPORT, help='Do not send usage report back to NCBI.')

	parser.add_argument('-o', '--output-dir', dest=ARGDEST_OUTDIR, help='Directory to store results and logs. If omitted, use current directory')

	##general switches
	parser.add_argument('--refdata-dir', dest=ARGDEST_REFDATA, help='Specify a location to store reference data used by RAPT. If omitted, use output directory')

	parser.add_argument('-c', '--cpus', dest=ARGDEST_MAXCPU, help='Specify the maximal CPU cores the container should use.')

	parser.add_argument('-m', '--memory', dest=ARGDEST_MAXMEM, help='Specify the maximal memory (number in GB) the container should use.')

	parser.add_argument('--tag', dest=ARGDEST_JOBID, help='Specify a custom string to tag the job')

	parser.add_argument('-D', '--docker', dest=ARGDEST_DOCKER, choices=VALID_RUNNERS, help='Use specified docker compatible program to run RAPT image')

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

	args = parser.parse_args()

	sys.exit(main(args, parser))

