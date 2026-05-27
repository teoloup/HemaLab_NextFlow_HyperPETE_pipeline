#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { FASTP } from './modules/fastp'
include { BWA_MEM } from './modules/bwa_mem'
include { SAMTOOLS_VIEW } from './modules/samtools_view'
include { SAMTOOLS_SORT as SORT_PRE_UMI } from './modules/samtools_sort'
include { SAMTOOLS_SORT as SORT_UMI2 } from './modules/samtools_sort'
include { SAMTOOLS_SORT as SORT_STRICT } from './modules/samtools_sort'
include { SAMTOOLS_INDEX as INDEX_PRE_UMI } from './modules/samtools_index'
include { SAMTOOLS_INDEX as INDEX_UMI2 } from './modules/samtools_index'
include { SAMTOOLS_INDEX as INDEX_STRICT } from './modules/samtools_index'
include { SAMTOOLS_INDEX as INDEX_RG_UMI2 } from './modules/samtools_index'
include { SAMTOOLS_INDEX as INDEX_RG_STRICT } from './modules/samtools_index'
include { SAMTOOLS_FLAGSTAT } from './modules/samtools_flagstat'
include { MOSDEPTH as MOSDEPTH_BEFORE } from './modules/mosdepth'
include { MOSDEPTH as MOSDEPTH_AFTER } from './modules/mosdepth'
include { GENCORE as GENCORE_UMI2 } from './modules/gencore'
include { GENCORE as GENCORE_STRICT } from './modules/gencore'
include { GATK_ADD_RG as ADD_RG_UMI2 } from './modules/gatk_add_rg'
include { GATK_ADD_RG as ADD_RG_STRICT } from './modules/gatk_add_rg'
include { GATK_MUTECT2 as MUTECT_UMI2 } from './modules/gatk_mutect2'
include { GATK_MUTECT2 as MUTECT_STRICT } from './modules/gatk_mutect2'
include { GATK_FILTER_MUTECT_CALLS as FILTER_MUTECT_UMI2 } from './modules/gatk_filter_mutect_calls'
include { GATK_FILTER_MUTECT_CALLS as FILTER_MUTECT_STRICT } from './modules/gatk_filter_mutect_calls'
include { BCFTOOLS_NORM as NORM_MUTECT_UMI2 } from './modules/bcftools_norm'
include { BCFTOOLS_NORM as NORM_MUTECT_STRICT } from './modules/bcftools_norm'
include { BCFTOOLS_NORM as NORM_VARDICT_UMI2 } from './modules/bcftools_norm'
include { BCFTOOLS_NORM as NORM_VARDICT_STRICT } from './modules/bcftools_norm'
include { VARDICT as VARDICT_UMI2 } from './modules/vardict'
include { VARDICT as VARDICT_STRICT } from './modules/vardict'
include { MERGE2VCFS as MERGE_CALLERS_UMI2 } from './modules/merge2vcfs'
include { MERGE2VCFS as MERGE_CALLERS_STRICT } from './modules/merge2vcfs'
include { MERGE2VCFS as MERGE_UMIS } from './modules/merge2vcfs'
include { SORT_VCF as SORT_MERGED_UMI2 } from './modules/sort_vcf'
include { SORT_VCF as SORT_MERGED_STRICT } from './modules/sort_vcf'
include { SORT_VCF as SORT_MERGED_UMIS } from './modules/sort_vcf'
include { BGZIP_TABIX as BGZIP_CALLER_MERGE } from './modules/bgzip_tabix'
include { BGZIP_TABIX as BGZIP_FINAL_MERGE } from './modules/bgzip_tabix'
include { ANNOVAR_CONVERT as CONVERT_FINAL } from './modules/annovar_convert'
include { ANNOVAR_CONVERT as CONVERT_MARKED } from './modules/annovar_convert'
include { ANNOVAR_TABLE as TABLE_FINAL } from './modules/annovar_table'
include { ANNOVAR_TABLE as TABLE_MARKED } from './modules/annovar_table'
include { ADD_DPAF as ADD_DPAF_FINAL } from './modules/add_dpaf'
include { ADD_DPAF as ADD_DPAF_MARKED } from './modules/add_dpaf'
include { STATS_SUMMARY } from './modules/stats_summary'
include { CNVKIT_BATCH } from './modules/cnvkit_batch'
include { CNVKIT_GENEMETRICS } from './modules/cnvkit_genemetrics'
include { CNVKIT_SCATTER } from './modules/cnvkit_scatter'
include { MAKE_VCF_LIST } from './modules/make_vcf_list'
include { MARK_ARTIFACTS } from './modules/mark_artifacts'
include { MULTIQC } from './modules/multiqc'
include { KEEP_IMPORTANT_OUTPUTS } from './modules/keep_important_outputs'

workflow {
  validate_params()

  ref_bundle_ch = Channel.value(reference_bundle())
  bed_ch = Channel.value(file(params.bed_file))
  annovar_dbs_ch = Channel.value(file(params.annovar_dbs_dir))
  pon_umi2_ch = Channel.value(indexed_vcf_bundle(params.pon_umi2, 'pon_umi2'))
  pon_umi4_ch = Channel.value(indexed_vcf_bundle(params.pon_umi4, 'pon_umi4'))
  germline_ch = Channel.value(indexed_vcf_bundle(params.germline_resource, 'germline_resource'))
  cnvkit_ref_ch = Channel.value(file(params.cnvkit_reference))
  multiqc_config_ch = Channel.value(file(multiqc_config_path()))
  multiqc_custom_script_ch = Channel.value(file("${baseDir}/bin/gencore_multiqc_custom.py"))

  read_pairs_ch = Channel
    .fromFilePairs("${params.fastq_dir}/*_R{1,2}*.fastq.gz", flat: true)
    .ifEmpty { error "No paired FASTQ files found under: ${params.fastq_dir}" }

  FASTP(read_pairs_ch)
  BWA_MEM(FASTP.out.reads, ref_bundle_ch)
  SAMTOOLS_VIEW(BWA_MEM.out.sam)

  SORT_PRE_UMI(
    SAMTOOLS_VIEW.out.bam.map { sample_id, bam ->
      tuple(sample_id, bam, "${sample_id}_002_st_sort.bam")
    }
  )
  INDEX_PRE_UMI(SORT_PRE_UMI.out.bam)
  SAMTOOLS_FLAGSTAT(INDEX_PRE_UMI.out.indexed_bam)

  MOSDEPTH_BEFORE(
    INDEX_PRE_UMI.out.indexed_bam.map { sample_id, bam, bai ->
      tuple(sample_id, bam, bai, '002_before_gencore')
    },
    bed_ch
  )

  GENCORE_UMI2(
    INDEX_PRE_UMI.out.indexed_bam.map { sample_id, bam, bai ->
      tuple(sample_id, bam, bai, 'umi2', "${sample_id}_003_umi_merged.bam", params.umi_thr, '')
    },
    ref_bundle_ch,
    bed_ch
  )
  GENCORE_STRICT(
    INDEX_PRE_UMI.out.indexed_bam.map { sample_id, bam, bai ->
      tuple(sample_id, bam, bai, 'strict', "${sample_id}_003_umi_merged_strict.bam", 2, '--score_threshold=9 --ratio_threshold=0.9 --duplex_only')
    },
    ref_bundle_ch,
    bed_ch
  )

  SORT_UMI2(
    GENCORE_UMI2.out.bam.map { sample_id, bam ->
      tuple(sample_id, bam, "${sample_id}_004_umi_merged_st_sort.bam")
    }
  )
  SORT_STRICT(
    GENCORE_STRICT.out.bam.map { sample_id, bam ->
      tuple(sample_id, bam, "${sample_id}_004_umi_merged_strict_st_sort.bam")
    }
  )
  INDEX_UMI2(SORT_UMI2.out.bam)
  INDEX_STRICT(SORT_STRICT.out.bam)

  ADD_RG_UMI2(
    INDEX_UMI2.out.indexed_bam.map { sample_id, bam, bai ->
      tuple(sample_id, bam, 'umi2', "${sample_id}_005_RG.bam")
    }
  )
  ADD_RG_STRICT(
    INDEX_STRICT.out.indexed_bam.map { sample_id, bam, bai ->
      tuple(sample_id, bam, 'strict', "${sample_id}_005_RG_strict.bam")
    }
  )
  INDEX_RG_UMI2(ADD_RG_UMI2.out.bam)
  INDEX_RG_STRICT(ADD_RG_STRICT.out.bam)

  MOSDEPTH_AFTER(
    INDEX_RG_UMI2.out.indexed_bam.map { sample_id, bam, bai ->
      tuple(sample_id, bam, bai, '005_after_gencore')
    },
    bed_ch
  )

  MUTECT_UMI2(
    INDEX_RG_UMI2.out.indexed_bam.map { sample_id, bam, bai ->
      tuple(sample_id, bam, bai, 'umi2', "${sample_id}_006_Mutect.vcf.gz", "${sample_id}_006_Mutect_bamout.bam")
    },
    ref_bundle_ch,
    bed_ch,
    pon_umi2_ch,
    germline_ch
  )
  MUTECT_STRICT(
    INDEX_RG_STRICT.out.indexed_bam.map { sample_id, bam, bai ->
      tuple(sample_id, bam, bai, 'strict', "${sample_id}_006_Mutect_strict.vcf.gz", "${sample_id}_006_Mutect_bamout_strict.bam")
    },
    ref_bundle_ch,
    bed_ch,
    pon_umi4_ch,
    germline_ch
  )

  FILTER_MUTECT_UMI2(
    MUTECT_UMI2.out.vcf.map { sample_id, vcf, tbi, stats, mode ->
      tuple(sample_id, vcf, tbi, stats, mode, "${sample_id}_006_filtered.vcf.gz")
    },
    ref_bundle_ch
  )
  FILTER_MUTECT_STRICT(
    MUTECT_STRICT.out.vcf.map { sample_id, vcf, tbi, stats, mode ->
      tuple(sample_id, vcf, tbi, stats, mode, "${sample_id}_006_filtered_strict.vcf.gz")
    },
    ref_bundle_ch
  )

  NORM_MUTECT_UMI2(
    FILTER_MUTECT_UMI2.out.vcf.map { sample_id, vcf, tbi, mode ->
      tuple(sample_id, vcf, mode, "${sample_id}_006_filtered_norm.vcf.gz")
    },
    ref_bundle_ch
  )
  NORM_MUTECT_STRICT(
    FILTER_MUTECT_STRICT.out.vcf.map { sample_id, vcf, tbi, mode ->
      tuple(sample_id, vcf, mode, "${sample_id}_006_filtered_strict_norm.vcf.gz")
    },
    ref_bundle_ch
  )

  VARDICT_UMI2(
    INDEX_RG_UMI2.out.indexed_bam.map { sample_id, bam, bai ->
      tuple(sample_id, bam, bai, 'umi2', "${sample_id}_VarDict0.01.vcf")
    },
    ref_bundle_ch,
    bed_ch
  )
  VARDICT_STRICT(
    INDEX_RG_STRICT.out.indexed_bam.map { sample_id, bam, bai ->
      tuple(sample_id, bam, bai, 'strict', "${sample_id}_VarDict0.01_strict.vcf")
    },
    ref_bundle_ch,
    bed_ch
  )

  NORM_VARDICT_UMI2(
    VARDICT_UMI2.out.vcf.map { sample_id, vcf, mode ->
      tuple(sample_id, vcf, mode, "${sample_id}_norm_VarDict0.01.vcf.gz")
    },
    ref_bundle_ch
  )
  NORM_VARDICT_STRICT(
    VARDICT_STRICT.out.vcf.map { sample_id, vcf, mode ->
      tuple(sample_id, vcf, mode, "${sample_id}_norm_VarDict0.01_strict.vcf.gz")
    },
    ref_bundle_ch
  )

  MERGE_CALLERS_UMI2(
    NORM_MUTECT_UMI2.out.vcf
      .join(NORM_VARDICT_UMI2.out.vcf)
      .map { sample_id, mutect_vcf, mutect_tbi, mutect_mode, vardict_vcf, vardict_tbi, vardict_mode ->
        tuple(sample_id, mutect_vcf, 'Mutect', vardict_vcf, 'VarDict', 'both_callers', "${sample_id}_Merged_vcfs.vcf")
      }
  )
  MERGE_CALLERS_STRICT(
    NORM_MUTECT_STRICT.out.vcf
      .join(NORM_VARDICT_STRICT.out.vcf)
      .map { sample_id, mutect_vcf, mutect_tbi, mutect_mode, vardict_vcf, vardict_tbi, vardict_mode ->
        tuple(sample_id, mutect_vcf, 'Mutect', vardict_vcf, 'VarDict', 'both_callers_strict', "${sample_id}_Merged_vcfs_strict.vcf")
      }
  )

  SORT_MERGED_UMI2(
    MERGE_CALLERS_UMI2.out.vcf.map { sample_id, vcf ->
      tuple(sample_id, vcf, "${sample_id}_Merged_sorted_vcfs.vcf")
    }
  )
  SORT_MERGED_STRICT(
    MERGE_CALLERS_STRICT.out.vcf.map { sample_id, vcf ->
      tuple(sample_id, vcf, "${sample_id}_Merged_sorted_vcfs_strict.vcf")
    }
  )

  MERGE_UMIS(
    SORT_MERGED_UMI2.out.vcf
      .join(SORT_MERGED_STRICT.out.vcf)
      .map { sample_id, umi2_vcf, strict_vcf ->
        tuple(sample_id, umi2_vcf, 'UMI2', strict_vcf, 'UMI_strict', 'both_umis', "${sample_id}_umi2_and_strict_merged.vcf")
      }
  )
  SORT_MERGED_UMIS(
    MERGE_UMIS.out.vcf.map { sample_id, vcf ->
      tuple(sample_id, vcf, "${sample_id}_umi2_and_strict_merged_sorted.vcf")
    }
  )

  BGZIP_CALLER_MERGE(SORT_MERGED_UMI2.out.vcf)
  BGZIP_FINAL_MERGE(SORT_MERGED_UMIS.out.vcf)

  CONVERT_FINAL(
    BGZIP_FINAL_MERGE.out.vcf.map { sample_id, vcf_gz, tbi ->
      tuple(sample_id, vcf_gz, 'final', "${sample_id}_umi2_and_strict_merged_sorted_Convert_2_Annovar.avinput")
    }
  )
  TABLE_FINAL(
    CONVERT_FINAL.out.avinput.map { sample_id, avinput, mode ->
      tuple(sample_id, avinput, mode, "${sample_id}_umi2_and_strict_merged_sorted_Annovar")
    },
    annovar_dbs_ch
  )
  ADD_DPAF_FINAL(TABLE_FINAL.out.csv)

  STATS_SUMMARY(
    ADD_DPAF_FINAL.out.csv
      .join(INDEX_RG_UMI2.out.indexed_bam)
      .join(MOSDEPTH_BEFORE.out.stats)
      .join(SAMTOOLS_FLAGSTAT.out.stats)
      .map { sample_id, csv, mode, bam, bai, mosdepth_files, flagstat_files ->
        tuple(sample_id, csv, bam, bai, mosdepth_files, flagstat_files)
      },
    bed_ch
  )

  CNVKIT_BATCH(INDEX_RG_UMI2.out.indexed_bam, cnvkit_ref_ch)
  CNVKIT_GENEMETRICS(CNVKIT_BATCH.out.cnvkit_files)
  CNVKIT_SCATTER(CNVKIT_GENEMETRICS.out.cnvkit_files)

  MAKE_VCF_LIST(
    BGZIP_FINAL_MERGE.out.vcf
      .map { sample_id, vcf_gz, tbi -> vcf_gz }
      .ifEmpty { error "No final merged VCFs were produced. Artifact marking requires all samples to complete BGZIP_FINAL_MERGE successfully." }
      .collect()
  )
  MARK_ARTIFACTS(MAKE_VCF_LIST.out.list)

  marked_for_annovar = MARK_ARTIFACTS.out.marked_vcfs
    .flatten()
    .map { vcf_gz ->
      def marked_suffix = '_umi2_and_strict_merged_sorted_artifacts_marked.vcf.gz'
      def vcf_name = vcf_gz.getName()
      if (!vcf_name.endsWith(marked_suffix)) {
        error "Unexpected marked artifact VCF name: ${vcf_name}"
      }
      def sample_id = vcf_name.substring(0, vcf_name.length() - marked_suffix.length())
      tuple(sample_id, vcf_gz, 'marked', "${sample_id}_umi2_and_strict_merged_sorted_artifacts_marked.avinput")
    }

  CONVERT_MARKED(marked_for_annovar)
  TABLE_MARKED(
    CONVERT_MARKED.out.avinput.map { sample_id, avinput, mode ->
      tuple(sample_id, avinput, mode, "${sample_id}_umi2_and_strict_merged_sorted_artifacts_marked_Annovar")
    },
    annovar_dbs_ch
  )
  ADD_DPAF_MARKED(TABLE_MARKED.out.csv)

  multiqc_completion_inputs = Channel
    .empty()
    .mix(ADD_DPAF_MARKED.out.csv.map { sample_id, csv, mode -> csv })
    .mix(CNVKIT_SCATTER.out.logs)
    .flatten()
    .collect()

  MULTIQC(
    FASTP.out.stats.flatten().collect(),
    SAMTOOLS_FLAGSTAT.out.stats.map { sample_id, files -> files }.flatten().collect(),
    MOSDEPTH_BEFORE.out.stats.map { sample_id, files -> files }.flatten().collect(),
    MOSDEPTH_AFTER.out.stats.map { sample_id, files -> files }.flatten().collect(),
    GENCORE_UMI2.out.stats.flatten().collect(),
    GENCORE_STRICT.out.stats.flatten().collect(),
    multiqc_completion_inputs,
    multiqc_config_ch,
    multiqc_custom_script_ch
  )

  cleanup_completion_inputs = Channel
    .empty()
    .mix(MULTIQC.out.report)
    .mix(ADD_DPAF_MARKED.out.csv.map { sample_id, csv, mode -> csv })
    .mix(STATS_SUMMARY.out.stats)
    .mix(CNVKIT_SCATTER.out.plots)
    .mix(CNVKIT_SCATTER.out.logs)
    .flatten()
    .map { file_obj -> file_obj.toString() }
    .collect()

  KEEP_IMPORTANT_OUTPUTS(
    ADD_DPAF_MARKED.out.csv.map { sample_id, csv, mode -> sample_id }.collect(),
    cleanup_completion_inputs,
    keepImportantEnabled()
  )
}

def validate_params() {
  def requiredPaths = [
    'fastq_dir',
    'bed_file',
    'ref_file',
    'annovar_dbs_dir',
    'pon_umi2',
    'pon_umi4',
    'germline_resource',
    'cnvkit_reference'
  ]

  requiredPaths.each { key ->
    def value = params[key]
    if (!value) {
      error "Missing required parameter: --${key}"
    }
    if (value.toString().contains('/path/to')) {
      error "Parameter --${key} still has a placeholder value: ${value}"
    }
    if (!file(value).exists()) {
      error "Parameter --${key} path does not exist: ${value}"
    }
  }

  reference_bundle_paths().each { path ->
    if (!file(path).exists()) {
      error "Required reference bundle file does not exist: ${path}"
    }
  }

  indexed_vcf_bundle_paths(params.pon_umi2, 'pon_umi2')
  indexed_vcf_bundle_paths(params.pon_umi4, 'pon_umi4')
  indexed_vcf_bundle_paths(params.germline_resource, 'germline_resource')

  if (!file(multiqc_config_path()).exists()) {
    error "MultiQC config path does not exist: ${multiqc_config_path()}"
  }
}

def keepImportantEnabled() {
  def commandLineValue = keepImportantFromCommandLine()
  if (commandLineValue != null) {
    return commandLineValue
  }

  def value = null
  ['keep-important', 'keep_important', 'keepImportant', 'keepimportant'].find { key ->
    try {
      if (params.containsKey(key)) {
        value = params[key]
        return true
      }
    }
    catch (ignored) {
      // Some Nextflow versions expose params as a scope rather than a plain map.
    }
    return false
  }

  return boolParam(value)
}

def keepImportantFromCommandLine() {
  def cmd = workflow.commandLine?.toString()
  if (!cmd) {
    return null
  }

  def matcher = cmd =~ /(?:^|\s)--keep-important(?:=(\S+)|\s+(\S+))?/
  if (!matcher.find()) {
    return null
  }

  def value = matcher.group(1) ?: matcher.group(2)
  if (value == null || value.startsWith('--')) {
    return true
  }
  return boolParam(value)
}

def boolParam(value) {
  if (value instanceof Boolean) {
    return value
  }
  def normalized = value?.toString()?.trim()?.replaceAll(/^['"]|['"]$/, '')?.toLowerCase()
  return normalized in ['true', '1', 'yes', 'y', 'on']
}

def multiqc_config_path() {
  return params.multiqc_config ?: "${baseDir}/multiqc_config.yaml"
}

def indexed_vcf_bundle(pathValue, label) {
  indexed_vcf_bundle_paths(pathValue, label).collect { file(it) }
}

def indexed_vcf_bundle_paths(pathValue, label) {
  def vcf = pathValue.toString()
  def tbi = "${vcf}.tbi"
  def idx = "${vcf}.idx"

  if (file(tbi).exists()) {
    return [vcf, tbi]
  }
  if (file(idx).exists()) {
    return [vcf, idx]
  }

  error "Required index for --${label} was not found. Expected either ${tbi} or ${idx}"
}

def reference_bundle() {
  reference_bundle_paths().collect { file(it) }
}

def reference_bundle_paths() {
  def ref = params.ref_file.toString()
  def dict = params.ref_dict ?: ref.replaceFirst(/\.(fa|fasta)$/, '.dict')

  return [
    ref,
    "${ref}.amb",
    "${ref}.ann",
    "${ref}.bwt",
    "${ref}.pac",
    "${ref}.sa",
    "${ref}.fai",
    dict
  ]
}
