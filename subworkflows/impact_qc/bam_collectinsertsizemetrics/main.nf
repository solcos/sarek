//
// IMPACT QC - COLLECT INSERT SIZE METRICS  
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { COLLECTINSERTSIZEMETRICS } from '../../../modules/impact_qc/gatk4/collectinsertsizemetrics/main'

workflow BAM_COLLECTINSERTSIZEMETRICS {
    take:
    bam                    // channel: [mandatory] [ meta, bam ]
    
    main:
    versions = Channel.empty()
    reports  = Channel.empty()

    // RUN COLLECT INSERT SIZE METRICS
    COLLECTINSERTSIZEMETRICS(bam)

    // Gather all reports generated
    reports = reports.mix(COLLECTINSERTSIZEMETRICS.out.metrics)
    reports = reports.mix(COLLECTINSERTSIZEMETRICS.out.histogram)

    // Gather versions of all tools used 
    versions = versions.mix(COLLECTINSERTSIZEMETRICS.out.versions)

    emit:
    reports

    versions    // channel: [ versions.yml ]
}

