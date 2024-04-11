process SOMALIER {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/somalier:0.2.18--hb57907c_0':
        'biocontainers/somalier:0.2.18--hb57907c_0' }"

    input:
    tuple val(meta), path(cram), path(crai)
    path  fasta
    path  fasta_fai
    path  sites

    output:
    tuple val(meta), path("*.html"), emit: html 
    tuple val(meta), path("*.tsv") , emit: tsv
  
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reference = fasta ? "${fasta}" : ""
 
    """
    mkdir extracted

    somalier extract -d extracted --sites ${sites} -f ${reference} $cram

    somalier relate --infer --output-prefix ${prefix} extracted/*.somalier

    somalier relate --ped ${prefix}.samples.tsv --output-prefix ${prefix} extracted/*.somalier

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        somalier: \$(echo \$(somalier -h 2>&1) | sed -n 's/.*version: \\([0-9.]*\\).*/\\1/p')
    END_VERSIONS 
    """
}
