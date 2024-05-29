process FASTQSCREEN {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastq-screen:0.15.2--pl5321hdfd78af_0' :
        'biocontainers/fastq-screen:0.15.2--pl5321hdfd78af_0' }"

    input:
    tuple val(meta), path(reads)
    path fastq_screen_conf_db
    

    output:
    tuple val(meta), path('*.html')           , emit: html
    tuple val(meta), path('*.png')            , emit: png
    tuple val(meta), path('*.txt')            , emit: txt
    path "versions.yml"                       , emit: versions
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
 
    // Added soft-links to original fastqs for consistent naming in MultiQC
    if (meta.single_end) {
        """
        [ ! -f  ${prefix}.fastq.gz ] && ln -sf $reads ${prefix}.fastq.gz

        # Put the conf file to the correct folder
        #cp fastq_screen.conf /usr/local/share/fastq-screen-0.15.2-0/fastq_screen.conf

        # Put the databases to the root folder in order to be used and be the same as in the conf file
        #cp *bt* /.

        # Exctract which aligner is in the conf file
        aligner_conf=\$(cat fastq_screen.conf | grep BOWTIE2 | cut -c1)

        # Create aligner tool variable
        if [ "\$aligner_conf" = "#" ]; then
            aligner_tool="bowtie"
        else
            aligner_tool="bowtie2"
        fi

        # Execute fastq_screen
        fastq_screen \\
            --conf fastq_screen.conf \\
            --force \\
            --aligner \${aligner_tool} \\
            --threads $task.cpus \\
            ${prefix}_1.fastq.gz \\
            $args
            
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fastq_screen: \$(fastq_screen --version 2>&1 | sed -e "s/FastQ Screen //g" | cut -c2-)
        END_VERSIONS
        """
    } else { 
        """
        [ ! -f  ${prefix}_1.fastq.gz ] && ln -sf ${reads[0]} ${prefix}_1.fastq.gz
        [ ! -f  ${prefix}_2.fastq.gz ] && ln -sf ${reads[1]} ${prefix}_2.fastq.gz

        # Put the conf file to the correct folder
        #cp fastq_screen.conf /usr/local/share/fastq-screen-0.15.2-0/fastq_screen.conf
        
        # Put the databases to the root folder in order to be used and be the same as in the conf file
        #cp *bt* /.
 
        # Exctract which aligner is in the conf file
        aligner_conf=\$(cat fastq_screen.conf | grep BOWTIE2 | cut -c1)

        # Create aligner tool variable
        if [ "\$aligner_conf" = "#" ]; then
            aligner_tool="bowtie"
        else
            aligner_tool="bowtie2"
        fi

        # Execute fastq_screen
        fastq_screen \\
            --conf fastq_screen.conf \\
            --force \\
            --aligner \${aligner_tool} \\
            --threads $task.cpus \\
            ${prefix}_1.fastq.gz \\
            ${prefix}_2.fastq.gz \\
            $args
 
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fastq_sceen: \$(fastq_screen --version 2>&1 | sed -e "s/FastQ Screen //g" | cut -c2-)
        END_VERSIONS
        """
    }
}
