process FASTP {
  tag "$sample_id"
  label 'fastp'
  label 'high_cpu'

  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode

  input:
  tuple val(sample_id), path(r1), path(r2)

  output:
  tuple val(sample_id), path("${sample_id}_R1_trimmed.fastq.gz"), path("${sample_id}_R2_trimmed.fastq.gz"), emit: reads
  path "stats/*", emit: stats
  path "stout_sterr/*", emit: logs

  script:
  """
  mkdir -p stats stout_sterr
  fastp \\
    -i ${r1} -I ${r2} \\
    -o ${sample_id}_R1_trimmed.fastq.gz -O ${sample_id}_R2_trimmed.fastq.gz \\
    -Q --umi --umi_loc per_read --umi_len 3 --umi_prefix UMI \\
    --detect_adapter_for_pe \\
    --umi_skip 3 \\
    --thread ${task.cpus} \\
    -g -W 5 -q 20 -u 40 -x -3 -l 70 -c \\
    -j stats/${sample_id}_fastp.json \\
    -h stats/${sample_id}_fastp.html \\
    > stout_sterr/${sample_id}_fastp.out \\
    2> stout_sterr/${sample_id}_fastp.err
  """
}
