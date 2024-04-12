process FASTPSTATS {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastp:0.23.4--h5f740d0_0' :
        'biocontainers/fastp:0.23.4--h5f740d0_0' }"
 
    input:
    tuple val(meta), path(json)
      
    output: 
    tuple val(meta), path("*fastp_stats_mqc.tsv"), emit: fastpstats 

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
  
    """
    # Create patient ID variable for final file
    id="${prefix}"

    # Extract number of sequenced bases before and after filtering
    total_bases_before=\$(grep -A25 "summary" $json | grep -A9 "before_filtering" | grep -o '"total_bases":[0-9]*' | cut -d ':' -f2)
    total_bases_after=\$(grep -A25 "summary" $json | grep -A9 "after_filtering" | grep -o '"total_bases":[0-9]*' | cut -d ':' -f2)

    # Extract the number of sequenced bases with quality > 30 before and after filtering
    total_bases_q30_before=\$(grep -A25 "summary" $json | grep -A9 "before_filtering" | grep -o '"q30_bases":[0-9]*' | cut -d ':' -f2)
    total_bases_q30_after=\$(grep -A25 "summary" $json | grep -A9 "after_filtering" | grep -o '"q30_bases":[0-9]*' | cut -d ':' -f2)

    # Extract number of reads before and after filtering
    total_reads_before=\$(grep -A25 "summary" $json | grep -A9 "before_filtering" | grep -o '"total_reads":[0-9]*' | cut -d ':' -f2)
    total_reads_after=\$(grep -A25 "summary" $json | grep -A9 "after_filtering" | grep -o '"total_reads":[0-9]*' | cut -d ':' -f2)

    # Calculate percentage passed (rounded to two decimal places)
    percentage_passed=\$(awk "BEGIN { printf \\"%.2f\\", (\$total_reads_after * 100 / \$total_reads_before) }")

    # Calculate percentage reads do not pass the filter
    percentage_failed=\$(echo \$percentage_passed | awk '{ print 100 - \$1}')

    # Echo multiqc config in report
    echo "# id: 'fastp_stats'" > tmp.tsv
    echo "# section_name: 'Custom fastp stats'" >> tmp.tsv
    echo "# description: 'Metrics from fastp stats'" >> tmp.tsv
    echo "# plot_type: 'generalstats'" >> tmp.tsv

    # Echo names to a file
    echo -e "Sample\\tN_SEQ_BASES_BEFORE\\tN_SEQ_BASES_AFTER\\tN_SEQ_BASES_Q30_BEFORE\\tN_SEQ_BASES_Q30_AFTER\\tN_READS_BEFORE\\tN_READS_AFTER\\tPCT_PASSED_READS\\tPCT_FAILED_READS" >> tmp.tsv
    
    # Echo stats
    awk -v var0="\$id" -v var1="\$total_bases_before" -v var2="\$total_bases_after" -v var3="\$total_bases_q30_before" -v var4="\$total_bases_q30_after" -v var5="\$total_reads_before" -v var6="\$total_reads_after" -v var7="\$percentage_passed" -v var8="\$percentage_failed" 'BEGIN{OFS="\t"} {print} END{print var0,var1,var2,var3,var4,var5,var6,var7,var8}' tmp.tsv > ${prefix}.fastp_stats_mqc.tsv 
    
    # Remove temporary file
    rm tmp.tsv
      
    """
}
