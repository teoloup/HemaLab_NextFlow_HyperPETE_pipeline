process SAMTOOLS_VIEW {
  tag "$sample_id"
  label 'samtools'
  label 'high_cpu'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(sam)

  output:
  tuple val(sample_id), path("${sample_id}_001_view.bam"), emit: bam
  path "stout_sterr/*", emit: logs

  script:
  """
  mkdir -p stout_sterr
  samtools view -bh -@ ${task.cpus} \\
    -o ${sample_id}_001_view.bam \\
    ${sam} \\
    > stout_sterr/${sample_id}_samtools_view.out \\
    2> stout_sterr/${sample_id}_samtools_view.err
  """
}
