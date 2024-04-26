/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPACT QC
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Quality control workflow nextflow code to use in nf-core pipelines. 
    Now implemented in nf-core/sarek. 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
    Started 2023.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/solcos/sarek
    Docs   : https://nf-co.re/sarek/usage
    Metrics: 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// For all modules here:
// A when clause condition is defined in the 'impact_qc/impact_qc.config' to determine if the module should be run

// Information for the configuration of Sarek
// Add to 'nextflow_schema.json' tools pattern: "plotallelicreadpct|plotgq|plotsb"
// Add to 'nextflow_schema.json' skip tools pattern: "bcftoolscustom|bcftoolsstats|collectinsertsizemetrics|collecthsmetrics|collecttargetedpcrmetrics|fastqscreen|fastpstats|flagstat|impactqc|sexdeterrmine|somalier|vcftoolscustom"

// Add to FastQC module 'main.nf' before 'fastqc' command:
//# Activate kmer module
//sed -i "5s:1:0:g" /usr/local/opt/fastqc-0.12.1/Configuration/limits.txt

// Add sites path to 'igenomes.config' in the differents reference genomes (specify the version)
// somalier_sites = "${projectDir}/impact_qc/assets/sites/sites.{version}.vcf.gz"

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// PICARD INTERVALS
params.bait_intervals          = ""
bait_intervals                 = params.bait_intervals     ? Channel.fromPath(params.bait_intervals, checkIfExists: true).collect()     : Channel.empty()
params.amplicon_intervals      = ""
amplicon_intervals             = params.amplicon_intervals ? Channel.fromPath(params.amplicon_intervals, checkIfExists: true).collect() : Channel.empty()
params.target_intervals        = ""
target_intervals               = params.target_intervals   ? Channel.fromPath(params.target_intervals, checkIfExists: true).collect()   : Channel.empty()
hsmetrics_intervals            = bait_intervals.combine(target_intervals)
 
// SOMALIER
somalier_sites                 = params.somalier_sites     ? Channel.fromPath(params.somalier_sites, checkIfExists: true).collect()     : Channel.empty()

// FASTQ_SCREEN
params.fastq_screen_conf_db    = "${projectDir}/impact_qc/assets/fastq_screen_conf_db/**"
fastq_screen_conf_db           = params.fastq_screen_conf_db ? Channel.fromPath(params.fastq_screen_conf_db, checkIfExists: true).collect()     : Channel.empty()

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Convert CRAM file (before variant calling) to BAM file
include { SAMTOOLS_CONVERT as CRAM_TO_BAM_IMPACT_QC } from '../modules/nf-core/samtools/convert/main'

// Collect Insert Size Metrics
include { COLLECTINSERTSIZEMETRICS                  } from './modules/gatk4/collectinsertsizemetrics/main'

// Collect Hs Metrics
include { COLLECTHSMETRICS                          } from './modules/gatk4/collecthsmetrics/main'

// Collect Targeted Pcr Metrics
include { COLLECTTARGETEDPCRMETRICS                 } from './modules/gatk4/collecttargetedpcrmetrics/main'

// Samtools flagstat
include { SAMTOOLS_FLAGSTAT                         } from './modules/samtools/flagstat/main'

// Sex determine
include { SAMTOOLS_DEPTH                            } from './modules/samtools/depth/main'
include { SEXDETERRMINE                             } from './modules/sexdeterrmine/main'

// Somalier
include { SOMALIER                                  } from './modules/somalier/main'

// FastP stats
include { FASTPSTATS                                } from './modules/fastpstats/main'

// FastQ_Screen
include { FASTQSCREEN                               } from './modules/fastqscreen/main'

// Bcftools custom commands
include { BCFTOOLSCUSTOM                            } from './modules/bcftoolscustom/main'

// Bcftools stats commands
include { BCFTOOLSSTATS                             } from './modules/bcftoolsstats/main'

// Vcftools custom commands
include { VCFTOOLSCUSTOM                            } from './modules/vcftoolscustom/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow IMPACT_QC {

    take:
    fa
    fai
    dic
    input
    prep_intervals
    vcf
    comb_bed_intervals
    reads_alignment
    fastp_results_json
    bcftools_stats_results
 
    main:

    // IMPACT QC
  
    versions = Channel.empty()
    impact_qc_reports  = Channel.empty()
 
    // FASTQ file
    // If the pipeline starts from Fastq files (the step is 'mapping')
    if (!(params.step in ['markduplicates', 'prepare_recalibration', 'recalibrate', 'variant_calling', 'annotate'])) {

        // Fastp stats
        if (!(params.skip_tools && params.skip_tools.split(',').contains('fastpstats'))) {

            // Fastp stats
            FASTPSTATS(fastp_results_json)

            // Gather reports of all tools used
            impact_qc_reports = impact_qc_reports.mix(FASTPSTATS.out.fastpstats)

        }
    

        // FASTQ_SCREEN
        if (!(params.skip_tools && params.skip_tools.split(',').contains('fastqscreen'))) {
            
            // fastq_screen_conf_db does not exists
            fastq_screen_conf_db.ifEmpty{ println("ERROR: fastq_screen_conf_db is empty or is not found. Put fastq_screen_conf_db to the correct path or add 'fastqscreen' to the 'skip_tools'.") }

            if ( true ) { println "[FASTQSCREEN] INFO: FastQ_Screen needs a configuration file called 'fastq_screen.conf' provided in the folder 'impact_qc/assets/fastq_screen_db' where the user can modify the mapper in the tool and also uncomment the the databases you want to use FastQ_Screen on. Also, in the same folder, the user needs to provide the respective Bowtie indexes of the different species that want to check in order to have the database for the FastQ_Screen. The indexes must go in a separate folder with the name as indicated in the 'fastq_screen.conf' file (the second field in each database). Moreover, the last field of each database is the prefix name of the indexes, note that you can't change the path, only the name."}
    
            FASTQSCREEN(reads_alignment, fastq_screen_conf_db)

            // Gather reports of all tools used
            impact_qc_reports = impact_qc_reports.mix(FASTQSCREEN.out.html)
            impact_qc_reports = impact_qc_reports.mix(FASTQSCREEN.out.png)
            impact_qc_reports = impact_qc_reports.mix(FASTQSCREEN.out.txt)

            // Gather versions of all tools used
            versions = versions.mix(FASTQSCREEN.out.versions)

        }
    } else {
        if ( true ) { println "[FASTQ metrics] WARNING: All the FASTQ metrics will not be shown since the pipeline configuration does not start from fastq files"}
    }

    // BAM/CRAM file
    // Collect Insert Size Metrics
    if (!(params.skip_tools && params.skip_tools.split(',').contains('collectinsertsizemetrics'))) {

        // Convert last CRAM file to BAM to used it in CollectInsertSizeMetrics
        CRAM_TO_BAM_IMPACT_QC(input, fa, fai)
        bam_impact_qc = Channel.empty()
        bam_impact_qc = CRAM_TO_BAM_IMPACT_QC.out.alignment_index
            // Make sure correct data types are carried through
            .map{ meta, bam, bai -> [ meta + [data_type: "bam"], bam, bai ] }

        versions = versions.mix(CRAM_TO_BAM_IMPACT_QC.out.versions)
          
        // RUN COLLECT INSERT SIZE METRICS
        COLLECTINSERTSIZEMETRICS(bam_impact_qc)

        // Gather all reports generated
        impact_qc_reports = impact_qc_reports.mix(COLLECTINSERTSIZEMETRICS.out.metrics)
        impact_qc_reports = impact_qc_reports.mix(COLLECTINSERTSIZEMETRICS.out.histogram)

        // Gather versions of all tools used 
        versions = versions.mix(COLLECTINSERTSIZEMETRICS.out.versions)
 
    }
      
    // CollectHsMetrics
    if (!(params.skip_tools && params.skip_tools.split(',').contains('collecthsmetrics'))) {
                    
        // Bait or target intervals do not exist
        bait_intervals.ifEmpty{ println("ERROR: Bait intervals is empty or is not found. Put the path to the correct bait intervals in 'bait_intervals' or add 'collecthsmetrics' to the 'skip_tools'.") }
        target_intervals.ifEmpty{ println("ERROR: Target intervals is empty or is not found. Put the path to the correct target intervals in 'target_intervals' or add 'collecthsmetrics' to the 'skip_tools'.") }

        if ( true ) { println "[GATK CollectHsMetrics] WARNING: PICARD CollectHsMetrics needs the intervals files for --bait_intervals and --target_intervals, (One or more genomic intervals over which to operate)." }

        // RUN COLLECT HS METRICS
        COLLECTHSMETRICS(input, bait_intervals, target_intervals, fa, fai, dic)

        // Gather all reports generated
        impact_qc_reports = impact_qc_reports.mix(COLLECTHSMETRICS.out.metrics)
    
        // Gather versions of all tools used 
        versions = versions.mix(COLLECTHSMETRICS.out.versions)
            
    }

    // CollectTargetedPcrMetrics
    if (!(params.skip_tools && params.skip_tools.split(',').contains('collecttargetedpcrmetrics'))) {
             
        // Amplicon or target intervals do not exist
        amplicon_intervals.ifEmpty{ println("ERROR: Amplicon intervals is empty or is not found. Put the path to the correct amplicon intervals in 'amplicon_intervals' or add 'collecttargetedpcrmetrics' to the 'skip_tools'.") }
        target_intervals.ifEmpty{ println("ERROR: Target intervals is empty or is not found. Put the path to the correct target intervals in 'target_intervals' or add 'collecttargetedpcrmetrics' to the 'skip_tools'.") }

        if ( true ) { println "[GATK CollectTargetedPcrMetrics] WARNING: PICARD CollectTargetedPcrMetrics needs the intervals files for --amplicon_intervals and --target_intervals, (One or more genomic intervals over which to operate). Also, this tool will not be processed by MultiQC." }

        // RUN COLLECT TARGETED PCR METRICS
        COLLECTTARGETEDPCRMETRICS(input, amplicon_intervals, target_intervals, fa, fai, dic)

        // Gather all reports generated
        impact_qc_reports = impact_qc_reports.mix(COLLECTTARGETEDPCRMETRICS.out.metrics)
    
        // Gather versions of all tools used 
        versions = versions.mix(COLLECTTARGETEDPCRMETRICS.out.versions)
    }
        
    // Samtools flagstat
    if (!(params.skip_tools && params.skip_tools.split(',').contains('flagstat'))) {

       // RUN SAMTOOLS FLAGSTAT
       SAMTOOLS_FLAGSTAT(input, prep_intervals)

       // Gather all reports generated
       impact_qc_reports = impact_qc_reports.mix(SAMTOOLS_FLAGSTAT.out.flagstat)

       // Gather versions of all tools used
       versions = versions.mix(SAMTOOLS_FLAGSTAT.out.versions) 
    }

    // SEX DETERMINATION
    if (!(params.skip_tools && params.skip_tools.split(',').contains('sexdeterrmine'))) {

        // RUN SAMTOOLS DEPTH
        SAMTOOLS_DEPTH(input, prep_intervals)

        // SEXDETERRMINE
        SEXDETERRMINE(SAMTOOLS_DEPTH.out.tsv, SAMTOOLS_DEPTH.out.txt)

        // Gather all reports generated
        impact_qc_reports = impact_qc_reports.mix(SEXDETERRMINE.out.json)

        // Gather versions of all tools used
        versions = versions.mix(SAMTOOLS_DEPTH.out.versions)
        versions = versions.mix(SEXDETERRMINE.out.versions)

    }

    // SOMALIER
    if (!(params.skip_tools && params.skip_tools.split(',').contains('somalier'))) {

        // Somalier sites does not exists
        somalier_sites.ifEmpty{ println("ERROR: Somalier sites is empty or is not found. Put the path to the correct somalier sites in 'somalier_sites' or add 'somalier' to the 'skip_tools'.") }

        if ( true ) { println "[SOMALIER] WARNING: Somalier only accepts the correct complementary sites file as input. Somalier only works with reference genomes from the next list [GATK.GRCh37, Ensembl.GRCh37, GATK.GRCh38, NCBI.GRCh38, hg38, hg19]. Please check that the sites files correspond to the same reference genome input if needed. To specify the correct sites file you can provide one by changing any config that customises the path using or changing: params.somalier_sites / --somalier_sites. You can find the sites files in 'impact_qc/assets/sites/' directory." }

        // RUN SOMALIER
        SOMALIER(input, fa, fai, somalier_sites)

        // Gather all reports generated
        impact_qc_reports = impact_qc_reports.mix(SOMALIER.out.tsv)

        // Gather versions of all tools used 
        versions = versions.mix(SOMALIER.out.versions)

    }

    // VCF file
    // If there is a variant calling tool
    if (params.tools) {

        // BCFTOOLSCUSTOM     
        if (!(params.skip_tools && params.skip_tools.split(',').contains('bcftoolscustom'))) {

            // RUN BCFTOOLS CUSTOM COMMANDS
            BCFTOOLSCUSTOM(vcf.map{meta, vcf -> [ meta + [ file_name: vcf.baseName ], vcf ] })

            // Gather all reports generated
            impact_qc_reports = impact_qc_reports.mix(BCFTOOLSCUSTOM.out.allelic_read_pct)

            // Not plot distribution in MultiQC if 'plotallelicreadpct' is in tools
            if (params.tools && params.tools.split(',').contains('plotallelicreadpct')) {
                impact_qc_reports = impact_qc_reports.mix(BCFTOOLSCUSTOM.out.mqc_allelic_read_pct)
            }
              
            // Gather versions of all tools used 
            versions = versions.mix(BCFTOOLSCUSTOM.out.versions)
        }

        // BCFTOOLSSTATS     
        if (!(params.skip_tools && params.skip_tools.split(',').contains('bcftoolsstats'))) {

            // RUN BCFTOOLS STATS
            BCFTOOLSSTATS(bcftools_stats_results)

            // Gather all reports generated
            impact_qc_reports = impact_qc_reports.mix(BCFTOOLSSTATS.out.stats)

        }        
        
        // VCFTOOLSCUSTOM
        if (!(params.skip_tools && params.skip_tools.split(',').contains('vcftoolscustom'))) {

            VCFTOOLSCUSTOM(vcf.map{meta, vcf -> [ meta + [ file_name: vcf.baseName ], vcf ] }, comb_bed_intervals, [])
        
            // Gather all reports generated
            impact_qc_reports = impact_qc_reports.mix(VCFTOOLSCUSTOM.out.distribution)

            // Not plot GQ distribution in MultiQC if 'plotgq' is in tools
            if (params.tools && params.tools.split(',').contains('plotgq')) {
                impact_qc_reports = impact_qc_reports.mix(VCFTOOLSCUSTOM.out.mqc_gq_distribution)
            }

            // Not plot SB distribution in MultiQC if 'plotsb' is in tools (different types of SB for the different variant callers)
            if (params.tools && params.tools.split(',').contains('plotsb')) {
                impact_qc_reports = impact_qc_reports.mix(VCFTOOLSCUSTOM.out.mqc_sb_distribution)
            }

            // Gather versions of all tools used 
            versions = versions.mix(VCFTOOLSCUSTOM.out.versions)
        }
    
    } else { 
        // If there is not variant calling tool
        if ( true ) { println "[VCF metrics] warning: All the VCF metrics will not be shown since the pipeline configuration does not have any variant calling tool set."}
    }

    emit:
    impact_qc_reports
    versions

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
