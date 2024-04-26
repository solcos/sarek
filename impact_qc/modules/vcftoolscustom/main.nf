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
    tuple val(meta), path("*.{FORMAT,INFO}")                                , emit: distribution
    tuple val(meta), path("*_GQ_distribution_mqc.txt")                      , emit: mqc_gq_distribution
    tuple val(meta), path("*_{SP,SRP-SAP-EPP,FS,SB}_distribution_mqc.txt")  , emit: mqc_sb_distribution
    
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
    
    ## GQ distribution
    vcftools \\
            $input_file \\
            --out $prefix \\
            --extract-FORMAT-info GQ \\
            $args

    ## Strand Bias (SB) (for the different variant callers) (DeepVariant does not output SB in the VCF)
    # Bcftools mpileup
    if [[ $variant_file == *"bcftools"* ]]; then
        
        vcftools \\
            $input_file \\
            --out $prefix \\
            --extract-FORMAT-info SP \\
            $args

        # Remove variant caller for the sample name id (for mqc)
        sample="\${id%.bcftools}"

        # Prepare files for MultiQC report (only SB distribution of Bcftools) 
        # SP distribution
        cut -f3 *SP.FORMAT > tmp.bcftools.txt
        sed -i "1s/^/Sample\\n/" tmp.bcftools.txt
        sed -i 's/\$/,/g' tmp.bcftools.txt
    
        # Transpose the table to match the MultiQC configuration
        n_cols=\$(head -1 tmp.bcftools.txt | wc -w)
        for i in \$(seq 1 "\$n_cols"); do
            echo \$(cut -d ' ' -f "\$i" tmp.bcftools.txt)
        done > \${sample}_SP_distribution_mqc.txt
    
        # Edit file to achive the desired configuration for MultiQC
        sed -i 's/, /,/g' \${sample}_SP_distribution_mqc.txt
        sed -i 's/,\$//g' \${sample}_SP_distribution_mqc.txt
        sed -i 's/Sample,/Sample /g' \${sample}_SP_distribution_mqc.txt
     
        # MultiQC plot type
        sed -i "1s/^/# plot_type: 'linegraph'\\n/" \${sample}_SP_distribution_mqc.txt
    
        # Remove temporary file
        rm tmp.bcftools.txt
    
    # Freebayes
    elif [[ $variant_file == *"freebayes"* ]]; then
        
        vcftools \\
            $input_file \\
            --out $prefix \\
            --get-INFO SRP --get-INFO SAP --get-INFO EPP \\
            $args

        # Remove variant caller for the sample name id (for mqc)
        sample="\${id%.freebayes}"

        ## Prepare files for MultiQC report (only SB distribution of Freebayes) 
        # SRP, SAP and EPP distributions
        cut -f5 *INFO > tmp.freebayes.srp.txt
        cut -f6 *INFO > tmp.freebayes.sap.txt
        cut -f7 *INFO > tmp.freebayes.epp.txt

        # Iterate through distributions and computing mean if there are more than one value
        for file in tmp.freebayes.*.txt; do
            while IFS= read -r line; do
                # Check if the line contains a comma
                if [[ "\$line" == *","* ]]; then
                    # Split the line by commas
                    IFS=',' read -ra values <<< "\$line"
                    sum=0
                    count=0
                    # Calculate the sum of values and count the number of values
                    for value in "\${values[@]}"; do
                        sum=\$(awk -v val1="\$sum" -v val2="\$value" "BEGIN { print val1 + val2 }")
                        ((count++))
                    done
                    # Calculate the mean
                    mean=\$(awk -v val3="\$sum" -v val4="\$count" "BEGIN { printf \\"%.5f\\", val3 / val4 }")
                    echo "\$mean"
                else
                    # If no comma found, print the original line
                    echo "\$line"
                fi
            done < \$file > temp.txt
            mv temp.txt \$file
        done

        # Formating different tmp files adding 'Sample' at the top and then a 'comma' after each row
        sed -i "1s/^/Sample\\n/" tmp.freebayes.*.txt
        sed -i 's/\$/,/g' tmp.freebayes.*.txt
 
        # Transpose the table to match the MultiQC configuration
        for tmp in tmp.freebayes.*.txt; do
            n_cols=\$(head -1 \$tmp | wc -w)
            for i in \$(seq 1 "\$n_cols"); do
                echo \$(cut -d ' ' -f "\$i" \$tmp)
            done > t_\$tmp
        done

        # Join different files
        cat t_tmp* > \${sample}_SRP-SAP-EPP_distribution_mqc.txt

        # Edit file to achive the desired configuration for MultiQC
        sed -i 's/, /,/g' \${sample}_SRP-SAP-EPP_distribution_mqc.txt
        sed -i 's/,\$//g' \${sample}_SRP-SAP-EPP_distribution_mqc.txt
        sed -i 's/Sample,/Sample /g' \${sample}_SRP-SAP-EPP_distribution_mqc.txt
 
        # MultiQC plot type
        sed -i "1s/^/# plot_type: 'linegraph'\\n/" \${sample}_SRP-SAP-EPP_distribution_mqc.txt
 
        # Remove temporary file
        rm tmp.freebayes.*.txt t_*

    # Haplotypecaller
    elif [[ $variant_file == *"haplotypecaller"* ]]; then

        vcftools \\
            $input_file \\
            --out $prefix \\
            --get-INFO FS \\
            $args
    
        # Remove variant caller for the sample name id (for mqc)
        sample="\${id%.haplotypecaller.filtered}"

        ## Prepare files for MultiQC report (only SB distribution of HaplotypeCaller) 
        # FS distribution
        cut -f5 *INFO | tail -n +2 > tmp.haplotypecaller.txt
        sed -i "1s/^/\${sample}\\n/" tmp.haplotypecaller.txt
        sed -i "1s/^/Sample\\n/" tmp.haplotypecaller.txt
        sed -i 's/\$/,/g' tmp.haplotypecaller.txt
    
        # Transpose the table to match the MultiQC configuration
        n_cols=\$(head -1 tmp.haplotypecaller.txt | wc -w)
        for i in \$(seq 1 "\$n_cols"); do
            echo \$(cut -d ' ' -f "\$i" tmp.haplotypecaller.txt)
        done > \${sample}_FS_distribution_mqc.txt
    
        # Edit file to achive the desired configuration for MultiQC
        sed -i 's/, /,/g' \${sample}_FS_distribution_mqc.txt
        sed -i 's/,\$//g' \${sample}_FS_distribution_mqc.txt
        sed -i 's/Sample,/Sample /g' \${sample}_FS_distribution_mqc.txt
     
        # MultiQC plot type
        sed -i "1s/^/# plot_type: 'linegraph'\\n/" \${sample}_FS_distribution_mqc.txt
    
        # Remove temporary file
        rm tmp.haplotypecaller.txt

    # Strelka
    elif [[ $variant_file == *"strelka"* ]]; then

        vcftools \\
            $input_file \\
            --out $prefix \\
            --extract-FORMAT-info SB \\
            $args
    
        # Remove variant caller for the sample name id (for mqc)
        sample="\${id%.strelka.variants}"

        ## Prepare files for MultiQC report (only SB distribution of Strelka) 
        # SB distribution
        cut -f3 *SB.FORMAT | tail -n +2 > tmp.strelka.txt
        sed -i "1s/^/\${sample}\\n/" tmp.strelka.txt
        sed -i "1s/^/Sample\\n/" tmp.strelka.txt
        sed -i 's/\$/,/g' tmp.strelka.txt
    
        # Transpose the table to match the MultiQC configuration
        n_cols=\$(head -1 tmp.strelka.txt | wc -w)
        for i in \$(seq 1 "\$n_cols"); do
            echo \$(cut -d ' ' -f "\$i" tmp.strelka.txt)
        done > \${sample}_SB_distribution_mqc.txt
    
        # Edit file to achive the desired configuration for MultiQC
        sed -i 's/, /,/g' \${sample}_SB_distribution_mqc.txt
        sed -i 's/,\$//g' \${sample}_SB_distribution_mqc.txt
        sed -i 's/Sample,/Sample /g' \${sample}_SB_distribution_mqc.txt
     
        # MultiQC plot type
        sed -i "1s/^/# plot_type: 'linegraph'\\n/" \${sample}_SB_distribution_mqc.txt
    
        # Remove temporary file
        rm tmp.strelka.txt

    else
        touch test.FORMAT test.INFO
        rm test.FORMAT test.INFO
        echo "WARNING \${id}: There is no 'strand bias' distribution for the variant caller selected"
    fi

    # Prepare files for MultiQC report (only GQ distribution) 
    # GQ distribution
    cut -f3 *GQ.FORMAT | tail -n +2 > tmp.txt
    sed -i "1s/^/\${sample}\\n/" tmp.txt
    sed -i "1s/^/Sample\\n/" tmp.txt
    sed -i 's/\$/,/g' tmp.txt

    # Transpose the table to match the MultiQC configuration
    n_cols=\$(head -1 tmp.txt | wc -w)
    for i in \$(seq 1 "\$n_cols"); do
        echo \$(cut -d ' ' -f "\$i" tmp.txt)
    done > \${sample}_GQ_distribution_mqc.txt

    # Edit file to achive the desired configuration for MultiQC
    sed -i 's/, /,/g' \${sample}_GQ_distribution_mqc.txt
    sed -i 's/,\$//g' \${sample}_GQ_distribution_mqc.txt
    sed -i 's/Sample,/Sample /g' \${sample}_GQ_distribution_mqc.txt
 
    # MultiQC plot type
    sed -i "1s/^/# plot_type: 'linegraph'\\n/" \${sample}_GQ_distribution_mqc.txt

    # Remove temporary file
    rm tmp.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vcftools: \$(echo \$(vcftools --version 2>&1) | sed 's/^.*VCFtools (//;s/).*//')
    END_VERSIONS
    """
}
