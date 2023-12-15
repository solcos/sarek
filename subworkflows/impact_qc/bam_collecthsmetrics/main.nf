
// IMPACT QC - COLLECT HS METRICS  
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { COLLECTHSMETRICS } from '../../../modules/impact_qc/gatk4/collecthsmetrics/main'

workflow BAM_COLLECTHSMETRICS {
    take:
    input                    // channel: [mandatory] [ meta, bam, bai, bait_intervals, target_intervals ]
    bait_intervals
    target_intervals
    fasta
    fasta_fai

    main:
    versions = Channel.empty()
    reports  = Channel.empty()

    // RUN COLLECT HS METRICS
    COLLECTHSMETRICS(input, bait_intervals, target_intervals, fasta, fasta_fai)

    // Gather all reports generated
    reports = reports.mix(COLLECTHSMETRICS.out.metrics)
    
    // Gather versions of all tools used 
    versions = versions.mix(COLLECTHSMETRICS.out.versions)

    emit:
    reports

    versions    // channel: [ versions.yml ]
}

