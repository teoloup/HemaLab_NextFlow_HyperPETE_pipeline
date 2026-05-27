process MAKE_VCF_LIST {
  tag "cohort"
  label 'small'

  publishDir { "${params.outdir}/cohort" }, mode: params.publish_mode

  input:
  path vcfs

  output:
  tuple path("merged_vcfs_list"), path(vcfs), emit: list
  path "stout_sterr/*", emit: logs

  script:
  """
  mkdir -p stout_sterr
  if [ ${vcfs.size()} -eq 0 ]; then
    echo "ERROR: No final merged VCFs were provided to MAKE_VCF_LIST. Upstream sample processing likely failed before artifact marking." >&2
    exit 1
  fi

  printf "%s\\n" ${vcfs} \\
    > merged_vcfs_list \\
    2> stout_sterr/make_vcf_list.err
  wc -l < merged_vcfs_list > stout_sterr/make_vcf_list.out
  """
}
