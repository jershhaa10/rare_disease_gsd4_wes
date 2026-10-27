#!/bin/bash
set -euo pipefail

module load bcftools/1.21

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"

INPUT="$PROJECT/variants/filtered/TRIO.quality_filtered.vcf.gz"
OUTPUT="$PROJECT/variants/filtered/TRIO.pass.vcf.gz"

mkdir -p "$(dirname "$OUTPUT")"

bcftools view \
  -f PASS \
  -Oz \
  -o "$OUTPUT" \
  "$INPUT"

bcftools index -t -f "$OUTPUT"

echo "PASS variants extracted:"
bcftools view -H "$OUTPUT" | wc -l
