#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
baseCommand: skesa
hints:
  DockerRequirement:
    dockerPull: ncbi/skesa:v2.3.0
inputs:
  reads:
    type:
      type: array
      items: File
      inputBinding:
	prefix: --reads
      	separate: false
    inputBinding:
      position: 1
  contigs_out_name:
    type: string?
    default: contigs.out
    inputBinding:
      prefix: --contigs_out
outputs:
  contigs_out:
    type: File
    outputBinding:
      glob: $(inputs.contigs_out_name)
