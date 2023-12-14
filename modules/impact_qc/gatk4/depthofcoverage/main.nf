process GATK4_DEPTH_OF_COVERAGE {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::gatk4=4.4.0.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gatk4:4.4.0.0--py36hdfd78af_0':
        'biocontainers/gatk4:4.4.0.0--py36hdfd78af_0' }"

    input:
    tuple val(meta), path(cram), path(crai) 
    path intervals
    path dict
    path fasta
    path fai
   

    output:
    //tuple val(meta), path("*.bam") , emit: bam,  optional: true
    //tuple val(meta), path("*.cram"), emit: cram, optional: true
    tuple val(meta), path("*gatk4_depth_of_coverage*"), emit: depth_of_coverage_output //per_locus_coverage          
    //tuple val(meta), path("*_summary"), emit: summary
    //tuple val(meta), path("*_statistics"), emit: statistics
    //tuple val(meta), path("*_interval_summary"), emit: interval_summary          
    //tuple val(meta), path("*_interval_statistics"), emit: interval_statistics          
    //tuple val(meta), path("*_gene_summary"), emit: gene_summary          
    //tuple val(meta), path("*_gene_statistics"), emit: gene_statistics          
    //tuple val(meta), path("*_cumulative_coverage_counts"), emit: cumulative_coverage_counts          
    //tuple val(meta), path("*_cumulative_coverage_proportions"), emit: cumulative_coverage_proportions           
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    //def interval_command = intervals ? "--intervals $intervals" : ""

    if ( true ) { println "[GATK4 DepthOfCoverage] warning: GATK4 DepthOfCoverage needs the intervals file (One or more genomic intervals over which to operate) (--intervals). Also, this tool will not be processed by MultiQC." }

   def avail_mem = 3072
    if (!task.memory) {
        log.info '[GATK4 DepthOfCoverage] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }
    """
    gatk --java-options "-Xmx${avail_mem}M -XX:-UsePerfData" \\
        DepthOfCoverage \\
        --input $cram \\
        --output ${prefix} \\
        --reference $fasta \\
        --intervals $intervals \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
}
