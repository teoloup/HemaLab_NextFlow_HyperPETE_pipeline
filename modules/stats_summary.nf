process STATS_SUMMARY {
  tag "$sample_id"
  label 'python_custom'
  label 'medium'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(csv), path(bam), path(bai), path(mosdepth_files), path(flagstat_files)
  path bed_file

  output:
  path "stats/*", emit: stats
  path "stout_sterr/*", emit: logs

  script:
  """
  mkdir -p ${sample_id}/stats stats stout_sterr
  cp ${csv} ${sample_id}/
  cp ${bam} ${bai} ${sample_id}/
  cp ${mosdepth_files} ${sample_id}/stats/ || true
  cp ${flagstat_files} ${sample_id}/stats/ || true

  python /opt/hematology-python/bin/stats.2.1.py \\
    -D ${sample_id}/stats \\
    -M ${sample_id}/stats/*before_gencore*thresholds.bed.gz \\
    -L ${bed_file} \\
    -U ${sample_id}/stats/*before_gencore.per-base.bed.gz \\
    > stout_sterr/${sample_id}_stats_summary.out \\
    2> stout_sterr/${sample_id}_stats_summary.err || {
      status=\$?
      cat stout_sterr/${sample_id}_stats_summary.err >&2
      exit \${status}
    }

  rm -f ${sample_id}/stats/per_base_ontarget.bed
  cp ${sample_id}/stats/* stats/
  """
}
