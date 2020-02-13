#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement

inputs: []

steps:
  directory_output_step:
    run: mkdir.cwl
    in: []
    out: [my_output]

  initial_work_dir_read_only_step:
    run: initial_work_dir_read_only.cwl
    in:
        my_input: directory_output_step/my_output
    out: [my_output]
 
outputs:
  my_final_output:
    type: Directory
    outputSource: initial_work_dir_read_only_step/my_output
