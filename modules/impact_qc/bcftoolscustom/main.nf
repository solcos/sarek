process BCFTOOLSCUSTOM {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools:1.17--haef29d1_0':
        'biocontainers/bcftools:1.17--haef29d1_0' }"

    input:
    tuple val(meta),  path(vcf)//, path(tbi)
    tuple val(meta2), path(cram), path(crai)
    path fasta
    path fasta_fai
 
    output:
    //tuple val(meta), path("*het-hom_ratio.txt"), emit: ratio
    //tuple val(meta), path("*dp_gq_distribution.txt"), emit: distribution
    tuple val(meta), path("*distributions.txt"), emit: distributions2
    path  "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    # Compute het/hom ratio
    #bcftools view --no-header -O v $vcf $args | awk 'BEGIN {FS="\\t"; hom=0; het=0} {split(\$9, format, ":"); for (i = 10; i <= NF; i++) {split(\$i, geno, ":"); if (geno[format["GT"]+1]=="0/0" || geno[format["GT"]+1]=="1/1") hom++; if (geno[format["GT"]+1]=="0/1" || geno[format["GT"]+1]=="1/0") het++}} END {if (hom != 0) { ratio = het / hom } else { ratio = "NaN" } print "Total Homozygous:", hom; print "Total Heterozygous:", het; print "Heterozygous/Homozygous Ratio:", ratio }' > ${prefix}_het-hom_ratio.txt

    # Extract all different DP and GQ values for all the variants/sample
    #bcftools query -f '[%GT\\t%DP\\t%GQ\\t]\\n' $vcf | awk 'BEGIN {print "GT\\tDP\\tGQ"} {print}' > ${prefix}_dp_gq_distribution.txt

    # Extract information of strand bias (FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/DP,FORMAT/SCR,FORMAT/SP,INFO/AD,INFO/ADF,INFO/ADR,INFO/SCR)
    bcftools mpileup -a "FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/DP,FORMAT/SP" --fasta-ref $fasta $cram | bcftools call -mv -Ov | bcftools view --output-file ${prefix}_annotated_format.vcf.gz --output-type z
    
    bcftools query -f '[%CHROM\\t%POS\\t%AD\\t%ADF\\t%ADR\\t%DP\\t%SP]\\n' ${prefix}_annotated_format.vcf.gz | awk 'BEGIN {print "CHROM\\tPOS\\tAD\\tADF\\tADR\\tDP\\tSP"} {print}' > ${prefix}_distributions.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}
