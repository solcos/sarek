process PICARD_COLLECTTARGETEDPCRMETRICS {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/picard:3.1.1--hdfd78af_0' :
        'biocontainers/picard:3.1.1--hdfd78af_0' }"

    input:
    //tuple val(meta), path(bam), path(bai), path(amplicon_intervals), path(target_intervals)
    //tuple val(meta2), path(fasta)
    //tuple val(meta3), path(fai)
    //tuple val(meta4), path(dict)
   
    tuple val(meta), path(bam), path(bai)
    path amplicon_intervals
    path target_intervals
    path fasta
    path fai
    //path dict

    output:
    tuple val(meta), path("*_metrics")  , emit: metrics
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    if ( true ) { println "[PICARD CollectTargetedPcrMetrics] warning: PICARD CollectTargetedPcrMetrics needs the intervals files for --amplicon_intervals and --target_intervals, (One or more genomic intervals over which to operate). Also, this tool will not be processed by MultiQC." }

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reference = fasta ? "--REFERENCE_SEQUENCE ${fasta}" : ""

    def avail_mem = 3072
    if (!task.memory) {
        log.info '[Picard CollectTargetedPcrMetrics] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }

    /*
    def amplicon_interval_list = amplicon_intervals
    def amplicon_intervallist_cmd = ""
    if (amplicon_intervals =~ /.(bed|bed.gz)$/){
        amplicon_interval_list = amplicon_intervals.toString().replaceAll(/.(bed|bed.gz)$/, ".interval_list")
        amplicon_intervallist_cmd = "picard -Xmx${avail_mem}M  BedToIntervalList --INPUT ${amplicon_intervals} --OUTPUT ${amplicon_interval_list} --SEQUENCE_DICTIONARY ${dict} --TMP_DIR ."
    }

    def target_interval_list = target_intervals
    def target_intervallist_cmd = ""
    if (target_intervals =~ /.(bed|bed.gz)$/){
        target_interval_list = target_intervals.toString().replaceAll(/.(bed|bed.gz)$/, ".interval_list")
        target_intervallist_cmd = "picard -Xmx${avail_mem}M  BedToIntervalList --INPUT ${target_intervals} --OUTPUT ${target_interval_list} --SEQUENCE_DICTIONARY ${dict} --TMP_DIR ."
    }
    */

    def amplicon_interval_list = amplicon_intervals
    def amplicon_intervallist_cmd = ""
    if (amplicon_intervals =~ /.(bed|bed.gz)$/){
        amplicon_interval_list = amplicon_intervals.toString().replaceAll(/.(bed|bed.gz)$/, ".interval_list")
        amplicon_intervallist_cmd = "picard -Xmx${avail_mem}M  BedToIntervalList --INPUT ${amplicon_intervals} --OUTPUT ${amplicon_interval_list} --TMP_DIR ."
    }

    def target_interval_list = target_intervals
    def target_intervallist_cmd = ""
    if (target_intervals =~ /.(bed|bed.gz)$/){
        target_interval_list = target_intervals.toString().replaceAll(/.(bed|bed.gz)$/, ".interval_list")
        target_intervallist_cmd = "picard -Xmx${avail_mem}M  BedToIntervalList --INPUT ${target_intervals} --OUTPUT ${target_interval_list} --TMP_DIR ."
    }

    """

    $amplicon_intervallist_cmd
    $target_intervallist_cmd

    picard \\
        -Xmx${avail_mem}M \\
        CollectTargetedPcrMetrics \\
        $args \\
        $reference \\
        --AMPLICON_INTERVALS $amplicon_interval_list \\
        --TARGET_INTERVALS $target_interval_list \\
        --INPUT $bam \\
        --OUTPUT ${prefix}.CollectTargetedPcrMetrics_metrics


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$(echo \$(picard CollectTargetedPcrMetrics --version 2>&1) | grep -o 'Version:.*' | cut -f2- -d:)
    END_VERSIONS
    """

    stub:
    //def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.CollectTargetedPcrMetrics_metrics

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$(echo \$(picard CollectTargetedPcrMetrics --version 2>&1) | grep -o 'Version:.*' | cut -f2- -d:)
    END_VERSIONS
    """
}
