process COLLECTTARGETEDPCRMETRICS {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gatk4:4.4.0.0--py36hdfd78af_0':
        'biocontainers/gatk4:4.4.0.0--py36hdfd78af_0' }"

    input:  
    tuple val(meta), path(cram), path(crai)
    path amplicon_intervals
    path target_intervals
    path fasta
    path fai
    path dict

    output:
    tuple val(meta), path("*_metrics")  , emit: metrics
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reference = fasta ? "--REFERENCE_SEQUENCE ${fasta}" : ""

    def avail_mem = 3072
    if (!task.memory) {
        log.info '[GATK CollectTargetedPcrMetrics] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }

    def amplicon_interval_list = amplicon_intervals
    def amplicon_intervallist_cmd = ""
    if (amplicon_intervals =~ /.(bed|bed.gz)$/){
        amplicon_interval_list = amplicon_intervals.toString().replaceAll(/.(bed|bed.gz)$/, ".interval_list")
        amplicon_intervallist_cmd = "gatk --java-options -Xmx${avail_mem}M  BedToIntervalList --INPUT ${amplicon_intervals} --OUTPUT ${amplicon_interval_list} --SEQUENCE_DICTIONARY ${dict} --TMP_DIR ."
    }

    def target_interval_list = target_intervals
    def target_intervallist_cmd = ""
    if (target_intervals =~ /.(bed|bed.gz)$/){
        target_interval_list = target_intervals.toString().replaceAll(/.(bed|bed.gz)$/, ".interval_list")
        target_intervallist_cmd = "gatk --java-options -Xmx${avail_mem}M  BedToIntervalList --INPUT ${target_intervals} --OUTPUT ${target_interval_list} --SEQUENCE_DICTIONARY ${dict} --TMP_DIR ."
    }

    """

    $amplicon_intervallist_cmd
    $target_intervallist_cmd
    
    gatk --java-options "-Xmx${avail_mem}M -XX:-UsePerfData" \\
        CollectTargetedPcrMetrics \\
        $args \\
        $reference \\
        --AMPLICON_INTERVALS $amplicon_interval_list \\
        --TARGET_INTERVALS $target_interval_list \\
        --INPUT $cram \\
        --OUTPUT ${prefix}.CollectTargetedPcrMetrics_metrics


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    touch ${prefix}.CollectTargetedPcrMetrics_metrics

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
}
