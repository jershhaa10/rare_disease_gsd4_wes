#!/bin/bash
set -euo pipefail

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"

echo "Starting VEP test annotation..."

apptainer exec \
  --bind "$PROJECT:$PROJECT" \
  "$PROJECT/containers/vep_115.2.sif" \
  vep \
  --input_file "$PROJECT/annotation/test_10.ensembl.vcf" \
  --output_file "$PROJECT/annotation/test_10.vep.vcf" \
  --format vcf \
  --vcf \
  --cache \
  --offline \
  --dir_cache "$PROJECT/annotation/vep_cache" \
  --species homo_sapiens \
  --assembly GRCh38 \
  --no_stats \
  --force_overwrite

echo "VEP test completed successfully!"
