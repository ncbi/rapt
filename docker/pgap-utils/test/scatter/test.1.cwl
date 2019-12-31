#!/usr/bin/env cwl-runner

cwlVersion: v1.0

class: Workflow

inputs:
   myint:
      type: int[]

requirements:
    - class: ScatterFeatureRequirement
    - class: InlineJavascriptRequirement
steps:
  massage_input:
    in:
        myint: myint
    out: [output]
    run: 
      class: ExpressionTool
      inputs: 
         myint: 
            type: int[]  
      expression: |
        ${ var  output=[];  output[0]=[];  var npartitions = 5; var partition_size = inputs.myint.length/npartitions; for(var i=0; i<inputs.myint.length; i++) { if(output[output.length-1].length >=partition_size ) { output.push([]); } output[output.length-1].push(inputs.myint[i]);   } ; return { "output": output }; }
      outputs:
         output: 
            type: 
            - type: array
              items: 
                type: array
                items: int
  mystep:
    scatter: [myint]
    scatterMethod: "flat_crossproduct"
    in:
      myint: massage_input/output
      # when passing data to a step, pass array
      # but underlying implementation of the step will use a singular type
    out: [output]
    run: 
      class: ExpressionTool
      inputs: 
         myint: 
            type: int[]  # specification of the input of the workflow is ALSO ARRAY, to complicate things
      expression: |
        ${ return { "output": inputs.myint }; }
      outputs:
         output: int[] # output is ALSO ARRAY, to complicate things
         # same with output:
         # output of the scattered subworkflow is NOT array
         # but output the step is used as ARRAY downstream
  massage_output:
    in:
        myint: mystep/output
    out: [output]
    run: 
      class: ExpressionTool
      inputs: 
         myint: 
            type: 
            - type: array
              items: 
                type: array
                items: int
      expression: |
        ${ var  output=[];for(var i=0; i<inputs.myint.length; i++) { for(var j=0; j<inputs.myint[i].length; j++) { output.push(inputs.myint[i][j]); }} ; return { "output": output }; }
      outputs:
         output: int[]
outputs:
    output:
      type: int[] 
      outputSource: massage_output/output 
      linkMerge: merge_flattened
      

