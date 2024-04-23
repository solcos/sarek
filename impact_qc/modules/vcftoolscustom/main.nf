process VCFTOOLSCUSTOM {
    tag "$meta.id"
    label 'process_single'
    label 'error_ignore'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vcftools:0.1.16--he513fc3_4' :
        'biocontainers/vcftools:0.1.16--he513fc3_4' }"

    input:
    tuple val(meta), path(variant_file)
    path  bed
    path  diff_variant_file
   
    output:
    tuple val(meta), path("*.{FORMAT,INFO}")            , emit: distribution
    tuple val(meta), path("*_mqc.txt")                  , emit: mqc_gq_distribution
    
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args_list = args.tokenize()
    
     def bed_arg  = (args.contains('--bed')) ? "--bed ${bed}" :
        (args.contains('--exclude-bed')) ? "--exclude-bed ${bed}" :
        (args.contains('--hapcount')) ? "--hapcount ${bed}" : ''
    args_list.removeIf { it.contains('--bed') }
    args_list.removeIf { it.contains('--exclude-bed') }
    args_list.removeIf { it.contains('--hapcount') }

    def diff_variant_arg = (args.contains('--diff')) ? "--diff ${diff_variant_file}" :
        (args.contains('--gzdiff')) ? "--gzdiff ${diff_variant_file}" :
        (args.contains('--diff-bcf')) ? "--diff-bcf ${diff_variant_file}" : ''
    args_list.removeIf { it.contains('--diff') }
    args_list.removeIf { it.contains('--gzdiff') }
    args_list.removeIf { it.contains('--diff-bcf') }

    def input_file = ("$variant_file".endsWith(".vcf")) ? "--vcf ${variant_file}" :
        ("$variant_file".endsWith(".vcf.gz")) ? "--gzvcf ${variant_file}" :
        ("$variant_file".endsWith(".bcf")) ? "--bcf ${variant_file}" : ''

    """
    id="${prefix}"
    
    # GQ distribution
    vcftools \\
            $input_file \\
            --out $prefix \\
            --extract-FORMAT-info GQ \\
            $args

    # Bcftools mpileup
    if [[ $variant_file == *"bcftools"* ]]; then
        
        vcftools \\
            $input_file \\
            --out $prefix \\
            --extract-FORMAT-info SP \\
            $args

        # Remove variant caller for the sample name id
        sample="\${id%.bcftools}"
    
    # Freebayes
    elif [[ $variant_file == *"freebayes"* ]]; then
        
        vcftools \\
            $input_file \\
            --out $prefix \\
            --get-INFO SRP --get-INFO SAP --get-INFO EPP \\
            $args

        # Remove variant caller for the sample name id
        sample="\${id%.freebayes}"

    # Haplotypecaller
    elif [[ $variant_file == *"haplotypecaller"* ]]; then

        vcftools \\
            $input_file \\
            --out $prefix \\
            --get-INFO FS \\
            $args
    
        # Remove variant caller for the sample name id
        sample="\${id%.haplotypecaller}"

    # Strelka
    elif [[ $variant_file == *"strelka"* ]]; then

        vcftools \\
            $input_file \\
            --out $prefix \\
            --extract-FORMAT-info SB \\
            $args
    
        # Remove variant caller for the sample name id
        sample="\${id%.strelka}"

    else
        touch test.FORMAT test.INFO
        rm test.FORMAT test.INFO
        echo "WARNING \${id}: There is no 'strand bias' distribution for the variant caller selected"
    fi

    # Prepare files for MultiQC
    # GQ distribution
    cut -f3 *GQ.FORMAT > tmp.txt
    sed -i "1s/^/Sample\\n/" tmp.txt
    sed -i 's/\$/,/g' tmp.txt

    # Transpose the table to match the MultiQC configuration
    n_cols=\$(head -1 tmp.txt | wc -w)
    for i in \$(seq 1 "\$n_cols"); do
        echo \$(cut -d ' ' -f "\$i" tmp.txt)
    done > \${sample}_GQ.FORMAT_mqc.txt

    # Edit file to achive the desired configuration for MultiQC
    sed -i 's/, /,/g' \${sample}_GQ.FORMAT_mqc.txt
    sed -i 's/,\$//g' \${sample}_GQ.FORMAT_mqc.txt
    sed -i 's/Sample,/Sample /g' \${sample}_GQ.FORMAT_mqc.txt
 
    # MultiQC plot type
    sed -i "1s/^/# plot_type: 'linegraph'\\n/" \${sample}_GQ.FORMAT_mqc.txt

    # Remove temporary file
    rm tmp.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vcftools: \$(echo \$(vcftools --version 2>&1) | sed 's/^.*VCFtools (//;s/).*//')
    END_VERSIONS
    """
}
