cwlVersion: v1.0 
class: CommandLineTool

baseCommand: [bash, '-c', 'mkdir "$1" && touch "$1/my_file"', '-']

inputs:
  my_input:
    type: string
    default: my_dir
    inputBinding:
      position: 1

outputs:
  my_output:
    type: Directory
    outputBinding:
        glob: $(inputs.my_input)
