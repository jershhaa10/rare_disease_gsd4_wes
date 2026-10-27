#!/bin/bash
#SBATCH --job-name=mark_mother
#SBATCH --partition=short
#SBATCH --cpus-per-task=2
#SBATCH --mem=24G
#SBATCH --time=08:00:00
#SBATCH --output=mark_mother_%j.out
#SBATCH --error=mark_mother_%j.err

set -euo pipefail

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"
GATK="$PROJECT/containers/gatk_4.6.2.0.sif"

INPUT="$PROJECT/bam/MOTHER.sorted.bam"
OUTPUT="$PROJECT/bam/marked/MOTHER.markdup.bam"
METRICS="$PROJECT/qc/duplicates/MOTHER.duplicates_metrics.txt"
TMP="$PROJECT/tmp/markduplicates/MOTHER"

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

echo "MarkDuplicates completed successfully for MOTHER."
