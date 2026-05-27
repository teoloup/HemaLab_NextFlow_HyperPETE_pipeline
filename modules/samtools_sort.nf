process SAMTOOLS_SORT {
  tag "$sample_id:$output_bam"
  label 'samtools'
  label 'high_cpu'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(input_bam), val(output_bam)

  output:
  tuple val(sample_id), path("$output_bam"), emit: bam
  path "stout_sterr/*", emit: logs

  script:
  def log_name = output_bam.replaceAll(/\.bam$/, '')
  """
  mkdir -p stout_sterr
  samtools sort \\
    ${input_bam} \\
    --threads ${task.cpus} \\
    -o ${output_bam} \\
    > stout_sterr/${sample_id}_${log_name}_samtools_sort.out \\
    2> stout_sterr/${sample_id}_${log_name}_samtools_sort.err
  """
}
