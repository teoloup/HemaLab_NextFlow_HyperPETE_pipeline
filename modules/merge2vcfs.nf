process MERGE2VCFS {
  tag "$sample_id:$merge_type"
  label 'python_custom'
  label 'small'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(vcf_a), val(name_a), path(vcf_b), val(name_b), val(merge_type), val(output_vcf)

  output:
  tuple val(sample_id), path("$output_vcf"), emit: vcf
  path "stout_sterr/*", emit: logs

  script:
  """
  mkdir -p stout_sterr
  python /opt/hematology-python/bin/Merge2Vcfs.py \\
    -v ${vcf_a} \\
    -n ${name_a} \\
    -V ${vcf_b} \\
    -N ${name_b} \\
    -t ${merge_type} \\
    -o ${output_vcf} \\
    > stout_sterr/${sample_id}_${merge_type}_merge2vcfs.out \\
    2> stout_sterr/${sample_id}_${merge_type}_merge2vcfs.err
  """
}
