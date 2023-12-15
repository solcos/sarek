
// IMPACT QC - COLLECT ALIGNMENT SUMMARY METRICS  
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { COLLECTALIGNMENTSUMMARYMETRICS } from '../../../modules/impact_qc/gatk4/collectalignmentsummarymetrics/main'

workflow BAM_COLLECTALIGNMENTSUMMARYMETRICS {
    take:
    bam                    // channel: [mandatory] [ meta, bam, bai ]
    fasta
    fasta_fai

    main:
    versions = Channel.empty()
    reports  = Channel.empty()

    // RUN COLLECT ALIGNMENT SUMMARY METRICS
    COLLECTALIGNMENTSUMMARYMETRICS(bam, fasta, fasta_fai)

    // Gather all reports generated
    reports = reports.mix(COLLECTALIGNMENTSUMMARYMETRICS.out.metrics)
    
    // Gather versions of all tools used 
    versions = versions.mix(COLLECTALIGNMENTSUMMARYMETRICS.out.versions)

    emit:
    reports

    versions    // channel: [ versions.yml ]
}

