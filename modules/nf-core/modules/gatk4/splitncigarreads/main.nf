process GATK4_SPLITNCIGARREADS {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::gatk=3.8" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gatk:3.8--hdfd78af_11':
        'quay.io/biocontainers/gatk4:4.2.6.1--hdfd78af_0' }"

    input:
        tuple val(meta), path(bam), path(bai), path(intervals)
        path  fasta
        path  fai
        path  dict

    output:
        tuple val(meta), path('*.bam'), emit: bam
        tuple val(meta), path('*.bai'), emit: bai
        path  "versions.yml"          , emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${meta.id}"
        def interval_command = intervals ? "--intervals $intervals" : ""

        def avail_mem = 4
        if (!task.memory) {
            log.info '[GATK SplitNCigarReads] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
        } else {
            avail_mem = task.memory.giga
        }
        """
        GenomeAnalysisTK -Xmx${avail_mem}g -Djava.io.tmpdir=. -T SplitNCigarReads \\
            -I $bam \\
            -o ${prefix}.bam \\
            -R $fasta \\
            $interval_command \\
            $args

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            gatk: \$(echo \$(GenomeAnalysisTK --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
        END_VERSIONS
        """
}