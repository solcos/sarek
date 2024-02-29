
// IMPACT QC - COLLECT HS METRICS  
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { COLLECTHSMETRICS } from '../../../modules/impact_qc/gatk4/collecthsmetrics/main'

workflow CRAM_COLLECTHSMETRICS {
    take:
    input                    // channel: [mandatory] [ meta, cram, crai ]
    bait_intervals
    target_intervals
    fasta
    fasta_fai
    dict

    main:
    versions = Channel.empty()
    reports  = Channel.empty()

    if ( true ) { println "[GATK CollectHsMetrics] warning: PICARD CollectHsMetrics needs the intervals files for --bait_intervals and --target_intervals, (One or more genomic intervals over which to operate)." }

    // RUN COLLECT HS METRICS
    COLLECTHSMETRICS(input, bait_intervals, target_intervals, fasta, fasta_fai, dict)

    // Gather all reports generated
    reports = reports.mix(COLLECTHSMETRICS.out.metrics)
    
    // Gather versions of all tools used 
    versions = versions.mix(COLLECTHSMETRICS.out.versions)

    emit:
    reports

    versions    // channel: [ versions.yml ]
}

