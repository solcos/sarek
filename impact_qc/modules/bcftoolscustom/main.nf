process BCFTOOLSCUSTOM {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools:1.19--h8b25389_1':
        'biocontainers/bcftools:1.19--h8b25389_1' }"

    input:
    tuple val(meta), path(vcf)
      
    output: 
    tuple val(meta), path("*allelic_read_percentages.tsv")      , emit: allelic_read_pct
    tuple val(meta), path("*allelic_read_percentages_mqc.txt")  , emit: mqc_allelic_read_pct

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
    bcftools query -f '[%CHROM\\t%POS\\t%REF\\t%ALT\\t%GT\\t%DP\\t%AD]\\n' $vcf | 
    awk -v sample=\${id%.bcftoolscustom} 'BEGIN{OFS="\\t"; print "Sample\\tCHROM\\tPOS\\tREF\\tALT\\tGT\\tRef_Read_Percentage\\tAlt_Read_Percentage"} {
        split(\$6, DP, ","); 
        split(\$7, AD, ","); 
        freq_ref = "NA"; 
        freq_alt = "NA"; 
        if (DP[1] > 0) { 
            freq_ref = (AD[1] / DP[1]) * 100; 
            freq_alt = (AD[2] / DP[1]) * 100; 
        } 
        print sample, \$1, \$2, \$3, \$4, \$5, freq_ref, freq_alt 
    }' > ${prefix}_allelic_read_percentages.tsv

    # Alt allelic read percentages for MultiQC
    sample="\${id%.bcftoolscustom}"
    cut -f1 ${prefix}_allelic_read_percentages.tsv > tmp1.txt 
    head -n2 tmp1.txt > tmp.txt
    cut -f8 ${prefix}_allelic_read_percentages.tsv | sed '1d' - >> tmp.txt
    sed -i 's/\$/,/g' tmp.txt

    # Transpose the table to match the MultiQC configuration
    n_cols=\$(head -1 tmp.txt | wc -w)
    for i in \$(seq 1 "\$n_cols"); do
        echo \$(cut -d ' ' -f "\$i" tmp.txt)
    done > \${sample}_alt_allelic_read_percentages_mqc.txt

    # Edit file to achive the desired configuration for MultiQC
    sed -i 's/, /,/g' \${sample}_alt_allelic_read_percentages_mqc.txt
    sed -i 's/,\$//g' \${sample}_alt_allelic_read_percentages_mqc.txt
    sed -i 's/Sample,/Sample /g' \${sample}_alt_allelic_read_percentages_mqc.txt

    # MultiQC plot type
    sed -i "1s/^/# plot_type: 'linegraph'\\n/" \${sample}_alt_allelic_read_percentages_mqc.txt

    # Remove temporary file
    rm tmp*txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}
