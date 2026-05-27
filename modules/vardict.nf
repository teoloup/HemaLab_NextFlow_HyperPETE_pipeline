process VARDICT {
  tag "$sample_id:$mode"
  label 'vardict'
  label 'high_cpu'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(bam), path(bai), val(mode), val(output_vcf)
  path ref_files
  path bed_file

  output:
  tuple val(sample_id), path("$output_vcf"), val(mode), emit: vcf
  path "stout_sterr/*", emit: logs

  script:
  def ref_name = file(params.ref_file).getName()
  """
  set -o pipefail

  mkdir -p stout_sterr
  {
    VarDict \\
      -G ${ref_name} \\
      -f "0.01" \\
      --fisher \\
      -I 150 \\
      -N ${sample_id} \\
      -b ${bam} \\
      -c 1 -S 2 -E 3 -g 4 ${bed_file} \\
      -th ${task.cpus} \\
      | var2vcf_valid.pl -N ${sample_id} -E -f "0.01"
  } \\
    > ${output_vcf} \\
    2> stout_sterr/${sample_id}_${mode}_vardict.err || {
      status=\$?
      cat stout_sterr/${sample_id}_${mode}_vardict.err >&2
      exit \${status}
    }

  if [ ! -s ${output_vcf} ]; then
    echo "VarDict did not produce a non-empty VCF: ${output_vcf}" >&2
    exit 1
  fi

  touch stout_sterr/${sample_id}_${mode}_vardict.out

  perl -pi -e 's/##INFO=<ID=HICNT,Number=1,Type=Integer/##INFO=<ID=HICNT,Number=1,Type=String/' ${output_vcf} \\
    > stout_sterr/${sample_id}_${mode}_vardict_fix_hicnt.out \\
    2> stout_sterr/${sample_id}_${mode}_vardict_fix_hicnt.err
  perl -pi -e 's/##INFO=<ID=HICOV,Number=1,Type=Integer/##INFO=<ID=HICOV,Number=1,Type=String/' ${output_vcf} \\
    > stout_sterr/${sample_id}_${mode}_vardict_fix_hicov.out \\
    2> stout_sterr/${sample_id}_${mode}_vardict_fix_hicov.err
  """
}
