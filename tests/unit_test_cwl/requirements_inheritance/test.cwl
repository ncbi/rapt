#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: DockerRequirement
    dockerPull: ubuntu 

inputs: []

steps:
  substep:
    run: subworkflow.cwl
    in: []
    out: [container]
 
outputs:
  container:
    type: File
    outputSource: substep/container
