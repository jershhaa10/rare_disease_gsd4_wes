#!/bin/bash
#SBATCH --job-name=gnomad_XY
#SBATCH --partition=short
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --output=xy_%j.out

set -euo pipefail

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"
DIR="$PROJECT/annotation/gnomad"

BASE="https://grch38.togovar.org/downloads/release/current/grch38/frequency/vcf/gnomad_exomes"

INPUT="$PROJECT/annotation/TRIO.clinvar.gnomad_autosomes.vcf.gz"

for chr in X Y; do

    echo "===== Processing chromosome $chr ====="

    RAW="$DIR/gnomad_exomes.v4.1.chr${chr}.grch38.vcf.gz"
    RENAMED="$DIR/gnomad_chr${chr}_renamed.vcf.gz"
    OUTPUT="$DIR/trio_gnomad_${chr}.vcf.gz"

    curl -fL --retry 5 -C - \
        -o "$RAW" \
        "$BASE/$(basename "$RAW")"

    printf 'chr%s\t%s\n' "$chr" "$chr" \
        > "$DIR/rename_chr${chr}.txt"

    bcftools annotate \
        --rename-chrs "$DIR/rename_chr${chr}.txt" \
        -Oz -o "$RENAMED" "$RAW"

    bcftools index -f -t "$RENAMED"

    bcftools annotate \
        -a "$RENAMED" \
        -h "$DIR/gnomad_header.txt" \
        -c CHROM,POS,REF,ALT,GNOMAD_AF:=INFO/AF,GNOMAD_AC:=INFO/AC,GNOMAD_AN:=INFO/AN,GNOMAD_AAC:=INFO/AAC \
        --pair-logic exact \
        -Oz -o "$OUTPUT" "$INPUT"

    bcftools index -f -t "$OUTPUT"

    INPUT="$OUTPUT"

    echo "Completed chromosome $chr"

done

FINAL="$PROJECT/annotation/TRIO.clinvar.gnomad_all.vcf.gz"

cp "$INPUT" "$FINAL"
bcftools index -f -t "$FINAL"

echo "ALL CHROMOSOME ANNOTATIONS COMPLETE"
