#!/usr/bin/env bash
#SBATCH --job-name=pon_m2
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=3000
#SBATCH --time=12:00:00
#SBATCH --output=/mnt/beegfs/tloupis/slurmstout/%x_%A_%a.out
#SBATCH --error=/mnt/beegfs/tloupis/slurmstout/%x_%A_%a.err

set -euo pipefail
shopt -s nullglob

mode="$1"
bam_list="$2"
outroot="$3"

ref="/mnt/beegfs/tloupis/ref_files/fasta/human/hg38/hg38.filtered.fa"
bed="/mnt/beegfs/tloupis/ref_files/bed_files/human/hg38/Hyper_Hema_primary_targets.bed"
germline="/mnt/beegfs/tloupis/ref_files/annotation_files_DBs/human/hg38/gnomad.exomes.r2.1.1.sites.liftover_grch38.vcf.gz"
gatk_jar="/software/gatk-4.6.0.0/gatk-package-4.6.0.0-local.jar"

echo "START $(date) on $(hostname)"
echo "mode=$mode"
echo "bam_list=$bam_list"
echo "outroot=$outroot"
echo "array_task=${SLURM_ARRAY_TASK_ID}"

source /software/usr/tloupis/.bashrc

bam=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$bam_list")
if [[ -z "${bam:-}" ]]; then
  echo "No BAM found for SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}" >&2
  exit 1
fi

base_name=$(basename "$bam" .bam)
sample="$base_name"
sample="${sample%_005_RG_strict}"
sample="${sample%_005_RG}"
sample="${sample%_RG_strict}"
sample="${sample%_RG}"

mutect_dir="$outroot/mutect2_${mode}"
norm_dir="$outroot/norm_${mode}"
mkdir -p "$mutect_dir" "$norm_dir" "$outroot/logs"

raw_vcf="$mutect_dir/${sample}.${mode}.mutect2.vcf.gz"
norm_vcf="$norm_dir/${sample}.${mode}.mutect2.norm.vcf.gz"

set +u
conda activate gatk
set -u

java -jar "$gatk_jar" Mutect2 \
  -R "$ref" \
  -I "$bam" \
  -tumor "$sample" \
  -L "$bed" \
  -O "$raw_vcf" \
  --af-of-alleles-not-in-resource 0.00003125 \
  --native-pair-hmm-threads "${SLURM_CPUS_PER_TASK}" \
  --dont-use-soft-clipped-bases true \
  --max-reads-per-alignment-start 0 \
  --max-mnp-distance 0 \
  --germline-resource "$germline" \
  > "$outroot/logs/${sample}.${mode}.mutect2.out" \
  2> "$outroot/logs/${sample}.${mode}.mutect2.err"

set +u
conda deactivate
conda activate userbase
set -u

bcftools norm \
  -f "$ref" \
  -m -any \
  -Oz \
  -o "$norm_vcf" \
  "$raw_vcf" \
  > "$outroot/logs/${sample}.${mode}.bcftools_norm.out" \
  2> "$outroot/logs/${sample}.${mode}.bcftools_norm.err"

bcftools index -f -t "$norm_vcf"

set +u
conda deactivate
set -u

echo "DONE $(date): $sample $mode"

