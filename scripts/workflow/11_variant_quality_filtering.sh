#!/bin/bash
#SBATCH --job-name=trio_quality
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=12G
#SBATCH --time=02:00:00
#SBATCH --output=trio_quality_%j.out
#SBATCH --error=trio_quality_%j.err

set -euo pipefail

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"
GATK="$PROJECT/containers/gatk_4.6.2.0.sif"
INPUT="$PROJECT/variants/filtered/TRIO.normalized.vcf.gz"
OUTPUT="$PROJECT/variants/filtered/TRIO.quality_filtered.vcf.gz"

echo "Starting variant quality filtering..."

apptainer exec --bind "$PROJECT:$PROJECT" "$GATK" \
  gatk --java-options "-Xmx8g" VariantFiltration \
  -V "$INPUT" \
  -O "$OUTPUT" \
  --filter-name "LowQD" \
  --filter-expression "QD < 2.0" \
  --filter-name "SNP_HighFS" \
  --filter-expression "vc.isSNP() && FS > 60.0" \
  --filter-name "SNP_HighSOR" \
  --filter-expression "vc.isSNP() && SOR > 3.0" \
  --filter-name "SNP_LowMQ" \
  --filter-expression "vc.isSNP() && MQ < 40.0" \
  --filter-name "SNP_LowMQRankSum" \
  --filter-expression "vc.isSNP() && MQRankSum < -12.5" \
  --filter-name "SNP_LowReadPosRankSum" \
  --filter-expression "vc.isSNP() && ReadPosRankSum < -8.0" \
  --filter-name "INDEL_HighFS" \
  --filter-expression "vc.isIndel() && FS > 200.0" \
  --filter-name "INDEL_HighSOR" \
  --filter-expression "vc.isIndel() && SOR > 10.0" \
  --filter-name "INDEL_LowReadPosRankSum" \
  --filter-expression "vc.isIndel() && ReadPosRankSum < -20.0"

echo "=== Original normalized records ==="
module load bcftools/1.21
bcftools view -H "$INPUT" | wc -l

echo "=== Filtered VCF records ==="
bcftools view -H "$OUTPUT" | wc -l

echo "=== FILTER status counts ==="
bcftools query -f '%FILTER\n' "$OUTPUT" | sort | uniq -c

echo "Quality filtering completed."
