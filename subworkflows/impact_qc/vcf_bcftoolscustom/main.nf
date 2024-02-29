include { BCFTOOLSCUSTOM                  } from '../../../modules/impact_qc/bcftoolscustom/main'

workflow VCF_BCFTOOLSCUSTOM {
    take:
    vcf
    cram
    fasta
    fasta_fai 

    main:
    reports  = Channel.empty()
    versions = Channel.empty()
    
    // RUN BCFTOOLS CUSTOM COMMANDS
    BCFTOOLSCUSTOM(vcf, cram, fasta, fasta_fai)

    // Gather all reports generated
    //reports = reports.mix(BCFTOOLSCUSTOM.out.ratio)
    //reports = reports.mix(BCFTOOLSCUSTOM.out.distribution)
    reports = reports.mix(BCFTOOLSCUSTOM.out.distributions2)
 
    // Gather versions of all tools used 
    versions = versions.mix(BCFTOOLSCUSTOM.out.versions)

    emit:
    reports
   
    versions
}
