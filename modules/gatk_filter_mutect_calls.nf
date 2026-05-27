process GATK_FILTER_MUTECT_CALLS {
  tag "$sample_id:$mode"
  label 'gatk'
  label 'medium'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(input_vcf), path(input_vcf_tbi), path(input_vcf_stats), val(mode), val(output_vcf)
  path ref_files

  output:
  tuple val(sample_id), path("$output_vcf"), path("${output_vcf}.tbi"), val(mode), emit: vcf
  path "stout_sterr/*", emit: logs

  script:
  def ref_name = file(params.ref_file).getName()
  """
  mkdir -p stout_sterr
  gatk FilterMutectCalls \\
    -R ${ref_name} \\
    -V ${input_vcf} \\
    -O ${output_vcf} \\
    > stout_sterr/${sample_id}_${mode}_filter_mutect_calls.out \\
    2> stout_sterr/${sample_id}_${mode}_filter_mutect_calls.err
  """
}
