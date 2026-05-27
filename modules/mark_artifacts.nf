process MARK_ARTIFACTS {
  tag "cohort"
  label 'python_custom'
  label 'high_mem'

  publishDir { "${params.outdir}/cohort" }, mode: params.publish_mode

  input:
  tuple path(vcf_list), path(vcfs)

  output:
  path "marked_artifacts/*_artifacts_marked.vcf.gz", emit: marked_vcfs
  path "stout_sterr/*", emit: logs

  script:
  """
  export MPLCONFIGDIR="\$PWD/.matplotlib"
  mkdir -p "\$MPLCONFIGDIR"
  mkdir -p marked_artifacts stout_sterr

  while IFS= read -r vcf_file; do
    if [ ! -s "\${vcf_file}" ]; then
      echo "ERROR: VCF listed in ${vcf_list} is not staged or is empty: \${vcf_file}" >&2
      exit 1
    fi
  done < ${vcf_list}

  python /opt/hematology-python/bin/Mark_artifacts_1.3.1.py \\
    -l ${vcf_list} \\
    -t 0.5 \\
    -r marked_artifacts/ \\
    > stout_sterr/mark_artifacts.out \\
    2> stout_sterr/mark_artifacts.err

  marked_vcfs=(*_artifacts_marked.vcf.gz)
  if [ ! -e "\${marked_vcfs[0]}" ]; then
    echo "ERROR: Mark_artifacts completed but did not create any *_artifacts_marked.vcf.gz files" >&2
    exit 1
  fi
  mv *_artifacts_marked.vcf.gz marked_artifacts/
  """
}
