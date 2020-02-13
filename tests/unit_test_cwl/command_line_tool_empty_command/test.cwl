#!/usr/bin/env cwl-runner

# See: https://github.com/common-workflow-language/common-workflow-language/issues/818
cwlVersion: v1.0
class: CommandLineTool
requirements:
    - class: DockerRequirement
      dockerPull: ubuntu
inputs: []
outputs: []
