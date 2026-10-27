#!/bin/bash
#SBATCH --job-name=trio_inheritance
#SBATCH --partition=short
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=slurm_%j.out

set -euo pipefail

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"
VCF="$PROJECT/annotation/TRIO.clinvar.gnomad_all.vcf.gz"
OUT="$PROJECT/results/inheritance"

mkdir -p "$OUT"

# Confirm sample order
EXPECTED=$'FATHER\nMOTHER\nPROBAND'
ACTUAL=$(bcftools query -l "$VCF")
[[ "$ACTUAL" == "$EXPECTED" ]] || {
    echo "ERROR: Unexpected sample order"
    exit 1
}

# Extract autosomal genotypes into a table
bcftools view -r "$(seq -s, 1 22)" -m2 -M2 -v snps,indels -Ou "$VCF" |
bcftools query \
    -f '%CHROM\t%POS\t%REF\t%ALT[\t%GT]\n' \
    > "$OUT/trio_genotypes.tsv"

# Screen genotype patterns
awk -F'\t' -v OFS='\t' '
BEGIN {
    print "CHROM","POS","REF","ALT","FATHER","MOTHER","PROBAND" > "'"$OUT"'/homozygous_recessive.tsv"
    print "CHROM","POS","REF","ALT","FATHER","MOTHER","PROBAND" > "'"$OUT"'/potential_denovo.tsv"
    print "CHROM","POS","REF","ALT","FATHER","MOTHER","PROBAND" > "'"$OUT"'/paternal_het.tsv"
    print "CHROM","POS","REF","ALT","FATHER","MOTHER","PROBAND" > "'"$OUT"'/maternal_het.tsv"
}
{
    f=$5; m=$6; p=$7

    if (f=="0/1" && m=="0/1" && p=="1/1")
        print > "'"$OUT"'/homozygous_recessive.tsv"

    if (f=="0/0" && m=="0/0" && p=="0/1")
        print > "'"$OUT"'/potential_denovo.tsv"

    if (f=="0/1" && m=="0/0" && p=="0/1")
        print > "'"$OUT"'/paternal_het.tsv"

    if (f=="0/0" && m=="0/1" && p=="0/1")
        print > "'"$OUT"'/maternal_het.tsv"
}
' "$OUT/trio_genotypes.tsv"

echo "===== RESULTS ====="
for file in "$OUT"/*.tsv; do
    echo "$(basename "$file"): $(wc -l < "$file") lines"
done

echo "TRIO INHERITANCE SCREEN COMPLETE"
