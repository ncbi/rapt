cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(inputs.my_input)
        writable: False

baseCommand: 'true'

inputs:
  my_input:
    type: Directory
    inputBinding:
      prefix: -asn-cache

outputs:
  my_output:
    type: Directory
    outputBinding:
      glob: $(inputs.my_input.basename)
