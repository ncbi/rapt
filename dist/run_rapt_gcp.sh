#!/usr/bin/env bash

###############################* Global Constants *##################################
IMAGE_URI="ncbi/rapt:v1.2.3"
RAPT_VERSION="rapt-30372431"

GCP_LOGS_VIEWER="https://console.cloud.google.com/logs/viewer"

DEFAULT_VM="n1-highmem-16"
DEFAULT_BDISKSIZE=128
DEFAULT_FORMAT=table
DEFAULT_JOB_TIMEOUT="86400s"	##24 hours
DEFAULT_REGION="us-east4"
DEFAULT_LOCATION="us-central1"
##subcommands
CMD_ACXN=submitacc
CMD_FASTQ=submitfastq
CMD_JOBLST=joblist
CMD_JOBDET=jobdetails
CMD_CANCEL=cancel
CMD_TEST=test
CMD_VER=version
CMD_HELP=help

OPT_ORG="--organism"
OPT_STRAIN="--strain"

#general options
OPT_BUCKET="-b"
OPT_BUCKET_L="--bucket"
OPT_LABEL="--label"
OPT_VMTYPE="--machine-type"
OPT_BDSIZE="--boot-disk-size"
OPT_MAXLST="-n"
OPT_MAXLST_L="--limit"
OPT_PROJECT="--project"
##OPT_LOCATION="--location"
OPT_REGIONS="--regions"
OPT_DELIM="-d"
OPT_DELIM_L="--delimiter"
OPT_JOBTIMEOUT="--timeout"

##flags
FLG_SKESA_ONLY="--skesa-only"
FLG_NOREPORT="--no-usage-reporting"
FLG_USE_CSV="--csv"

####################################### Utilities ####################################

script_name=$(basename "$0")

GCLOUD=gcloud

err()
{
	printf "Error: %s\n" "$*" 1>&2
}

errexit()
{
	err "$*"
	exit 1
}

usage()
{
	cat << EOF

Usage: ${script_name}  <command>  [options]

Job creation commands:

	${CMD_ACXN} <sra_acxn> <${OPT_BUCKET}|${OPT_BUCKET_L} URL> [${OPT_LABEL} LABEL]
		[${FLG_SKESA_ONLY}] [${FLG_NOREPORT}] [${OPT_VMTYPE} TYPE] [${OPT_BDSIZE} NUM]
		[${OPT_JOBTIMEOUT} SECONDS]

		Submit a job to run RAPT on an SRA run accession (sra_acxn).

	${CMD_FASTQ} <fastq_uri> <${OPT_ORG} "Genus species"> [${OPT_STRAIN} "ATCC xxxx"]
		<${OPT_BUCKET}|${OPT_BUCKET_L} URL> [${OPT_LABEL} LABEL] [${FLG_SKESA_ONLY}]
		[${FLG_NOREPORT}] [${OPT_VMTYPE} TYPE] [${OPT_BDSIZE} NUM]
		[${OPT_JOBTIMEOUT} SECONDS]

		Submit a job to run RAPT on Illumina reads in FASTQ or FASTA format.
		fastq_uri is expected to point to a google cloud storage (bucket).

		The ${OPT_ORG} argument is mandatory. It is the binomial name or, if the
		species is unknown, the genus for the sequenced organism. This identifier
		must be valid in NCBI Taxonomy. The ${OPT_STRAIN} argument is optional.

	${CMD_TEST} <${OPT_BUCKET}|${OPT_BUCKET_L}> [${OPT_LABEL} LABEL] [${FLG_SKESA_ONLY}]
		[${FLG_NOREPORT}]

		Run a test suite. When RAPT does not produce the expected results, it may be 
		helpful to use this command to ensure RAPT is functioning normally.

		Common options:
		======================
		${OPT_BUCKET}|${OPT_BUCKET_L} URL

			Mandatory. Specify the destination storage location to store results
			and job logs.

		${OPT_LABEL} LABEL

			Optional. Tag the job with a custom label, which can be used to filter jobs
			with the joblist command. Google cloud platform requires that the label can
			only contain lower case letters, numbers and dash (-). Dot and white spaces
			are not allowed.

		${FLG_SKESA_ONLY}

			Optional. Only assemble sequences to contigs, but do not annotate.

		${FLG_NOREPORT}

			Optional. Prevents usage report back to NCBI. By default, RAPT sends usage  
			information	back to NCBI for statistical analysis. The information collected
			are a unique identifier for the RAPT process, the machine IP address, the
			start and end time of RAPT, and its three modules: SKESA, taxcheck and PGAP.
			No personal or project-specific information (such as the input data) are
			collected.

		${OPT_REGIONS}

			Optional, comma-separated. Specify in which GCP region(s) RAPT should run.
			Note: it should be regions in which you have sufficient CPU quotas (verify
			at https://console.cloud.google.com/iam-admin/quotas/details). Default is
			a single region, us-east4.

		${OPT_VMTYPE} TYPE

			Optional. Specify the type of google cloud virtual machine to run this job
			(see Google documentation, https://cloud.google.com/compute/docs/machine-types).
			Default is "n1-highmem-16", which is suitable for most jobs.

		${OPT_BDSIZE} NUM

			Optional. Set the size (in Gb) of boot disk for the virtual machine. Default
			size is ${DEFAULT_BDISKSIZE}.

		${OPT_JOBTIMEOUT} SECONDS

			Optional. Set the timeout (seconds) for the job. Default is ${DEFAULT_JOB_TIMEOUT}
			(24 hours).

Job control commands:

	${CMD_JOBLST} [${OPT_MAXLST}|${OPT_MAXLST_L} NUM] [${FLG_USE_CSV}]
		[${OPT_DELIM}|${OPT_DELIM_L} DELIM]

		List jobs under current project. Jobs are are sorted by their submission time,
		latest first. Use -n or --limit to limit the number of jobs to display.
		Specify ${FLG_USE_CSV} will list jobs in comma-delimited table instead of
		tab-delimited. Specify a delimit character using "${OPT_DELIM}|${OPT_DELIM_L} DELIM"
		will override ${FLG_USE_CSV} and output a custom delimited table.

	${CMD_JOBDET} <job-id>

		All job creating commands, if successful, will display a job-id that uniquely
		identify the job created. This command can be used to display the detailed
		information of the job identified by the job-id. Be aware this is mostly about
		technical details of how the job is created and handled by google cloud platform,
		mostly useful to developers and technical staff than to general users.

	${CMD_CANCEL} <job-id>

		Cancel a running job

	${CMD_VER}

		Display the current RAPT version.

	${CMD_HELP}

		Display this usage page.

EOF
	rcode=0
	while (( $# ))
	do
		err "$1"
		rcode=1
		shift
	done

	exit $rcode
}




##transform strings to comply GCP label requirement: only lowercase, number and dash
normalize_val()
{
	tr '+/.[:blank:]' '-' <<< "$1" | tr '[:upper:]' '[:lower:]' | cut -c1-32
}

get_uuid()
{
	tr '[:upper:]' '[:lower:]' < <([[ -r /proc/sys/kernel/random/uuid ]] && cat /proc/sys/kernel/random/uuid || uuidgen)
}

uuid2jobid()
{
	local jid="${1//-/}"
	printf "%s" "${jid:1:10}"
}

##what is the advantage of using shopt?
export GCP_ACCOUNT=
export GCP_PROJECT=

verify_prerequisites()
{
	[[ -z $(command -v gcloud 2>/dev/null) ]] && errexit "gcloud SDK is required. See https://cloud.google.com/sdk/install for help."

	[[ -z $(command -v gsutil 2>/dev/null) ]] && errexit "gsutil is required. See https://cloud.google.com/storage/docs/gsutil_install for help."

	GCP_ACCOUNT=$(${GCLOUD} config get-value account 2>/dev/null)
	
}

verify_bucket()
{
	local bkt="$1"
	[[ -z $bkt ]] && errexit "Destination bucket not specified."

	[[ "$bkt" != "gs://"* ]] && errexit "Google cloud storage bucket uri should start with \"gs://\": ${bkt}"

	local fname="tmp.$(date '+%Y-%m-%dT%H:%M:%S')"
	local data=$RANDOM

	if ! gsutil cp - "${bkt}/${fname}" <<<${data} > /dev/null 2>&1
	then
		errexit "Specified bucket \"${bkt}\" does not exist or is not writable"
	fi

	##local read_back=$(gsutil cat "${bkt}/${fname}" 2>/dev/null)
	[[ "$data" != "$(gsutil cat "${bkt}/${fname}" 2>/dev/null)" ]] && errexit "Read back failed on bucket \"${bkt}\"."
}

##args
usr_label=''
##from environment by default
dst_bkt="$RAPT_OUTPUT_BUCKET"

flags=()
vm_type="${DEFAULT_VM}"
bd_size=${DEFAULT_BDISKSIZE}
job_timeout=${DEFAULT_JOB_TIMEOUT}
orga=
strain=

gcp_regions=${DEFAULT_REGION}

##joblist
max_lst=
format=${DEFAULT_FORMAT}
delimiter=

parse_opts()
{
	while (( $# ))
	do
		opt="$1"
		shift
		case $opt in
		${OPT_BUCKET}|${OPT_BUCKET_L})
			dst_bkt="$1"
			shift
			;;
		${OPT_BUCKET}=*|${OPT_BUCKET_L}=*)
			dst_bkt="${opt#*=}"
			;;
		${OPT_PROJECT})
			
			GCP_PROJECT="$1"
			shift
			;;
		${OPT_PROJECT}=*)
			GCP_PROJECT="${opt#*=}"
			;;
		${OPT_LABEL})
			usr_label="$1"
			shift
			;;
		${OPT_LABEL}=*)
			usr_label="${opt#*=}"
			;;

		${OPT_REGIONS})
			gcp_regions="$1"
			shift
			;;	
		${OPT_REGIONS}=*)
			gcp_regions="${opt#*=}"
			;;

		${OPT_VMTYPE})
			vm_type="$1"
			shift
			;;
		${OPT_VMTYPE}=*)
			vm_type="${opt#*=}"
			;;	

		${OPT_BDSIZE})
			bd_size="$1"
			shift
			;;
		${OPT_BDSIZE}=*)
			bd_size="${opt#*=}"
			;;

		${OPT_ORG})
			orga="$1"
			shift
			;;
		${OPT_ORG}=*)
			orga="${opt#*=}"
			;;

		${OPT_STRAIN})
			strain="$1"
			shift
			;;
		${OPT_STRAIN}=*)
			strain="${opt#*=}"
			;;

		${OPT_MAXLST}|${OPT_MAXLST_L})
			max_lst="$1"
			shift
			;;
		${OPT_MAXLST}=*|${OPT_MAXLST_L}=*)
			max_lst="${opt#*=}"
			;;

		${FLG_SKESA_ONLY})
			flags+=("skesa_only")
			;;

		${FLG_NOREPORT})
			flags+=("no_report")
			;;

		${FLG_USE_CSV})
			format="csv"
			;;
		${OPT_DELIM}|${OPT_DELIM_L})
			delimiter="$1"
			shift
			;;
		${OPT_DELIM}=*|${OPT_DELIM_L}=*)
			delimiter="${opt#*=}"
			;;
		${OPT_JOBTIMEOUT})
			job_timeout="$1"
			shift
			;;
		${OPT_JOBTIMEOUT}=*)
			job_timeout="${opt#*=}"
			;;
		*)
			errexit "Unknown option ${opt}."
			;;
		esac

	done

	##validate
	[[ ${job_timeout} =~ ^[0-9]+$ ]] && job_timeout="${job_timeout}s"
	
	if [[ -z ${GCP_PROJECT} ]]	##no project specified
	then
		GCP_PROJECT=$(gcloud config get-value project 2>/dev/null)
		[[ -z ${GCP_PROJECT} ]] && errexit "GCP project not set. Refer to 'gcloud init' for help to initiate a project."
	fi
	##add project to all gcloud commands
	
	GCLOUD="${GCLOUD} --project=${GCP_PROJECT}"
}

TMP_DIR=
cleanup()
{
	[[ ! -z ${TMP_DIR} && -e ${TMP_DIR} ]] && rm -rf -- "${TMP_DIR}"
}
trap cleanup EXIT

##job related
env_params=()
finputs=()
labels=("app=rapt" "rapt_version=${RAPT_VERSION}" "user=${USER}" "host=${HOSTNAME}" "image_tag=$(normalize_val ${IMAGE_URI##*:})")

create_job()
{
	local do_wait="$1"

	##verify_prerequisites
	verify_bucket "${dst_bkt}"

	local uuid=$(get_uuid)
	local job_id=$(uuid2jobid "${uuid}")
	labels+=("job_id=${job_id}")
	env_params+=("rapt_uuid=${uuid}" "rapt_jobid=${job_id}" "rapt_build=${RAPT_VERSION}")

	local dst_sto="${dst_bkt}/${job_id}"
	##local slog="${dst_sto}/concise.log"
	local vlog="${dst_sto}/run.log"
	local jobout="${dst_sto}/output.tar.gz"
	env_params+=("rapt_vlog_dst=${vlog}")

	if [[ ${#flags[@]} -gt 0 ]]
	then
		local opts=$(IFS=':';echo "${flags[*]}")
		env_params+=("rapt_opts=${opts}")
	fi

	##extra env vars not for RAPT but for job list
	[[ ! -z ${usr_label} ]] && env_params+=("user_label=${usr_label}")
	env_params+=("output_uri=${dst_sto}")

	TMP_DIR=$(mktemp -d)
	local gcpyaml="${TMP_DIR}/gcp.yaml"

	cat << YAML >"${gcpyaml}"
actions:
- imageUri: ${IMAGE_URI}
  commands: []

- imageUri: google/cloud-sdk:slim
  alwaysRun: true
  ignoreExitStatus: true
  commands:
  - /bin/sh
  - -c
  - "gsutil -m -q cp \${rapt_out} ${jobout}"

resources:
  virtualMachine:
    machineType: ${vm_type}
    bootDiskSizeGb: ${bd_size}
timeout: "${job_timeout}"
YAML

	local env_vars=$(IFS=',';echo "${env_params[*]}")
	local job_labels=$(IFS=',';echo "${labels[*]}")
	local rc=
	opid=$(${GCLOUD} beta lifesciences pipelines run \
		--regions=${gcp_regions} \
		--location=${DEFAULT_LOCATION} \
		--format="value(name.basename())" \
		--pipeline-file="${gcpyaml}" \
		--env-vars="${env_vars}" \
		--logging="${vlog}" \
		"${finputs[@]}" \
		--outputs="rapt_out=${jobout}" \
		--labels="${job_labels}" 2> "${TMP_DIR}/gcmsg")

	rc=$?

	if [[ rc -ne 0 ]]
	then
		cat "${TMP_DIR}/gcmsg"
		exit $rc
	fi

	##Success
	cat << EOF

RAPT job has been created successfully.
----------------------------------------------------
Job-id:             ${job_id}
Output storage:     ${dst_sto}
GCP account:        ${GCP_ACCOUNT}
GCP project:        ${GCP_PROJECT}
----------------------------------------------------

[**Attention**] RAPT jobs may take hours to finish. Progress of this job can be viewed in GCP stackdriver log viewer at:

	${GCP_LOGS_VIEWER}?project=${GCP_PROJECT}&filters=text:${job_id}

For current status of this job, run:

	${script_name} ${CMD_JOBLST} | fgrep ${job_id}

For technical details of this job, run:

	${script_name} ${CMD_JOBDET} ${job_id}

EOF
}

get_opid()
{
	opid=$(${GCLOUD} beta lifesciences operations list --format="value(name)" --filter="metadata.labels.job_id=$1" 2>/dev/null)
	[[ -z ${opid} || ! ${opid} =~ ^[0-9]+$ ]] && errexit "Invalid job id -> <$1>"

	printf "%s" "$opid"
}

list_jobs()
{
	local fmt_opts="metadata.labels.job_id,"\
"metadata.labels.user,"\
"metadata.pipeline.environment.user_label:label=LABEL,"\
"metadata.pipeline.environment.rapt_srr:label=SRR,"\
"format('{}{}', done.yesno(1,0), error.yesno(1,0)):label=STATUS,"\
"metadata.startTime.date(tz=LOCAL),"\
"metadata.endTime.date(tz=LOCAL),"\
"metadata.pipeline.environment.output_uri"

	##verify_prerequisites

	printf "%s\n" "Current jobs under project ${GCP_PROJECT}:"
	printf "%s\n" "-----------------------------------------------------"

	if [[ -z ${delimiter} ]]
	then
		[[ "${DEFAULT_FORMAT}" == "$format" ]] && delimiter='	' || delimiter=','
	fi

	local max=()
	[[ ! -z ${max_lst} && ${max_lst} =~ ^[0-9]+$ ]] && max=("--limit=${max_lst}")
	${GCLOUD} beta lifesciences operations list --filter="metadata.labels.app=rapt" --format="table(${fmt_opts})" ${max[@]} |
	while read line
	do
		local d=''
		for w in $line
		do
			case $w in
			10)
				printf "%s" "${d}Done"
				;;
			00)
				printf "%s" "${d}Running"
				;;
			11 | 01)
				printf "%s" "${d}Failed"
				;;
			*)
				printf "%s" "${d}${w}"
			esac
			d="${delimiter}"
		done
		printf "\n"

	done
}




get_jobinfo()
{
	##check if such job exists and get operation id
	opid=$(get_opid "$1")

	local datafmt="json(done,error,"\
"metadata.startTime,metadata.endTime,metadata.labels,"\
"metadata.pipeline.environment.output_uri,"\
"metadata.pipeline.environment.user_label,"\
"metadata.pipeline.resources,"\
"metadata.events)"
	${GCLOUD} beta lifesciences operations describe "$opid" --format="${datafmt}" 2>/dev/null
	rc=$?

	[[ rc -ne 0 ]] && errexit "Invalid job id -> <$1>"
}

cancel_job()
{
	${GCLOUD} beta lifesciences operations cancel $(get_opid "$1")
}
####################################* main  *#######################################

[[ $# -eq 0 ]] && usage

##read args
subcmd="$1"
shift

case ${subcmd} in
${CMD_ACXN})
	[[ $# -eq 0 ]] && usage "SRA running accession is required for command ${subcmd}."
	sra_acxn="$1"
	shift

	parse_opts "$@"

	env_params+=("rapt_srr=${sra_acxn}")
	labels+=("$(normalize_val srr=${sra_acxn})")

	create_job
	;;

${CMD_FASTQ})
	[[ $# -eq 0 ]] && usage "URI to FASTQ file in google cloud storage is required for command ${subcmd}."
	fastq_uri="$1"
	shift
	parse_opts "$@"

	[[ -z ${orga} ]] && usage "${OPT_ORG} \"Genus\" is required for FASTQ jobs."

	env_params+=("rapt_fastq_org=${orga}")

	[[ ! -z ${strain} ]] && env_params+=("rapt_fastq_strain=${strain}")

	finputs+=("--inputs" "rapt_fastq=${fastq_uri}")
	create_job
	;;

${CMD_JOBLST})
	parse_opts "$@"

	list_jobs
	;;

${CMD_JOBDET})
	[[ $# -eq 0 ]] && usage "Job-id is required for command ${subcmd}."
	job_id="$1"
	shift
	parse_opts "$@"

	get_jobinfo ${job_id}
	;;

${CMD_CANCEL})
	[[ $# -eq 0 ]] && usage "Job-id is required for command ${subcmd}."
	job_id="$1"
	shift
	parse_opts "$@"

	cancel_job "${job_id}"
	;;

${CMD_TEST})
	parse_opts "$@"
	env_params+=("rapt_act=functest")
	create_job
	;;

${CMD_VER}|--${CMD_VER}|-v)
	printf "%s\n" ${RAPT_VERSION}
	;;

${CMD_HELP})
	usage
	;;

*)
	if [[ ${subcmd} == -* ]]
	then
		errexit "No command specified."
	fi
	errexit "Unknown command -> <${subcmd}>."
	;;
esac
