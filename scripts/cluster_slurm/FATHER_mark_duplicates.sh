#!/bin/bash
#SBATCH --job-name=mark_father
#SBATCH --partition=short
#SBATCH --cpus-per-task=2
#SBATCH --mem=24G
#SBATCH --time=08:00:00
#SBATCH --output=mark_father_%j.out
#SBATCH --error=mark_father_%j.err

set -euo pipefail

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"
GATK="$PROJECT/containers/gatk_4.6.2.0.sif"

INPUT="$PROJECT/bam/FATHER.sorted.bam"
OUTPUT="$PROJECT/bam/marked/FATHER.markdup.bam"
METRICS="$PROJECT/qc/duplicates/FATHER.duplicates_metrics.txt"
TMP="$PROJECT/tmp/markduplicates/FATHER"

mkdir -p "$PROJECT/bam/marked" "$PROJECT/qc/duplicates" "$TMP"

module load samtools/1.21

apptainer exec "$GATK" gatk \
    --java-options "-Xmx16g -Djava.io.tmpdir=$TMP" \
    MarkDuplicates \
    --INPUT "$INPUT" \
    --OUTPUT "$OUTPUT" \
    --METRICS_FILE "$METRICS" \
    --TMP_DIR "$TMP" \
    --REMOVE_DUPLICATES false \
    --CREATE_INDEX true

samtools quickcheck -v "$OUTPUT"

echo "MarkDuplicates completed successfully for FATHER."
