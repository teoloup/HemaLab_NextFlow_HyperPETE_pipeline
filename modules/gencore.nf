process GENCORE {
  tag "$sample_id:$mode"
  label 'gencore'
  label 'high_cpu'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(bam), path(bai), val(mode), val(output_bam), val(umi_support), val(extra_args)
  path ref_files
  path bed_file

  output:
  tuple val(sample_id), path("$output_bam"), emit: bam
  path "stats/*", emit: stats
  path "stout_sterr/*", emit: logs

  script:
  def ref_name = file(params.ref_file).getName()
  """
  mkdir -p stats stout_sterr
  gencore \\
    -i ${bam} \\
    -o ${output_bam} \\
    -r ${ref_name} \\
    -s ${umi_support} -u UMI \\
    -b ${bed_file} \\
    --html stats/${sample_id}_gencore_${mode}.html \\
    --json stats/${sample_id}_gencore_${mode}.json \\
    --umi_diff_threshold 1 \\
    ${extra_args} \\
    > stout_sterr/${sample_id}_${mode}_gencore.out \\
    2> stout_sterr/${sample_id}_${mode}_gencore.err
  """
}
