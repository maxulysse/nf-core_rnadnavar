//
// Core workflow of the RNA/DNA variant calling pipeline
//
include { BAM_GATK_PREPROCESSING                                   } from '../bam_gatk_preprocessing/main'
// For now only matched supported
// include { BAM_VARIANT_CALLING                                      } from '../variant_calling/main'
// // Can we just call normalization here?
// include { VCF_NORMALIZE                                            } from '../normalize_vcf_variants/main'
// // Can we just call the consensus module here?
// include { VCF_CONSENSUS                                            } from '../consensus/main'
// // maybe just call VEP here?
// include { VCF_ANNOTATE                                             } from '../annotate/main'
// include { MAF_BASIC_FILTERING as FILTERING                         } from '../../../modules/local/filter_variants'


workflow BAM_VARIANT_CALLING_PRE_POST_PROCESSING {
    take:
        step                   // step to start with
        tools
        skip_tools
        ch_input_sample        // input from CSV if applicable
        ch_genome_bam          // input from mapping
        fasta                  // fasta reference file
        fasta_fai              // fai for fasta file
        dict                   //
        dbsnp
        dbsnp_tbi
        pon
        pon_tbi
        germline_resource
        germline_resource_tbi
        intervals
        intervals_for_preprocessing
        ch_interval_list_split
        intervals_bed_gz_tbi
        intervals_bed_combined
        vcf_consensus_dna      // to repeat rescue consensus
        vcfs_status_dna       // to repeat rescue consensus

    main:
        ch_reports   = Channel.empty()
        ch_versions  = Channel.empty()
        ch_genome_bam.dump(tag:"ch_genome_bam")
    // GATK PREPROCESSING - See: https://gatk.broadinstitute.org/hc/en-us/articles/360035535912-Data-pre-processing-for-variant-discovery
        BAM_GATK_PREPROCESSING(
            step,                   // Mandatory, step to start with - should be mapping for second pass
            tools,
            ch_genome_bam,        // channel: [mandatory] [meta, [bam]]
            skip_tools,           // channel: [mandatory] skip_tools
            params.save_output_as_bam,   // channel: [mandatory] save_output_as_bam
            fasta,                       // channel: [mandatory] fasta
            fasta_fai ,                  // channel: [mandatory] fasta_fai
            dict,
            germline_resource,           // channel: [optional]  germline_resource
            germline_resource_tbi,       // channel: [optional]  germline_resource_tbi
            intervals,                   // channel: [mandatory] intervals/target regions
            intervals_for_preprocessing, // channel: [mandatory] intervals_for_preprocessing/wes
            ch_interval_list_split,
            ch_input_sample
        )

        ch_cram_variant_calling = GATK_PREPROCESSING.out.ch_cram_variant_calling
        ch_versions = ch_versions.mix(GATK_PREPROCESSING.out.versions)
        ch_reports = ch_reports.mix(GATK_PREPROCESSING.out.ch_reports)

        ch_cram_variant_calling.dump(tag:"[STEP8 RNA_FILTERING] ch_cram_variant_calling")
        intervals_bed_gz_tbi.dump(tag:"[STEP8 RNA_FILTERING] intervals_bed_gz_tbi")
        pon.dump(tag:"[STEP8 RNA_FILTERING] pon")
    // STEP 3: VARIANT CALLING
//         VARIANT_CALLING( tools,
//             ch_cram_variant_calling,
//             fasta,
//             fasta_fai,
//             dbsnp,
//             dbsnp_tbi,
//             dict,
//             germline_resource,
//             germline_resource_tbi,
//             intervals,
//             intervals_bed_gz_tbi,
//             intervals_bed_combined,
//             pon,
//             pon_tbi,
//             ch_input_sample
//         )
//         cram_vc_pair     = VARIANT_CALLING.out.cram_vc_pair  // use same crams for force calling later
//         vcf_to_normalize = VARIANT_CALLING.out.vcf
//         contamination    = VARIANT_CALLING.out.contamination_table
//         segmentation     = VARIANT_CALLING.out.segmentation_table
//         orientation      = VARIANT_CALLING.out.artifact_priors
//         ch_versions      = ch_versions.mix(VARIANT_CALLING.out.versions)
//         ch_reports       = ch_reports.mix(VARIANT_CALLING.out.reports)
//
//
//     // STEP 4: NORMALIZE
//        NORMALIZE (tools,
//                   vcf_to_normalize,
//                   fasta,
//                   ch_input_sample)
//        ch_versions = ch_versions.mix(NORMALIZE.out.versions)
//        vcf_normalized = NORMALIZE.out.vcf
//
//
//     // STEP 5: ANNOTATE
//         ANNOTATE(tools,
//             vcf_normalized, // second pass TODO: make it optional
//             fasta,
//             ch_input_sample // first pass
//             )
//
//         ch_versions = ch_versions.mix(ANNOTATE.out.versions)
//         ch_reports  = ch_reports.mix(ANNOTATE.out.reports)
//
//     // STEP 6: CONSENSUS
//         CONSENSUS ( tools,
//                     ANNOTATE.out.maf_ann,
//                     cram_vc_pair,  // from previous variant calling
//                     dict,
//                     fasta,
//                     fasta_fai,
//                     germline_resource,
//                     germline_resource_tbi,
//                     intervals,
//                     intervals_bed_gz_tbi,
//                     intervals_bed_combined,
//                     pon,
//                     pon_tbi,
//                     vcf_consensus_dna, // null when first pass
//                     vcfs_status_dna, // null when first pass
//                     ch_input_sample,
//                     contamination,
//                     segmentation,
//                     orientation
//                            )
//     // STEP 7: FILTERING
//         if (tools.split(',').contains('filtering')) {
//             FILTERING(CONSENSUS.out.maf, fasta)
//
//             FILTERING.out.maf.branch{
//                                      dna: it[0].status < 2
//                                      rna: it[0].status == 2
//                                      }.set{filtered_maf}
//             filtered_maf_rna = filtered_maf.rna
//             filtered_maf_dna = filtered_maf.dna
//         } else{
//             filtered_maf = Channel.empty()
//             filtered_maf_rna = Channel.empty()
//             filtered_maf_dna = Channel.empty()
//
//         }
//
//     emit:
//         vcf_consensus_dna               = CONSENSUS.out.vcf_consensus_dna
//         vcfs_status_dna                 = CONSENSUS.out.vcfs_status_dna
//         maf                             = filtered_maf
//         maf_rna                         = filtered_maf_rna
//         maf_dna                         = filtered_maf_dna
//         versions                        = ch_versions                                                         // channel: [ versions.yml ]
//         reports                         = ch_reports
}
