cwlVersion: v1.0 
class: CommandLineTool

baseCommand: ['grep', 'docker', '/proc/1/cgroup']

inputs: []
outputs:
  container:
    type: stdout
