//
// IMPACT QC - DEPTH OF COVERAGE  
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { DEPTHOFCOVERAGE } from '../../../modules/impact_qc/gatk4/depthofcoverage/main'

workflow CRAM_DEPTHOFCOVERAGE {
    take:
    cram                    // channel: [mandatory] [ meta, cram ]
    intervals              // channel: [mandatory] [ intervals, num_intervals ] or [ [], 0 ] if no intervals
    dict                  // channel: [mandatory] [ dict ]
    fasta                  // channel: [mandatory] [ fasta ]
    fasta_fai              // channel: [mandatory] [ fasta_fai ]
    
    main:
    versions = Channel.empty()
    reports  = Channel.empty()

    // RUN DEPTH OF COVERAGE
    if ( !intervals ) {
        if ( true ) { println "[GATK4 DepthOfCoverage] warning: GATK4 DepthOfCoverage needs the intervals file (One or more genomic intervals over which to operate) (--intervals). If not, it's not executed" }
    } else {
        DEPTHOFCOVERAGE(cram, intervals, dict.map{ meta, it -> [ it ] }, fasta, fasta_fai)

    }

    // Gather all reports generated
    reports = reports.mix(DEPTHOFCOVERAGE.out.depthofcoverage_output)
    //reports = reports.mix(GATK4_DEPTH_OF_COVERAGE.out.summary)
    //reports = reports.mix(GATK4_DEPTH_OF_COVERAGE.out.statistics)
    //reports = reports.mix(GATK4_DEPTH_OF_COVERAGE.out.interval_summary)
    //reports = reports.mix(GATK4_DEPTH_OF_COVERAGE.out.interval_statistics)
    //reports = reports.mix(GATK4_DEPTH_OF_COVERAGE.out.gene_summary)
    //reports = reports.mix(GATK4_DEPTH_OF_COVERAGE.out.gene_statistics)
    //reports = reports.mix(GATK4_DEPTH_OF_COVERAGE.out.cumulative_coverage_counts)
    //reports = reports.mix(GATK4_DEPTH_OF_COVERAGE.out.cumulative_coverage_proportions)

    // Gather versions of all tools used 
    versions = versions.mix(DEPTHOFCOVERAGE.out.versions)

    emit:
    reports

    versions    // channel: [ versions.yml ]
}

