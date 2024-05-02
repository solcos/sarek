process FLAGSTATCUSTOM {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.17--h00cdaf9_0' :
        'biocontainers/samtools:1.17--h00cdaf9_0' }"

    input:
    tuple val(meta), path(flagstat)
    
    output:
    tuple val(meta), path("*.flagstatcustom_mqc.tsv"), emit: mqc_paired_reads_diff_chr_mapq5_pct
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    # Create patient ID variable for final file
    id="${prefix}"

    # Clean diff chr variable from flagstat
    diff_chr_mapq5_string=\$(tail -n1 $flagstat)
    diff_chr_mapq5_clean="\${diff_chr_mapq5_string%% *}"
    diff_chr_mapq5="\${diff_chr_mapq5_clean//[^0-9]/}"  

    # Clean total number of passed reads from flagstat
    total_passed_reads_string=\$(head -n1 $flagstat)
    total_passed_reads_clean="\${total_passed_reads_string%% *}"
    total_passed_reads="\${total_passed_reads_clean//[^0-9]/}" 

    # Compute percentage
    pct_diff_chr_mapq5=\$(awk "BEGIN {if (total_passed_reads != 0) printf \\"%.4f\\", \$diff_chr_mapq5 / \$total_passed_reads; else printf \\"%.4f\\", 0}")

    # Echo multiqc config in report
    echo "# id: 'flagstatcustom'
    # section_name: 'Custom flagstat'
    # namespace: 'flagstatcustom'  
    # description: 'Metric from samtools flagstat' 
    # plot_type: 'generalstats'
    # pconfig:
    #     - PCT_DIFF_CHR_MAPQ5: 
    #         description: 'Percentage of with mate mapped to a different chr (mapQ >= 5) passed'
    #         format: '{:,.2f}'" > tmp.tsv

    # Echo the names to a file
    echo -e "Sample\\tPCT_DIFF_CHR_MAPQ5" >> tmp.tsv

    # Echo stats
    awk -v var0="\$id" -v var1="\$pct_diff_chr_mapq5" 'BEGIN{OFS="\\t"} {print} END{print var0,var1}' tmp.tsv > ${prefix}.flagstatcustom_mqc.tsv

    # Remove temporary file
    rm tmp.tsv
    
    """
}
