#!/bin/bash
set -euo pipefail

# Project reference directory
REF="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}/reference"

# Input files
BED="$REF/S07604514_Covered_noheader.hg38.bed"
FAI="$REF/GCF_000001405.40_GRCh38.p14_genomic.fna.fai"

# Output files
CONVERTED="$REF/S07604514_Covered_NCBI_GRCh38.bed"
MERGED="$REF/S07604514_Covered_NCBI_GRCh38_merged.bed"

# Convert chromosome names from chr1 to NC_000001.11, etc.

awk 'BEGIN {OFS="\t"}
NR==FNR {
    if ($1 ~ /^NC_0000[0-9]+\./) {
        n = $1
        sub(/^NC_/, "", n)
        sub(/\..*$/, "", n)
	n = n + 0
        if (n >= 1 && n <= 22)
            map["chr" (n+0)] = $1
        else if (n == 23)
            map["chrX"] = $1
        else if (n == 24)
            map["chrY"] = $1
    }
    next
}
{
    if (!($1 in map)) {
        print "Unknown chromosome: " $1 > "/dev/stderr"
        exit 1
    }
    $1 = map[$1]
    print
}' "$FAI" "$BED" > "$CONVERTED"

# Validate BED coordinates
echo "Validating BED intervals..."

awk 'BEGIN {FS=OFS="\t"}
NR==FNR {
    chr_length[$1]=$2
    next
}
{
    total++
    if (!($1 in chr_length) ||
        $2 !~ /^[0-9]+$/ ||
        $3 !~ /^[0-9]+$/ ||
        $2 >= $3 ||
        $3 > chr_length[$1]) {
        invalid++
        print "Invalid interval:", $0 > "/dev/stderr"
    }
}
END {
    print "Total target intervals:", total
    print "Invalid intervals:", invalid+0
    if (invalid > 0 || total == 0) exit 1
}' "$FAI" "$CONVERTED"

# Merge overlapping or adjacent BED intervals
echo "Merging target intervals..."

sort -k1,1 -k2,2n "$CONVERTED" |
awk 'BEGIN {OFS="\t"}
NR==1 {
    chr=$1; start=$2; end=$3
    next
}
{
    if ($1==chr && $2<=end) {
        if ($3>end) end=$3
    } else {
        print chr, start, end
        chr=$1; start=$2; end=$3
    }
}
END {
    if (NR>0) print chr, start, end
}' > "$MERGED"

echo "Merged intervals: $(wc -l < "$MERGED")"
echo "Target preparation complete!"
