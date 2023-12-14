//
// BIOQC - SOMALIER  
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { SOMALIER } from '../../../modules/impact_qc/somalier/main'

workflow CRAM_SOMALIER {
    take:
    cram                    // channel: [mandatory] [ meta, cram ]
    fasta                  // channel: [mandatory] [ fasta ]
    fasta_fai              // channel: [mandatory] [ fasta_fai ]
    sites                  // channel: [mandatory] [ sites ]

    main:
    versions = Channel.empty()
    reports  = Channel.empty()

    // RUN SOMALIER
    SOMALIER(cram, fasta, fasta_fai, sites)

    // Gather all reports generated
    reports = reports.mix(SOMALIER.out.tsv)

    // Gather versions of all tools used 
    versions = versions.mix(SOMALIER.out.versions)

    emit:
    //tsv
    reports

    versions    // channel: [ versions.yml ]
}

