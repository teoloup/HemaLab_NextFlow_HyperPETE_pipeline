process CNVKIT_GENEMETRICS {
  tag "$sample_id"
  label 'cnvkit'
  label 'medium'

  publishDir { "${params.outdir}/${sample_id}/cnvkit" }, mode: params.publish_mode, pattern: "cnvkit/*", saveAs: { filename -> filename.tokenize('/').last() }
  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode, pattern: "stout_sterr/*"

  input:
  tuple val(sample_id), path(cnvkit_files)

  output:
  tuple val(sample_id), path("cnvkit/*"), emit: cnvkit_files
  path "stout_sterr/*", emit: logs

  script:
  """
  mkdir -p cnvkit stout_sterr
  cp ${cnvkit_files} cnvkit/
  cnvkit genemetrics \\
    cnvkit/${sample_id}*RG.cnr \\
    -s cnvkit/${sample_id}*RG.cns \\
    -t 0.5 \\
    -o cnvkit/${sample_id}_genemetrics_cnvkit.txt \\
    > stout_sterr/${sample_id}_cnvkit_genemetrics.out \\
    2> stout_sterr/${sample_id}_cnvkit_genemetrics.err
  """
}
