#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement

inputs: []

steps:
  substep:
    run: command.cwl
    in: []
    out: [container]
 
outputs:
  container:
    type: File
    outputSource: substep/container
