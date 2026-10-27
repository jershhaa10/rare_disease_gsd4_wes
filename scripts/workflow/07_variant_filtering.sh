#!/bin/bash
#SBATCH --job-name=trio_filter
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=12G
#SBATCH --time=02:00:00
#SBATCH --output=trio_filter_%j.out
#SBATCH --error=trio_filter_%j.err

set -euo pipefail

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"
REF="$PROJECT/reference/GCF_000001405.40_GRCh38.p14_genomic.fna"
GATK="$PROJECT/containers/gatk_4.6.2.0.sif"
INPUT="$PROJECT/variants/joint_genotyping/TRIO.joint.vcf.gz"
OUT="$PROJECT/variants/filtered"

mkdir -p "$OUT"

echo "Selecting SNPs..."
apptainer exec --bind "$PROJECT:$PROJECT" "$GATK" \
  gatk SelectVariants \
  -R "$REF" \
  -V "$INPUT" \
  --select-type-to-include SNP \
  -O "$OUT/TRIO.snps.vcf.gz"

echo "Selecting indels..."
apptainer exec --bind "$PROJECT:$PROJECT" "$GATK" \
  gatk SelectVariants \
  -R "$REF" \
  -V "$INPUT" \
  --select-type-to-include INDEL \
  -O "$OUT/TRIO.indels.vcf.gz"

echo "SNP and indel selection completed."
