process KEEP_IMPORTANT_OUTPUTS {
  tag "cohort"
  label 'small'

  publishDir { "${params.outdir}/cohort" }, mode: params.publish_mode

  input:
  val sample_ids
  val completion_inputs
  val keep_important_enabled

  output:
  path "keep_important_cleanup.log", emit: log

  script:
  def sample_lines = sample_ids.join('\n')
  """
  echo "keep-important received value: ${keep_important_enabled}" > keep_important_cleanup.log
  if [ "${keep_important_enabled}" != "true" ]; then
    echo "keep-important disabled; no cleanup performed" >> keep_important_cleanup.log
    exit 0
  fi

  # publishDir copies are asynchronous in Nextflow. Give final sample-level
  # publishes a short grace period before pruning the published output dirs.
  sleep 30

  outdir="\$(realpath -m '${params.outdir}')"
  if [ -z "\${outdir}" ] || [ "\${outdir}" = "/" ]; then
    echo "Refusing to clean unsafe outdir: \${outdir}" >&2
    exit 1
  fi

  cat > sample_ids.txt <<'EOF'
${sample_lines}
EOF

  while IFS= read -r sample_id; do
    [ -n "\${sample_id}" ] || continue
    sample_dir="\$(realpath -m "\${outdir}/\${sample_id}")"

    case "\${sample_dir}" in
      "\${outdir}"/*) ;;
      *)
        echo "Refusing to clean path outside outdir: \${sample_dir}" >&2
        exit 1
        ;;
    esac

    if [ ! -d "\${sample_dir}" ]; then
      echo "SKIP missing sample dir: \${sample_dir}" >> keep_important_cleanup.log
      continue
    fi

    echo "Cleaning sample dir: \${sample_dir}" >> keep_important_cleanup.log
    find "\${sample_dir}" -mindepth 1 -maxdepth 1 \\
      ! -name 'stats' \\
      ! -name 'cnvkit' \\
      ! -name 'stout_sterr' \\
      ! -name '*_umi2_and_strict_merged_sorted_artifacts_marked_Annovar.hg38_multianno.csv' \\
      ! -name '*_umi2_and_strict_merged_sorted.vcf.gz' \\
      ! -name '*_006_filtered_norm.vcf.gz' \\
      ! -name '*_006_filtered_norm.vcf.gz.tbi' \\
      ! -name '*_006_filtered_strict_norm.vcf.gz' \\
      ! -name '*_006_filtered_strict_norm.vcf.gz.tbi' \\
      ! -name '*_006_Mutect_bamout.bam' \\
      ! -name '*_norm_VarDict0.01.vcf.gz' \\
      ! -name '*_norm_VarDict0.01.vcf.gz.tbi' \\
      ! -name '*_006_Mutect_bamout_strict.bam' \\
      ! -name '*_005_RG.bam.bai' \\
      ! -name '*_005_RG.bam' \\
      ! -name '*_norm_VarDict0.01_strict.vcf.gz' \\
      ! -name '*_norm_VarDict0.01_strict.vcf.gz.tbi' \\
      ! -name '*_005_RG_strict.bam.bai' \\
      ! -name '*_005_RG_strict.bam' \\
      -print0 | while IFS= read -r -d '' path_to_remove; do
        echo "REMOVE \${path_to_remove}" >> keep_important_cleanup.log
        rm -rf -- "\${path_to_remove}"
      done
  done < sample_ids.txt
  """
}
