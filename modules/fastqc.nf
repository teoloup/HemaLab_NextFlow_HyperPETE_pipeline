process FASTQC {
  tag "$sample_id:$mode"
  label 'fastqc'
  label 'medium'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(r1), path(r2), val(mode)

  output:
  tuple val(sample_id), path("stats/fastqc_${mode}/*_fastqc.{html,zip}"), val(mode), emit: reports
  path "stout_sterr/*", emit: logs

  script:
  """
  mkdir -p stats/fastqc_${mode} stout_sterr
  fastqc \\
    --threads ${task.cpus} \\
    --outdir stats/fastqc_${mode} \\
    ${r1} ${r2} \\
    > stout_sterr/${sample_id}_${mode}_fastqc.out \\
    2> stout_sterr/${sample_id}_${mode}_fastqc.err
  """
}
