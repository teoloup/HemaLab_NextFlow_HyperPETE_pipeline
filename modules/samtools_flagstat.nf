process SAMTOOLS_FLAGSTAT {
  tag "$sample_id"
  label 'samtools'
  label 'medium'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(bam), path(bai)

  output:
  tuple val(sample_id), path("stats/*"), emit: stats
  path "stout_sterr/*", emit: logs

  script:
  """
  mkdir -p stats stout_sterr
  samtools flagstat \\
    --threads ${task.cpus} \\
    ${bam} \\
    | tee stats/${sample_id}_002_view.txt \\
    > stout_sterr/${sample_id}_samtools_flagstat.out \\
    2> stout_sterr/${sample_id}_samtools_flagstat.err
  """
}
