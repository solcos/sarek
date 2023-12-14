process SAMTOOLS_DEPTH {
    tag "$meta1.id"
    label 'process_low'

    conda "bioconda::samtools=1.17"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.17--h00cdaf9_0' :
        'biocontainers/samtools:1.17--h00cdaf9_0' }"

    input:
    tuple val(meta1), path(cram), path(crai)
    tuple val(meta2), path(intervals)

    output:
    tuple val(meta1), path("*_modified_sexdeterrmine.tsv"), emit: tsv
    tuple val(meta1), path("*_sample_sexdeterrmine.txt"), emit: txt
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta1.id}"
    def positions = intervals ? "-b ${intervals}" : ""

    """
    samtools \\
        depth \\
        --threads ${task.cpus-1} \\
        $args \\
        $positions \\
        -o ${prefix}.tsv \\
        $cram

    #  Modify output for SexDeterrmine
    awk 'BEGIN {print "#Chr\tPos\t${prefix}"} {print}' ${prefix}.tsv > ${prefix}_modified_sexdeterrmine.tsv
    echo "${prefix}" > ${prefix}_sample_sexdeterrmine.txt 
    rm -f ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
