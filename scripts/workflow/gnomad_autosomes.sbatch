#!/bin/bash
#SBATCH --job-name=gnomad_wes
#SBATCH --partition=short
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=slurm_%j.out

set -euo pipefail

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"
DIR="$PROJECT/annotation/gnomad"
BASE="https://grch38.togovar.org/downloads/release/current/grch38/frequency/vcf/gnomad_exomes"

INPUT="$PROJECT/annotation/TRIO.clinvar.gnomad_chr3.vcf.gz"

for chr in {1..22}; do

    # Chromosome 3 is already annotated
    [[ "$chr" == "3" ]] && continue

    echo "===== Processing chromosome $chr ====="

    RAW="$DIR/gnomad_exomes.v4.1.chr${chr}.grch38.vcf.gz"
    RENAMED="$DIR/gnomad_chr${chr}_renamed.vcf.gz"
    OUTPUT="$DIR/trio_gnomad_step_chr${chr}.vcf.gz"

    # Resume from a completed chromosome
    if [[ -s "$OUTPUT" && -s "$OUTPUT.tbi" ]]; then
        INPUT="$OUTPUT"
        echo "Reusing chromosome $chr"
        continue
    fi

    # Download with resume support
    wget -c --tries=5 --timeout=60 \
        "$BASE/$(basename "$RAW")" -O "$RAW"

    # Standardize chromosome naming
    printf 'chr%s\t%s\n' "$chr" "$chr" > "$DIR/rename_chr${chr}.txt"

    bcftools annotate \
        --rename-chrs "$DIR/rename_chr${chr}.txt" \
        -Oz -o "$RENAMED" "$RAW"

    bcftools index -f -t "$RENAMED"

    # Transfer population frequency annotations
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

# Final autosomal annotation file
cp "$INPUT" "$PROJECT/annotation/TRIO.clinvar.gnomad_autosomes.vcf.gz"

bcftools index -f -t \
    "$PROJECT/annotation/TRIO.clinvar.gnomad_autosomes.vcf.gz"

echo "AUTOSOMAL GNOMAD ANNOTATION COMPLETE"
