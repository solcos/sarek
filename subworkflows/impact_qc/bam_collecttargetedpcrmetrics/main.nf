
// IMPACT QC - COLLECT TARGETED PCR METRICS  
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { COLLECTTARGETEDPCRMETRICS } from '../../../modules/impact_qc/gatk4/collecttargetedpcrmetrics/main'

workflow BAM_COLLECTTARGETEDPCRMETRICS {
    take:
    input                    // channel: [mandatory] [ meta, bam, bai, amplicon_intervals, target_intervals ]
    amplicon_intervals
    target_intervals
    fasta
    fasta_fai

    main:
    versions = Channel.empty()
    reports  = Channel.empty()

    // RUN COLLECT TARGETED PCR METRICS
    COLLECTTARGETEDPCRMETRICS(input, amplicon_intervals, target_intervals, fasta, fasta_fai)

    // Gather all reports generated
    reports = reports.mix(COLLECTTARGETEDPCRMETRICS.out.metrics)
    
    // Gather versions of all tools used 
    versions = versions.mix(COLLECTTARGETEDPCRMETRICS.out.versions)

    emit:
    reports

    versions    // channel: [ versions.yml ]
}

