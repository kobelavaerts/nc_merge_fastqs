process CREATE_ARCHIVE {

    container "docker.io/kobelavaerts/wrapdemux:1.1"

    publishDir "${params.tosenddir}/${project_name}", mode: 'copy'

    input:
    tuple val(project_name), path(fastqs)

    output:
    tuple val(project_name), path("*.{tar,txt}"), emit: wrapped_fastqs

    script:
    def tar_prefix = params.tar_prefix ? params.tar_prefix : "processed_fastqs"

    """
    tar -chf - ${fastqs} \
    | tee >(md5sum > ${tar_prefix}-${project_name}.md5sum.txt) \
    > ${tar_prefix}-${project_name}.tar

    sed -i 's/-/${tar_prefix}-${project_name}.tar/g' ${tar_prefix}-${project_name}.md5sum.txt
    """


}