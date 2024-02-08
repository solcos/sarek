//
// FASTQ_SCREEN 
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { FASTQSCREEN            } from '../../../modules/impact_qc/fastqscreen/main'

workflow FASTQ_FASTQSCREEN {
    take:
    reads // channel: [mandatory] meta, read
    fastq_screen_conf_db
   
    main:

    versions = Channel.empty()
    reports = Channel.empty()

    if ( true ) { println "[FASTQSCREEN] warning: FastQ_Screen needs a configuration file called 'fastq_screen.conf' provided in the folder 'assets/fastq_screen_db' where the user can modify the mapper in the tool and also uncomment the the databases you want to use FastQ_screen on. Also, in the same folder, the user needs to provide the respective Bowtie indexes of the different species that want to check in order have the database for the FastQ_Screen."}

    FASTQSCREEN(reads, fastq_screen_conf_db) 

    // Gather reports of all tools used
    reports = reports.mix(FASTQSCREEN.out.html)
    reports = reports.mix(FASTQSCREEN.out.png)
    reports = reports.mix(FASTQSCREEN.out.txt)

    // Gather versions of all tools used
    versions = versions.mix(FASTQSCREEN.out.versions)
   
    emit:
    reports
    versions // channel: [ versions.yml ]
}
