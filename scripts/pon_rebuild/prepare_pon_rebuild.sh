#!/usr/bin/env bash
set -euo pipefail

base="/mnt/beegfs/tloupis/HematologyNGS/HyperPetePanel_v0200567846"
outroot="${1:-$base/PoN_rebuild_$(date +%Y%m%d_%H%M%S)}"

mkdir -p "$outroot"/{lists,mutect2_umi2,mutect2_umi4,norm_umi2,norm_umi4,gdb,pon,logs}
mkdir -p /mnt/beegfs/tloupis/slurmstout

find "$base"/analysis/2025 "$base"/analysis/2026 \
  -type f \
  -name '*005_RG.bam' \
  ! -name '*005_RG_strict.bam' \
  | sort > "$outroot/lists/umi2_bams.txt"

find "$base"/analysis/2025 "$base"/analysis/2026 \
  -type f \
  -name '*005_RG_strict.bam' \
  | sort > "$outroot/lists/umi4_bams.txt"

echo "$outroot" > "$outroot/OUTROOT.txt"
echo "PoN rebuild output root:"
echo "$outroot"
echo
wc -l "$outroot/lists/"*.txt

