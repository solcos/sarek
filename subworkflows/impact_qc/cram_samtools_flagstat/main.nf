//
// QC - Samtools Flagstat 
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { SAMTOOLS_FLAGSTAT } from '../../../modules/impact_qc/samtools/flagstat/main'

workflow CRAM_SAMTOOLS_FLAGSTAT {
    take:
    cram                    // channel: [mandatory] [ meta, bam ]
    intervals

    main:
    versions = Channel.empty()
    reports  = Channel.empty()

    // RUN SAMTOOLS FLAGSTAT
    SAMTOOLS_FLAGSTAT(cram, intervals)

    // Gather all reports generated
    reports = reports.mix(SAMTOOLS_FLAGSTAT.out.flagstat)

    // Gather versions of all tools used
    versions = versions.mix(SAMTOOLS_FLAGSTAT.out.versions)

    emit:
    //cram
    reports

    versions    // channel: [ versions.yml ]
}

