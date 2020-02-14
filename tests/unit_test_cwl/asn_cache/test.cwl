#!/usr/bin/env cwl-runner

label: "ASN-Cache Unit Test"
cwlVersion: v1.0
class: Workflow

requirements:
    - class: SubworkflowFeatureRequirement
    - class: MultipleInputFeatureRequirement
    - class: DockerRequirement
      dockerPull: ncbi/gpdev:latest

inputs:
    submit_block_template: File
    fasta: File
    taxid: int
    gc_assm_name: string
    taxon_db: File

steps:
    genomic_source:
        run: ../../pgap/genomic_source/wf_genomic_source.cwl
        in:
            submit_block_template: submit_block_template
            fasta: fasta
            taxid: taxid
            gc_assm_name: gc_assm_name
            taxon_db: taxon_db
        out: [gencoll_asn, seqid_list, stats_report, asncache, ids_out]

outputs:
    example_output:
        type: Directory
        outputSource: genomic_source/asncache
