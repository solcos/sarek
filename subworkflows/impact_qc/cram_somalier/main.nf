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

    if ( true ) { println "[SOMALIER] warning: Somalier only accepts the correct complementary sites file as input. Somalier only works with reference genomes from the next list [GATK.GRCh37, Ensembl.GRCh37, GATK.GRCh38, NCBI.GRCh38, hg38, hg19]. Please check that the sites files correspond to the same reference genome input if needed. To specify the correct sites file you can provide one by changing any config that customises the path using or changing: params.somalier_sites / --somalier_sites. You can find the sites files in 'assets/sites/' directory." }

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

