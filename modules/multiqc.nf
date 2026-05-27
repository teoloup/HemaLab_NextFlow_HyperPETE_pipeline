process MULTIQC {
  tag "cohort"
  label 'multiqc'
  label 'medium'

  publishDir { "${params.outdir}/multiqc" }, mode: params.publish_mode

  input:
  path fastqc_raw_reports, stageAs: "multiqc_inputs/fastqc_raw/*"
  path fastqc_trimmed_reports, stageAs: "multiqc_inputs/fastqc_trimmed/*"
  path fastp_stats, stageAs: "multiqc_inputs/fastp/*"
  path flagstat_stats, stageAs: "multiqc_inputs/flagstat/*"
  path mosdepth_before_stats, stageAs: "multiqc_inputs/mosdepth_before/*"
  path mosdepth_after_stats, stageAs: "multiqc_inputs/mosdepth_after/*"
  path gencore_umi2_stats, stageAs: "multiqc_inputs/gencore_umi2/*"
  path gencore_strict_stats, stageAs: "multiqc_inputs/gencore_strict/*"
  path completion_inputs, stageAs: "pipeline_done/*"
  path multiqc_config
  path custom_content_script

  output:
  path "multiqc/*", emit: report
  path "stout_sterr/*", emit: logs

  script:
  """
  mkdir -p multiqc stout_sterr
  python ${custom_content_script}

  multiqc multiqc_inputs \\
    --config ${multiqc_config} \\
    --outdir multiqc \\
    --filename hematology_multiqc_report.html \\
    > stout_sterr/multiqc.out \\
    2> stout_sterr/multiqc.err
  """
}
