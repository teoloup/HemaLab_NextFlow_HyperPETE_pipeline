process GATK_MUTECT2 {
  tag "$sample_id:$mode"
  label 'gatk'
  label 'high_cpu'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(bam), path(bai), val(mode), val(output_vcf), val(output_bamout)
  path ref_files
  path bed_file
  path panel_of_normals_files
  path germline_resource_files

  output:
  tuple val(sample_id), path("$output_vcf"), path("${output_vcf}.tbi"), path("${output_vcf}.stats"), val(mode), emit: vcf
  path "$output_bamout", emit: bamout
  path "stout_sterr/*", emit: logs

  script:
  def ref_name = file(params.ref_file).getName()
  def pon_name = mode == 'strict' ? file(params.pon_umi4).getName() : file(params.pon_umi2).getName()
  def germline_name = file(params.germline_resource).getName()
  """
  mkdir -p stout_sterr
  gatk Mutect2 \\
    -tumor ${sample_id} \\
    -R ${ref_name} \\
    -I ${bam} \\
    -O ${output_vcf} \\
    -L ${bed_file} \\
    -bamout ${output_bamout} \\
    --af-of-alleles-not-in-resource 0.00003125 \\
    --native-pair-hmm-threads ${task.cpus} \\
    --dont-use-soft-clipped-bases true \\
    --max-reads-per-alignment-start 0 \\
    --panel-of-normals ${pon_name} \\
    --germline-resource ${germline_name} \\
    > stout_sterr/${sample_id}_${mode}_mutect2.out \\
    2> stout_sterr/${sample_id}_${mode}_mutect2.err
  """
}
