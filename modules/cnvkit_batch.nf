process CNVKIT_BATCH {
  tag "$sample_id"
  label 'cnvkit'
  label 'high_cpu'

  publishDir { "${params.outdir}/${sample_id}/cnvkit" }, mode: params.publish_mode, pattern: "cnvkit/*", saveAs: { filename -> filename.tokenize('/').last() }
  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode, pattern: "stout_sterr/*"

  input:
  tuple val(sample_id), path(bam), path(bai)
  path cnvkit_reference

  output:
  tuple val(sample_id), path("cnvkit/*"), emit: cnvkit_files
  path "stout_sterr/*", emit: logs

  script:
  """
  mkdir -p cnvkit stout_sterr
  cnvkit batch \\
    ${bam} \\
    -r ${cnvkit_reference} \\
    --output-dir cnvkit \\
    --diagram --scatter -p ${task.cpus} \\
    > stout_sterr/${sample_id}_cnvkit_batch.out \\
    2> stout_sterr/${sample_id}_cnvkit_batch.err
  """
}
