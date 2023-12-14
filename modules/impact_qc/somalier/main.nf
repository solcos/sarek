process SOMALIER {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::somalier=0.2.18"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/somalier:0.2.18--hb57907c_0':
        'biocontainers/somalier:0.2.18--hb57907c_0' }"

    input:
    tuple val(meta), path(cram), path(crai)
    path  fasta
    path  fasta_fai
    path  sites

    output:
    tuple val(meta), path("*.html"), emit: html 
    tuple val(meta), path("*.tsv") , emit: tsv
    //tuple val(meta), path("*.sample.tsv") , emit: tsv
    //tuple val(meta), path("*.groups.tsv") , emit: tsv

    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reference = fasta ? "${fasta}" : ""

    //if ( !sites ) { warning "[SOMALIER] warning: Somalier only accepts the correct complementary sites file as input. Somalier only works with reference genomes from the next list [GATK.GRCh37, Ensembl.GRCh37, GATK.GRCh38, NCBI.GRCh38, hg38, hg19]. Please check that the sites files correspond to the same reference genome input if needed. To specify the correct sites file you can provide one by changing any config that customises the path using: $params.somalier_sites / --somalier_sites" }

    
    if ( true ) { println "[SOMALIER] warning: Somalier only accepts the correct complementary sites file as input. Somalier only works with reference genomes from the next list [GATK.GRCh37, Ensembl.GRCh37, GATK.GRCh38, NCBI.GRCh38, hg38, hg19]. Please check that the sites files correspond to the same reference genome input if needed. To specify the correct sites file you can provide one by changing any config that customises the path using or changing: params.somalier_sites / --somalier_sites. You can find the sites files in 'assets/sites/' directory." }
    

    """
    mkdir extracted

    somalier extract -d extracted --sites ${sites} -f ${reference} $cram

    somalier relate --infer --output-prefix ${prefix} extracted/*.somalier

    somalier relate --ped ${prefix}.samples.tsv --output-prefix ${prefix} extracted/*.somalier

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        somalier: \$(echo \$(somalier -h 2>&1) | sed -n 's/.*version: \\([0-9.]*\\).*/\\1/p')
    END_VERSIONS 
    """
}
