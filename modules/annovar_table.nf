process ANNOVAR_TABLE {
  tag "$sample_id:$mode"
  label 'annovar'
  label 'high_mem'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(avinput), val(mode), val(output_prefix)
  path annovar_dbs_dir

  output:
  tuple val(sample_id), path("${output_prefix}.hg38_multianno.csv"), val(mode), emit: csv
  path "stout_sterr/*", emit: logs

  script:
  """
  mkdir -p stout_sterr
  table_annovar.pl \\
    ${avinput} \\
    ${annovar_dbs_dir} \\
    -buildver hg38 \\
    -out ${output_prefix} \\
    -remove \\
    -protocol refGene,gnomad211_exome,clinvar_latest,oncokb_43,avsnp150,cosmic_coding,intervar_latest,dbnsfp42c,dbscsnv11 \\
    -operation g,f,f,f,f,f,f,f,f \\
    -arg '--splicing_threshold 6 --hgvs',,,,,'-colsWanted all',,, \\
    -nastring . \\
    -csvout \\
    -polish \\
    --otherinfo \\
    > stout_sterr/${sample_id}_${mode}_table_annovar.out \\
    2> stout_sterr/${sample_id}_${mode}_table_annovar.err
  """
}
