process ADD_DPAF {
  tag "$sample_id:$mode"
  label 'python_custom'
  label 'small'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode, pattern: "dpaf/*", saveAs: { filename -> filename.tokenize('/').last() }
  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode, pattern: "stout_sterr/*"

  input:
  tuple val(sample_id), path(csv), val(mode)

  output:
  tuple val(sample_id), path("dpaf/*multianno*.csv"), val(mode), emit: csv
  path "stout_sterr/*", emit: logs

  script:
  def output_csv = csv.getName()
  """
  mkdir -p dpaf stout_sterr
  cp -L ${csv} dpaf/${output_csv}
  python /opt/hematology-python/bin/add_dpaf.py dpaf/${output_csv} \\
    > stout_sterr/${sample_id}_${mode}_add_dpaf.out \\
    2> stout_sterr/${sample_id}_${mode}_add_dpaf.err
  """
}
