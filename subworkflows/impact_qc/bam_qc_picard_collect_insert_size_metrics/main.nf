//
// IMPACT QC - PICARD COLLECT INSERT SIZE METRICS  
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { PICARD_COLLECT_INSERT_SIZE_METRICS } from '../../../modules/impact_qc/picard/collectinsertsizemetrics/main'

workflow BAM_PICARD_COLLECT_INSERT_SIZE_METRICS {
    take:
    bam                    // channel: [mandatory] [ meta, bam ]
    
    main:
    versions = Channel.empty()
    reports  = Channel.empty()

    // RUN PICARD COLLECT INSERT SIZE METRICS
    PICARD_COLLECT_INSERT_SIZE_METRICS(bam)

    // Gather all reports generated
    reports = reports.mix(PICARD_COLLECT_INSERT_SIZE_METRICS.out.metrics)
    reports = reports.mix(PICARD_COLLECT_INSERT_SIZE_METRICS.out.histogram)

    // Gather versions of all tools used 
    versions = versions.mix(PICARD_COLLECT_INSERT_SIZE_METRICS.out.versions)

    emit:
    reports

    versions    // channel: [ versions.yml ]
}

