process MADINSERTSIZECUSTOM {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/picard:3.1.1--hdfd78af_0' :
        'biocontainers/picard:3.1.1--hdfd78af_0' }"

    input:
    tuple val(meta), path(insertsizemetrics)
    
    output:
    tuple val(meta), path("*.madinsertsizecustom_mqc.tsv"), emit: mqc_madinsertsize
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    # Create patient ID variable for final file
    id="${prefix}"

    # Extract MAD insert size variable from insertsizemetrics
    madinsertsize=\$(head -n8 $insertsizemetrics | tail -n1 | cut -f3) 

    # Echo multiqc config in report
    echo "# id: 'madinsertsizecustom'
    # section_name: 'Custom MAD insert size'
    # namespace: 'madinsertsizecustom'  
    # description: 'Metric from collectinsertsizemetrics, MAD insert size' 
    # plot_type: 'generalstats'
    # pconfig:
    #     - MAD_INSERT_SIZE: 
    #         description: 'The median absolute deviation of the distribution. If the distribution is essentially normal then the standard deviation can be estimated as ~1.4826 * MAD'
    #         format: '{:,.2f}'" > tmp.tsv

    # Echo the names to a file
    echo -e "Sample\\tMAD_INSERT_SIZE" >> tmp.tsv

    # Echo stats
    awk -v var0="\$id" -v var1="\$madinsertsize" 'BEGIN{OFS="\\t"} {print} END{print var0,var1}' tmp.tsv > ${prefix}.madinsertsizecustom_mqc.tsv

    # Remove temporary file
    rm tmp.tsv

    """
}
