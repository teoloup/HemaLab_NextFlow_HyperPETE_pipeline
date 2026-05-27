process CNVKIT_SCATTER {
  tag "$sample_id"
  label 'cnvkit'
  label 'medium'

  publishDir { "${params.outdir}/${sample_id}/cnvkit" }, mode: params.publish_mode, pattern: "cnvkit/*", saveAs: { filename -> filename.tokenize('/').last() }
  publishDir { "${params.outdir}/${sample_id}" }, mode: params.publish_mode, pattern: "stout_sterr/*"

  input:
  tuple val(sample_id), path(cnvkit_files)

  output:
  path "cnvkit/*", optional: true, emit: plots
  path "stout_sterr/*", emit: logs

  script:
  """
  export MPLCONFIGDIR="\$PWD/.matplotlib"
  mkdir -p cnvkit stout_sterr "\$MPLCONFIGDIR"
  cp ${cnvkit_files} cnvkit/

  make_placeholder_plot() {
    output_png="\$1"
    title="\$2"
    message="\$3"
    python3 - "\${output_png}" "\${title}" "\${message}" <<'PY'
import sys
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

output_png, title, message = sys.argv[1:4]
fig, ax = plt.subplots(figsize=(8, 4.5))
ax.axis('off')
ax.text(0.5, 0.62, title, ha='center', va='center', fontsize=16, fontweight='bold')
ax.text(0.5, 0.42, message, ha='center', va='center', fontsize=11, wrap=True)
fig.tight_layout()
fig.savefig(output_png, dpi=150)
plt.close(fig)
PY
  }

  awk 'NR > 1 { print \$1 }' cnvkit/${sample_id}_005_RG.cnr | sort -u > cnvkit/${sample_id}_cnvkit_chromosomes.txt
  : > stout_sterr/${sample_id}_cnvkit_scatter_summary.out

  for chr_num in \$(seq 1 22); do
    chr="chr\${chr_num}"
    if ! grep -Fxq "\${chr}" cnvkit/${sample_id}_cnvkit_chromosomes.txt; then
      if grep -Fxq "\${chr_num}" cnvkit/${sample_id}_cnvkit_chromosomes.txt; then
        chr="\${chr_num}"
      else
        echo "Skipping chr\${chr_num}: no bins found in ${sample_id}_005_RG.cnr" \
          > stout_sterr/${sample_id}_cnvkit_scatter_chr\${chr_num}.out
        touch stout_sterr/${sample_id}_cnvkit_scatter_chr\${chr_num}.err
        make_placeholder_plot \
          cnvkit/${sample_id}_chr\${chr_num}.png \
          "${sample_id} chr\${chr_num}" \
          "No CNVkit bins were found for this chromosome in ${sample_id}_005_RG.cnr."
        echo "SKIPPED chr\${chr_num} no_bins" >> stout_sterr/${sample_id}_cnvkit_scatter_summary.out
        continue
      fi
    fi

    cnvkit scatter \\
      cnvkit/${sample_id}_005_RG.cnr \\
      -s cnvkit/${sample_id}_005_RG.cns \\
      -c \${chr} \\
      --by-bin \\
      -o cnvkit/${sample_id}_chr\${chr_num}.png \\
      > stout_sterr/${sample_id}_cnvkit_scatter_chr\${chr_num}.out \\
      2> stout_sterr/${sample_id}_cnvkit_scatter_chr\${chr_num}.err || {
        status=\$?
        echo "WARNING: cnvkit scatter failed for \${chr}; keeping pipeline running because per-chromosome plots are non-critical. Exit status: \${status}" \
          >> stout_sterr/${sample_id}_cnvkit_scatter_chr\${chr_num}.err
        echo "FAILED \${chr} status=\${status}" >> stout_sterr/${sample_id}_cnvkit_scatter_summary.out
        rm -f cnvkit/${sample_id}_chr\${chr_num}.png
        make_placeholder_plot \
          cnvkit/${sample_id}_chr\${chr_num}.png \
          "${sample_id} \${chr}" \
          "CNVkit scatter failed for this chromosome. See stout_sterr/${sample_id}_cnvkit_scatter_chr\${chr_num}.err."
        continue
      }
    echo "OK \${chr}" >> stout_sterr/${sample_id}_cnvkit_scatter_summary.out
  done

  cnvkit scatter \\
    cnvkit/${sample_id}_005_RG.cnr \\
    -s cnvkit/${sample_id}_005_RG.cns \\
    -o cnvkit/${sample_id}_all_chromosomes_scatter.pdf \\
    > stout_sterr/${sample_id}_cnvkit_scatter_all.out \\
    2> stout_sterr/${sample_id}_cnvkit_scatter_all.err || {
      status=\$?
      echo "WARNING: whole-genome cnvkit scatter failed. Exit status: \${status}" \
        >> stout_sterr/${sample_id}_cnvkit_scatter_all.err
      rm -f cnvkit/${sample_id}_all_chromosomes_scatter.pdf
    }
  """
}
