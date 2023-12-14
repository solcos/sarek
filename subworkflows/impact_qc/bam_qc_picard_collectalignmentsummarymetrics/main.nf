
// IMPACT QC - PICARD COLLECT ALIGNMENT SUMMARY METRICS  
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { PICARD_COLLECTALIGNMENTSUMMARYMETRICS } from '../../../modules/impact_qc/picard/collectalignmentsummarymetrics/main'

workflow BAM_PICARD_COLLECTALIGNMENTSUMMARYMETRICS {
    take:
    bam                    // channel: [mandatory] [ meta, bam, bai ]
    fasta
    fasta_fai
    //dict

    main:
    versions = Channel.empty()
    reports  = Channel.empty()

    // RUN PICARD COLLECT ALIGNMENT SUMMARY METRICS
    //PICARD_COLLECTALIGNMENTSUMMARYMETRICS(bam, fasta, fasta_fai, dict)

    PICARD_COLLECTALIGNMENTSUMMARYMETRICS(bam, fasta, fasta_fai)

    // Gather all reports generated
    reports = reports.mix(PICARD_COLLECTALIGNMENTSUMMARYMETRICS.out.metrics)
    
    // Gather versions of all tools used 
    versions = versions.mix(PICARD_COLLECTALIGNMENTSUMMARYMETRICS.out.versions)

    emit:
    reports

    versions    // channel: [ versions.yml ]
}

