//
// Subworkflow: Run GATK4 SplitNCigarReads without intervals, merge and index BAM file.
//
include { GATK4_SPLITNCIGARREADS } from '../../modules/nf-core/modules/gatk4/splitncigarreads/main'
include { SAMTOOLS_INDEX         } from '../../modules/nf-core/modules/samtools/index/main'

workflow SPLITNCIGAR {
    take:
        bam             // channel: [ val(meta), [ bam ], [bai] ]
        fasta           // channel: [ fasta ]
        fasta_fai       // channel: [ fai ]
        fasta_dict      // channel: [ dict ]
        intervals       // channel: [ interval_list]

    main:

        ch_versions       = Channel.empty()
        bam = bam.map{meta, bam, bai -> [meta, bam, bai, []]}
        GATK4_SPLITNCIGARREADS (
            bam,
            fasta,
            fasta_fai,
            fasta_dict
        )
        splitncigar_bam_bai = GATK4_SPLITNCIGARREADS.out.bam.join(GATK4_SPLITNCIGARREADS.out.bai, failOnDuplicate: true, failOnMismatch: true)

        ch_versions = ch_versions.mix(GATK4_SPLITNCIGARREADS.out.versions)



    emit:
        bam_bai     = splitncigar_bam_bai
        versions    = ch_versions
}
