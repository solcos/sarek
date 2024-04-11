process BCFTOOLSCUSTOM {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools:1.17--haef29d1_0':
        'biocontainers/bcftools:1.17--haef29d1_0' }"

    input:
    tuple val(meta), path(vcf)
      
    output: 
    tuple val(meta), path("*allelic_read_percentages.tsv"), emit: allelic_read_pct

    path  "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
  
     
    """
    # Create patient ID variable for final file
    id="${prefix}"

    # Allelic read percentages 
    bcftools query -f '[%CHROM\\t%POS\\t%REF\\t%ALT\\t%GT\\t%DP\\t%AD]\\n' $vcf | awk -v sample=\${id} 'BEGIN{OFS="\\t"; print "Sample\\tCHROM\\tPOS\\tREF\\tALT\\tGT\\tRef_Read_Percentage\\tAlt_Read_Percentage"} {split(\$6, DP, ","); split(\$7, AD, ","); freq_ref = "NA"; freq_alt = "NA"; if (DP[1] > 0) { freq_ref = (AD[1] / DP[1]) * 100; freq_alt = (AD[2] / DP[1]) * 100; } print sample, \$1, \$2, \$3, \$4, \$5, freq_ref, freq_alt }' > ${prefix}_allelic_read_percentages.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}
