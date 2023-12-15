process COLLECTHSMETRICS {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::gatk4=4.4.0.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gatk4:4.4.0.0--py36hdfd78af_0':
        'biocontainers/gatk4:4.4.0.0--py36hdfd78af_0' }"

    input:
    tuple val(meta), path(bam), path(bai)
    path bait_intervals
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
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reference = fasta ? "--REFERENCE_SEQUENCE ${fasta}" : ""

    def avail_mem = 3072
    if (!task.memory) {
        log.info '[GATK CollectHsMetrics] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }

    def bait_interval_list = bait_intervals
    def bait_intervallist_cmd = ""
    if (bait_intervals =~ /.(bed|bed.gz)$/){
        bait_interval_list = bait_intervals.toString().replaceAll(/.(bed|bed.gz)$/, ".interval_list")
        bait_intervallist_cmd = "picard -Xmx${avail_mem}M  BedToIntervalList --INPUT ${bait_intervals} --OUTPUT ${bait_interval_list} --TMP_DIR ."
    }

    def target_interval_list = target_intervals
    def target_intervallist_cmd = ""
    if (target_intervals =~ /.(bed|bed.gz)$/){
        target_interval_list = target_intervals.toString().replaceAll(/.(bed|bed.gz)$/, ".interval_list")
        target_intervallist_cmd = "picard -Xmx${avail_mem}M  BedToIntervalList --INPUT ${target_intervals} --OUTPUT ${target_interval_list} --TMP_DIR ."
    }

    """

    $bait_intervallist_cmd
    $target_intervallist_cmd

    gatk --java-options "-Xmx${avail_mem}M -XX:-UsePerfData" \\
        CollectHsMetrics \\
        $args \\
        $reference \\
        --BAIT_INTERVALS $bait_interval_list \\
        --TARGET_INTERVALS $target_interval_list \\
        --INPUT $bam \\
        --OUTPUT ${prefix}.CollectHsMetrics.coverage_metrics


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//') 
    END_VERSIONS
    """

    stub:
    //def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.CollectHsMetrics.coverage_metrics

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
}
