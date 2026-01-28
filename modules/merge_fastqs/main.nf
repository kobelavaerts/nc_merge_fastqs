
process MERGE_FASTQS {

    container "python:3.12.12"
    publishDir "${params.output}/merged", mode: 'copy'


    input:
    tuple val(meta), path("fastq1.gz"), path("fastq2.gz")

    output:
    tuple val(meta), path("${meta.prefix}")

    script:
    """
    merge_fastqs.py fastq1.gz fastq2.gz ${meta.prefix} 
    """
}