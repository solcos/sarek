
// IMPACT QC - PICARD COLLECT TARGETED PCR METRICS  
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { PICARD_COLLECTTARGETEDPCRMETRICS } from '../../../modules/impact_qc/picard/collecttargetedpcrmetrics/main'

workflow BAM_PICARD_COLLECTTARGETEDPCRMETRICS {
    take:
    input                    // channel: [mandatory] [ meta, bam, bai, amplicon_intervals, target_intervals ]
    amplicon_intervals
    target_intervals
    fasta
    fasta_fai
    //dict

    main:
    versions = Channel.empty()
    reports  = Channel.empty()

    // RUN PICARD COLLECT TARGETED PCR METRICS
    //PICARD_COLLECTTARGETEDPCRMETRICS(input, fasta, fasta_fai, dict)

    //PICARD_COLLECTTARGETEDPCRMETRICS(input, amplicon_intervals, target_intervals, fasta, fasta_fai, dict)

    PICARD_COLLECTTARGETEDPCRMETRICS(input, amplicon_intervals, target_intervals, fasta, fasta_fai)

    // Gather all reports generated
    reports = reports.mix(PICARD_COLLECTTARGETEDPCRMETRICS.out.metrics)
    
    // Gather versions of all tools used 
    versions = versions.mix(PICARD_COLLECTTARGETEDPCRMETRICS.out.versions)

    emit:
    reports

    versions    // channel: [ versions.yml ]
}

