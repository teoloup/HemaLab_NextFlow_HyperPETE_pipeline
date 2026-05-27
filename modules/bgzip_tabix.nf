process BGZIP_TABIX {
  tag "$sample_id:$input_vcf"
  label 'htslib'
  label 'small'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(input_vcf)

  output:
  tuple val(sample_id), path("*.vcf.gz"), path("*.vcf.gz.tbi"), emit: vcf
  path "stout_sterr/*", emit: logs

  script:
  def log_name = input_vcf.getName().replaceAll(/\.vcf$/, '')
  """
  mkdir -p stout_sterr
  bgzip -f ${input_vcf} \\
    > stout_sterr/${sample_id}_${log_name}_bgzip.out \\
    2> stout_sterr/${sample_id}_${log_name}_bgzip.err
  tabix -f ${input_vcf}.gz \\
    > stout_sterr/${sample_id}_${log_name}_tabix.out \\
    2> stout_sterr/${sample_id}_${log_name}_tabix.err
  """
}
