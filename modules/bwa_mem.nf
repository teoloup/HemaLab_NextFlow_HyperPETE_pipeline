process BWA_MEM {
  tag "$sample_id"
  label 'bwa'
  label 'high_cpu'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(r1), path(r2)
  path ref_files

  output:
  tuple val(sample_id), path("${sample_id}.sam"), emit: sam
  path "stout_sterr/*", emit: logs

  script:
  def ref_name = file(params.ref_file).getName()
  """
  mkdir -p stout_sterr
  bwa mem \\
    -M \\
    -t ${task.cpus} \\
    ${ref_name} \\
    ${r1} \\
    ${r2} \\
    > ${sample_id}.sam \\
    2> stout_sterr/${sample_id}_bwa_mem.err
  touch stout_sterr/${sample_id}_bwa_mem.out
  """
}
