process NGSCAT {
    tag "$meta.id"
    label 'process_single'

    //conda "bioconda::sexdeterrmine=1.1.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ngscat':
        'clinbioinfosspa/ngscat:latest' }"

    input:
    tuple val(meta), path(bam), path(bai)
    path targets
    path fasta
    path fai

    output:
    tuple val(meta), path("*.html"), emit: html
    
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
   
     if ( true ) { println "[ngsCAT] warning: GATK4 DepthOfCoverage needs the targets bed file (One or more genomic intervals over which to operate) (--target-ngscat). Also, this tool will not be processed by MultiQC." }     

    """
    sexdeterrmine \\
        -I $depth \\
        -f $sample_list_file \\
        $args \\
        > ${prefix}_results.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sexdeterrmine: \$(echo \$(sexdeterrmine --version 2>&1))
    END_VERSIONS
    """
