process ANNOVAR_CONVERT {
  tag "$sample_id:$mode"
  label 'annovar'
  label 'medium'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(input_vcf_gz), val(mode), val(output_avinput)

  output:
  tuple val(sample_id), path("$output_avinput"), val(mode), emit: avinput
  path "stout_sterr/*", emit: logs

  script:
  """
  mkdir -p stout_sterr
  convert2annovar.pl \\
    -format vcf4 ${input_vcf_gz} \\
    -outfile ${output_avinput} \\
    --includeinfo \\
    --allsample \\
    --withfreq \\
    > stout_sterr/${sample_id}_${mode}_convert2annovar.out \\
    2> stout_sterr/${sample_id}_${mode}_convert2annovar.err

  if [ ! -s "${output_avinput}" ]; then
    sample_avinput="${output_avinput}.${sample_id}.avinput"
    if [ -s "\${sample_avinput}" ]; then
      mv "\${sample_avinput}" "${output_avinput}"
    else
      echo "ERROR: convert2annovar did not create ${output_avinput} or \${sample_avinput}" >&2
      exit 1
    fi
  fi
  """
}
