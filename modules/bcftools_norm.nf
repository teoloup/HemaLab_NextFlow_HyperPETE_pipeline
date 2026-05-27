process BCFTOOLS_NORM {
  tag "$sample_id:$mode"
  label 'bcftools'
  label 'medium'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(input_vcf), val(mode), val(output_vcf)
  path ref_files

  output:
  tuple val(sample_id), path("$output_vcf"), path("${output_vcf}.tbi"), val(mode), emit: vcf
  path "stout_sterr/*", emit: logs

  script:
  def ref_name = file(params.ref_file).getName()
  """
  mkdir -p stout_sterr
  bcftools norm \\
    -f ${ref_name} \\
    -m - \\
    -O z \\
    -o ${output_vcf} \\
    ${input_vcf} \\
    > stout_sterr/${sample_id}_${mode}_bcftools_norm.out \\
    2> stout_sterr/${sample_id}_${mode}_bcftools_norm.err

  bcftools index -f -t ${output_vcf} \\
    > stout_sterr/${sample_id}_${mode}_bcftools_norm_tabix.out \\
    2> stout_sterr/${sample_id}_${mode}_bcftools_norm_tabix.err
  """
}
