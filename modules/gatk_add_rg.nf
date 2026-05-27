process GATK_ADD_RG {
  tag "$sample_id:$mode"
  label 'gatk'
  label 'medium'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(input_bam), val(mode), val(output_bam)

  output:
  tuple val(sample_id), path("$output_bam"), emit: bam
  path "stout_sterr/*", emit: logs

  script:
  """
  mkdir -p stout_sterr
  gatk AddOrReplaceReadGroups \\
    -I ${input_bam} \\
    -O ${output_bam} \\
    -LB 01 \\
    -SM ${sample_id} \\
    -PL Illumina_MiSeq \\
    -PU AAAAAA \\
    > stout_sterr/${sample_id}_${mode}_gatk_add_rg.out \\
    2> stout_sterr/${sample_id}_${mode}_gatk_add_rg.err
  """
}
