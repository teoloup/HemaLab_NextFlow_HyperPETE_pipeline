process SORT_VCF {
  tag "$sample_id:$output_vcf"
  label 'small'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(input_vcf), val(output_vcf)

  output:
  tuple val(sample_id), path("$output_vcf"), emit: vcf
  path "stout_sterr/*", emit: logs

  script:
  def log_name = output_vcf.replaceAll(/\.vcf$/, '')
  """
  mkdir -p stout_sterr
  awk '\$1 ~ /^#/ {print \$0; next} {print \$0 | "sort -k1,1 -k2,2n"}' \\
    ${input_vcf} \\
    > ${output_vcf} \\
    2> stout_sterr/${sample_id}_${log_name}_sort_vcf.err
  touch stout_sterr/${sample_id}_${log_name}_sort_vcf.out
  """
}
