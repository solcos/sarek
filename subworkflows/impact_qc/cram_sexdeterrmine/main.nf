//
// BIOQC - Sex DetERRmine 
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { SAMTOOLS_DEPTH } from '../../../modules/impact_qc/samtools/depth/main'
include { SEXDETERRMINE } from '../../../modules/impact_qc/sexdeterrmine/main'

workflow CRAM_SEXDETERRMINE {
    take:
    cram                    // channel: [mandatory] [ meta, bam ]
    intervals

    main:
    versions = Channel.empty()
    reports  = Channel.empty()

    // RUN SAMTOOLS DEPTH
    SAMTOOLS_DEPTH(cram, intervals)

    // SEXDETERRMINE
    SEXDETERRMINE(SAMTOOLS_DEPTH.out.tsv, SAMTOOLS_DEPTH.out.txt)

    // Gather all reports generated
    //reports = reports.mix(SAMTOOLS_DEPTH.out.reports)
    reports = reports.mix(SEXDETERRMINE.out.json)

    // Gather versions of all tools used
    versions = versions.mix(SAMTOOLS_DEPTH.out.versions)
    versions = versions.mix(SEXDETERRMINE.out.versions)

    emit:
    //cram
    reports

    versions    // channel: [ versions.yml ]
}

