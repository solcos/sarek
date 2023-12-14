
// IMPACT QC - PICARD COLLECT HS METRICS  
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { PICARD_COLLECTHSMETRICS } from '../../../modules/impact_qc/picard/collecthsmetrics/main'

workflow BAM_PICARD_COLLECTHSMETRICS {
    take:
    input                    // channel: [mandatory] [ meta, bam, bai, bait_intervals, target_intervals ]
    bait_intervals
    target_intervals
    fasta
    fasta_fai
    //dict

    main:
    versions = Channel.empty()
    reports  = Channel.empty()

    // RUN PICARD COLLECT HS METRICS
    //PICARD_COLLECTHSMETRICS(input, fasta, fasta_fai, dict)

    //PICARD_COLLECTHSMETRICS(input, bait_intervals, target_intervals, fasta, fasta_fai, dict)
 
    PICARD_COLLECTHSMETRICS(input, bait_intervals, target_intervals, fasta, fasta_fai)

    // Gather all reports generated
    reports = reports.mix(PICARD_COLLECTHSMETRICS.out.metrics)
    
    // Gather versions of all tools used 
    versions = versions.mix(PICARD_COLLECTHSMETRICS.out.versions)

    emit:
    reports

    versions    // channel: [ versions.yml ]
}

