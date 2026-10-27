#!/bin/bash
#SBATCH --job-name=integrate_vep
#SBATCH --partition=short
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=integrate_vep_%j.out

set -euo pipefail

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"

bcftools annotate \
  -a "$PROJECT/annotation/TRIO.vep.vcf.gz" \
  -c INFO/CSQ \
  -Oz \
  -o "$PROJECT/annotation/TRIO.final_annotated.vcf.gz" \
  "$PROJECT/annotation/TRIO.clinvar.gnomad_all.vcf.gz"

bcftools index -t "$PROJECT/annotation/TRIO.final_annotated.vcf.gz"

echo "===== VALIDATION ====="

echo "Total variants:"
bcftools view -H "$PROJECT/annotation/TRIO.final_annotated.vcf.gz" | wc -l

echo "Variants with VEP annotations:"
bcftools view -H -i 'INFO/CSQ!="."' \
  "$PROJECT/annotation/TRIO.final_annotated.vcf.gz" | wc -l

echo "VEP INTEGRATION COMPLETE"
