process MOSDEPTH {
  tag "$sample_id:$prefix"
  label 'mosdepth'
  label 'medium'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(bam), path(bai), val(prefix)
  path bed_file

  output:
  tuple val(sample_id), path("stats/*"), emit: stats
  path "stout_sterr/*", emit: logs

  script:
  """
  mkdir -p stats stout_sterr
  mosdepth \\
    -t ${task.cpus} \\
    --by ${bed_file} \\
    --thresholds 100,200,500,1000,2000,10000 \\
    stats/${sample_id}_${prefix} \\
    ${bam} \\
    > stout_sterr/${sample_id}_${prefix}_mosdepth.out \\
    2> stout_sterr/${sample_id}_${prefix}_mosdepth.err
  """
}
