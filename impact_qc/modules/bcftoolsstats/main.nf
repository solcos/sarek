process BCFTOOLSSTATS {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools:1.19--h8b25389_1' :
        'biocontainers/bcftools:1.19--h8b25389_1' }"
 
    input:
    tuple val(meta), path(stats)

    output: 
    tuple val(meta), path("*bcftools_stats_mqc.tsv"), emit: stats 

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
  
    """
    # Create patient ID variable for final file
    #id="${prefix}"
    id=\$(cat $stats | grep "^PSC" | cut -f3)

    # Extract number of multiallelic variants (MAV) (multiallelic sties from bcftools output)
    multiallelic_sites=\$(cat $stats | grep "^SN" | grep "number of multiallelic sites:" | cut -f4)

    # Extract number of multiallelic SNP variants (MAsnpV) (multiallelic SNP sties from bcftools output)
    multiallelic_snp_sites=\$(cat $stats | grep "^SN" | grep "number of multiallelic SNP sites:" | cut -f4)
    
    # Extract number non-ref hom SNP sites
    non_ref_hom_snp_sites=\$(cat $stats | grep "^PSC" | cut -f5)

    # Extract number het SNP sites
    het_snp_sites=\$(cat $stats | grep "^PSC" | cut -f6)

    # Calculate het/hom ratio
    het_hom_ratio=\$(awk "BEGIN {if (hom != 0) printf \\"%.4f\\", \$het_snp_sites / \$non_ref_hom_snp_sites; else printf \\"%.4f\\", 0}")

    # Echo multiqc config in report
    echo "# id: 'bcftools_stats'
    # section_name: 'Custom bcftools stats'
    # namespace: 'bcftools_stats'  
    # description: 'Metrics from bcftools stats' 
    # plot_type: 'generalstats'
    # pconfig:
    #     - RATIO_HET-HOM: 
    #         description: 'Ratio of heterozygous SNV sites and homozygous SNV sites'
    #         format: '{:,.2f}'
    #     - N_MULTIALLELIC_VARIANTS: 
    #         description: 'Number of multiallelic variants'
    #         format: '{:,.0f}'
    #     - N_MULTIALLELIC_SNP_VARIANTS:
    #         description: 'Number of multiallelic SNP variants'
    #         format: '{:,.0f}'" > tmp.tsv

    # Echo the names to a file
    echo -e "Sample\\tRATIO_HET-HOM\\tN_MULTIALLELIC_VARIANTS\\tN_MULTIALLELIC_SNP_VARIANTS" >> tmp.tsv
    
    # Echo stats
    awk -v var0="\$id" -v var1="\$het_hom_ratio" -v var2="\$multiallelic_sites" -v var3="\$multiallelic_snp_sites" 'BEGIN{OFS="\\t"} {print} END{print var0,var1,var2,var3}' tmp.tsv > ${prefix}.bcftools_stats_mqc.tsv 
                                                            
    # Remove temporary file
    rm tmp.tsv 
    """
}
