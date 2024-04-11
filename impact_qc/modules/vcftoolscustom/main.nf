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
    tuple val(meta), path("*.FORMAT")                   , emit: format
    //tuple val(meta), path("*.INFO")                   , emit: info
    
    path "versions.yml"                               , emit: versions

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

    # GQ distribution
    vcftools \\
            $input_file \\
            --out $prefix \\
            --extract-FORMAT-info GQ \\
            $args

    # VCF strand bias
    #vcftools \\
    #        $input_file \\
    #        --out $prefix \\
    #        --extract-FORMAT-info SB \\
    #        $args

    # Bcftools mpileup
    if [[ $variant_file == *"bcftools"* ]]; then
        
        vcftools \\
            $input_file \\
            --out $prefix \\
            --extract-FORMAT-info SP \\
            $args
    
    # Freebayes
    elif [[ $variant_file == *"freebayes"* ]]; then
        
        vcftools \\
            $input_file \\
            --out $prefix \\
            --get-INFO SRP --get-INFO SAP --get-INFO EPP \\
            $args

    # Haplotypecaller
    elif [[ $variant_file == *"haplotypecaller"* ]]; then

        vcftools \\
            $input_file \\
            --out $prefix \\
            --get-INFO FS \\
            $args
    
    # Strelka
    elif [[ $variant_file == *"strelka"* ]]; then

        vcftools \\
            $input_file \\
            --out $prefix \\
            --extract-FORMAT-info SB \\
            $args

    else
        touch test.FORMAT test.INFO
    fi
 
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vcftools: \$(echo \$(vcftools --version 2>&1) | sed 's/^.*VCFtools (//;s/).*//')
    END_VERSIONS
    """
}
