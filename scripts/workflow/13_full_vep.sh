#!/bin/bash
set -euo pipefail

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"

INPUT="$PROJECT/variants/filtered/TRIO.pass.vcf.gz"
RENAMED="$PROJECT/annotation/TRIO.ensembl.vcf.gz"
OUTPUT="$PROJECT/annotation/TRIO.vep.vcf"

echo "Step 1: Converting chromosome names..."

bcftools annotate \
  --rename-chrs "$PROJECT/annotation/chromosome_map.txt" \
  -Oz \
  -o "$RENAMED" \
  "$INPUT"

bcftools index -t -f "$RENAMED"

echo "Step 2: Running VEP functional annotation..."

apptainer exec \
  --bind "$PROJECT:$PROJECT" \
  "$PROJECT/containers/vep_115.2.sif" \
  vep \
  --input_file "$RENAMED" \
  --output_file "$OUTPUT" \
  --format vcf \
  --vcf \
  --cache \
  --offline \
  --dir_cache "$PROJECT/annotation/vep_cache" \
  --species homo_sapiens \
  --assembly GRCh38 \
  --no_stats \
  --force_overwrite

echo "Step 3: Checking variant counts..."

echo "Original:"
bcftools view -H "$INPUT" | wc -l

echo "Renamed:"
bcftools view -H "$RENAMED" | wc -l

echo "Annotated:"
bcftools view -H "$OUTPUT" | wc -l

echo "Full VEP annotation finished."
