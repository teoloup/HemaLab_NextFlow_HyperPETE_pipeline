#!/usr/bin/env bash
#SBATCH --job-name=pon_build
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=80G
#SBATCH --time=24:00:00
#SBATCH --output=/mnt/beegfs/tloupis/slurmstout/%x_%j.out
#SBATCH --error=/mnt/beegfs/tloupis/slurmstout/%x_%j.err

set -euo pipefail
shopt -s nullglob

outroot="$1"
threshold_fraction="${2:-0.50}"

ref="/mnt/beegfs/tloupis/ref_files/fasta/human/hg38/hg38.filtered.fa"
bed="/mnt/beegfs/tloupis/ref_files/bed_files/human/hg38/Hyper_Hema_primary_targets.bed"
germline="/mnt/beegfs/tloupis/ref_files/annotation_files_DBs/human/hg38/gnomad.exomes.r2.1.1.sites.liftover_grch38.vcf.gz"
gatk_jar="/software/gatk-4.6.0.0/gatk-package-4.6.0.0-local.jar"

echo "START $(date) on $(hostname)"
echo "outroot=$outroot"
echo "threshold_fraction=$threshold_fraction"

source /software/usr/tloupis/.bashrc
mkdir -p "$outroot"/{lists,gdb,pon,logs}

make_map() {
  local mode="$1"
  local norm_dir="$outroot/norm_${mode}"
  local map="$outroot/lists/${mode}.sample_map.tsv"
  : > "$map"

  for vcf in "$norm_dir"/*.vcf.gz; do
    local sample
    sample=$(basename "$vcf")
    sample="${sample%%.${mode}.mutect2.norm.vcf.gz}"
    printf "%s\t%s\n" "$sample" "$vcf" >> "$map"
  done

  echo "$map"
}

build_one() {
  local mode="$1"
  local map
  local n
  local min_count

  map=$(make_map "$mode")
  n=$(wc -l < "$map")
  if [[ "$n" -eq 0 ]]; then
    echo "No normalized VCFs found for $mode" >&2
    exit 1
  fi

  min_count=$(python - <<PY
import math
print(max(2, math.ceil($n * $threshold_fraction)))
PY
)

  echo "$mode samples=$n min-sample-count=$min_count"

  rm -rf "$outroot/gdb/${mode}_pon_db"

  set +u
  conda activate gatk
  set -u

  java -jar "$gatk_jar" GenomicsDBImport \
    -R "$ref" \
    -L "$bed" \
    --sample-name-map "$map" \
    --genomicsdb-workspace-path "$outroot/gdb/${mode}_pon_db" \
    > "$outroot/logs/${mode}.genomicsdbimport.out" \
    2> "$outroot/logs/${mode}.genomicsdbimport.err"

  java -jar "$gatk_jar" CreateSomaticPanelOfNormals \
    -R "$ref" \
    -V "gendb://$outroot/gdb/${mode}_pon_db" \
    --germline-resource "$germline" \
    --min-sample-count "$min_count" \
    -O "$outroot/pon/PoN_${mode}_controls.new.vcf.gz" \
    > "$outroot/logs/${mode}.create_pon.out" \
    2> "$outroot/logs/${mode}.create_pon.err"

  set +u
  conda deactivate
  conda activate userbase
  set -u

  bcftools index -f -t "$outroot/pon/PoN_${mode}_controls.new.vcf.gz"

  set +u
  conda deactivate
  set -u
}

build_one umi2
build_one umi4

set +u
conda activate userbase
set -u

sha256sum "$outroot"/pon/*.vcf.gz "$outroot"/pon/*.tbi > "$outroot/pon/checksums.sha256"

bcftools view -H -r chr20:32434630-32434645 "$outroot/pon/PoN_umi2_controls.new.vcf.gz" \
  > "$outroot/pon/check_chr20_32434638_umi2.txt"
bcftools view -H -r chr20:32434630-32434645 "$outroot/pon/PoN_umi4_controls.new.vcf.gz" \
  > "$outroot/pon/check_chr20_32434638_umi4.txt"

set +u
conda deactivate
set -u

echo "DONE $(date)"
echo "$outroot/pon/PoN_umi2_controls.new.vcf.gz"
echo "$outroot/pon/PoN_umi4_controls.new.vcf.gz"

