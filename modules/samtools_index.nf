process SAMTOOLS_INDEX {
  tag "$sample_id:$bam"
  label 'samtools'
  label 'medium'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(bam)

  output:
  tuple val(sample_id), path("*.bam", includeInputs: true), path("*.bam.bai"), emit: indexed_bam
  path "stout_sterr/*", emit: logs

  script:
  def log_name = bam.getName().replaceAll(/\.bam$/, '')
  """
  mkdir -p stout_sterr
  samtools index -b ${bam} \\
    > stout_sterr/${sample_id}_${log_name}_samtools_index.out \\
    2> stout_sterr/${sample_id}_${log_name}_samtools_index.err
  """
}
