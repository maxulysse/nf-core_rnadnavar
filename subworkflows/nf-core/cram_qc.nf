//
// QC on CRAM
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { SAMTOOLS_STATS     } from '../../modules/nf-core/modules/samtools/stats/main'
include { MOSDEPTH           } from '../../modules/nf-core/modules/mosdepth/main'

workflow CRAM_QC {
    take:
        cram                          // channel: [mandatory] meta, cram, crai
        fasta                         // channel: [mandatory] fasta
        fasta_fai                     // channel: [mandatory] fasta_fai
        intervals_bed_combined

    main:
    ch_versions = Channel.empty()
    qc_reports  = Channel.empty()

    // Reports run on cram TODO:
    SAMTOOLS_STATS(cram, fasta.map{ fasta -> [ [ id:fasta.baseName ], fasta ] })
    // TODO: cram_indexed can accept bed file at the end - not implemented yet
    MOSDEPTH(cram.map{meta, cram, crai -> [meta, cram, crai, []]}, fasta.map{ fasta -> [ [ id:fasta.baseName ], fasta ] })

    // Gather all reports generated
    qc_reports = qc_reports.mix(SAMTOOLS_STATS.out.stats)
    qc_reports = qc_reports.mix(MOSDEPTH.out.global_txt,
                                MOSDEPTH.out.regions_txt)

    // Gather versions of all tools used
    ch_versions = ch_versions.mix(MOSDEPTH.out.versions)
    ch_versions = ch_versions.mix(SAMTOOLS_STATS.out.versions)

    emit:
        qc       = qc_reports
        versions = ch_versions // channel: [ versions.yml ]
}
