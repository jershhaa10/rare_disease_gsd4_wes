#!/usr/bin/env python3

"""
Trio-WES Variant Prioritization
Disease focus: Glycogen Storage Disease Type IV (GSD IV)

Inputs:
    Annotated trio VCF containing VEP, ClinVar, and gnomAD annotations.

Outputs:
    Quality-filtered and rarity-filtered variants
    Inheritance classifications
    Functional consequence summaries
    Candidate compound heterozygous genes
    Prioritized candidate tables
"""

from pathlib import Path
import os
import subprocess

# --------------------------------------------------
# 1. PROJECT CONFIGURATION
# --------------------------------------------------

# Override with WES_PROJECT_DIR when running outside Explorer.
DEFAULT_PROJECT = Path(__file__).resolve().parents[1]
PROJECT = Path(os.environ.get("WES_PROJECT_DIR", str(DEFAULT_PROJECT))).expanduser()

INPUT_VCF = PROJECT / "annotation" / "TRIO.final_annotated.vcf.gz"

OUTPUT_DIR = (
    PROJECT / "results" / "prioritization" / "reproducibility_test"
)

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# --------------------------------------------------
# 2. FILTERING PARAMETERS
# --------------------------------------------------

MIN_DEPTH = 10
MIN_GQ = 20
MAX_GNOMAD_AF = 0.001

SAMPLES = ["FATHER", "MOTHER", "PROBAND"]

# --------------------------------------------------
# 3. INPUT VALIDATION
# --------------------------------------------------

def validate_inputs():
    if not INPUT_VCF.exists():
        raise FileNotFoundError(
            f"Annotated VCF not found: {INPUT_VCF}"
        )

    print("Trio-WES Variant Prioritization")
    print(f"Input VCF: {INPUT_VCF}")
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"Minimum depth: {MIN_DEPTH}")
    print(f"Minimum genotype quality: {MIN_GQ}")
    print(f"Maximum gnomAD AF threshold: {MAX_GNOMAD_AF}")



# --------------------------------------------------
# 4. QUALITY AND RARITY FILTERING
# --------------------------------------------------

def filter_variants():
    output_vcf = OUTPUT_DIR / "TRIO.quality_rare.vcf.gz"

    filter_expression = (
        f"FMT/DP[0]>={MIN_DEPTH} && FMT/GQ[0]>={MIN_GQ} && "
        f"FMT/DP[1]>={MIN_DEPTH} && FMT/GQ[1]>={MIN_GQ} && "
        f"FMT/DP[2]>={MIN_DEPTH} && FMT/GQ[2]>={MIN_GQ} && "
        f'(INFO/GNOMAD_AF<{MAX_GNOMAD_AF} || INFO/GNOMAD_AF=".")'
    )

    # Verify sample order before using sample indices.
    result = subprocess.run(
        ["bcftools", "query", "-l", str(INPUT_VCF)],
        capture_output=True,
        text=True,
        check=True
    )

    actual_samples = result.stdout.strip().splitlines()

    if actual_samples != SAMPLES:
        raise ValueError(
            f"Unexpected sample order: {actual_samples}. "
            f"Expected: {SAMPLES}"
        )

    subprocess.run(
        [
            "bcftools", "view",
            "-i", filter_expression,
            "-Oz",
            "-o", str(output_vcf),
            str(INPUT_VCF)
        ],
        check=True
    )

    subprocess.run(
        ["bcftools", "index", "-t", "-f", str(output_vcf)],
        check=True
    )

    result = subprocess.run(
        ["bcftools", "view", "-H", str(output_vcf)],
        capture_output=True,
        text=True,
        check=True
    )

    variant_count = len(result.stdout.splitlines())

    print(f"\nFiltered variants: {variant_count}")
    print(f"Output: {output_vcf}")

    if variant_count != 5614:
        print("WARNING: Count differs from the original 5,614 variants.")
    else:
        print("PASS: Filtering reproduces the original count.")



# --------------------------------------------------
# 5. INHERITANCE CLASSIFICATION
# --------------------------------------------------

def classify_inheritance():
    input_vcf = OUTPUT_DIR / "TRIO.quality_rare.vcf.gz"
    output_tsv = OUTPUT_DIR / "inheritance_classification.tsv"

    genotype_patterns = {
        ("0/1", "0/1", "1/1"): "homozygous_recessive",
        ("0/0", "0/0", "0/1"): "potential_de_novo",
        ("0/1", "0/0", "0/1"): "paternal",
        ("0/0", "0/1", "0/1"): "maternal",
    }

    counts = {
        "homozygous_recessive": 0,
        "potential_de_novo": 0,
        "paternal": 0,
        "maternal": 0,
        "other": 0,
    }

    query_format = (
        "%CHROM\t%POS\t%REF\t%ALT"
        "[\t%GT]\n"
    )

    process = subprocess.Popen(
        ["bcftools", "query", "-f", query_format, str(input_vcf)],
        stdout=subprocess.PIPE,
        text=True
    )

    with output_tsv.open("w") as output:
        output.write(
            "CHROM\tPOS\tREF\tALT\tFATHER_GT\t"
            "MOTHER_GT\tPROBAND_GT\tINHERITANCE\n"
        )

        for line in process.stdout:
            fields = line.rstrip("\n").split("\t")

            if len(fields) != 7:
                raise ValueError(f"Unexpected VCF query row: {line}")

            chrom, pos, ref, alt = fields[:4]
            # Preserve genotype notation to reproduce Step 17.
            # Phased genotypes are retained but classified as "other".
            genotypes = tuple(fields[4:])

            inheritance = genotype_patterns.get(
                genotypes, "other"
            )

            counts[inheritance] += 1

            output.write(
                "\t".join(
                    [chrom, pos, ref, alt]
                    + list(genotypes)
                    + [inheritance]
                ) + "\n"
            )

    if process.wait() != 0:
        raise RuntimeError("bcftools query failed.")

    print("\nInheritance classification:")
    for category, count in counts.items():
        print(f"  {category}: {count}")

    print(f"Output: {output_tsv}")

    expected = {
        "homozygous_recessive": 88,
        "potential_de_novo": 46,
        "paternal": 897,
        "maternal": 918,
        "other": 3665,
    }

    if counts == expected:
        print("PASS: Inheritance counts match Step 17.")
    else:
        print("WARNING: Inheritance counts differ from Step 17.")



# --------------------------------------------------
# 6. FUNCTIONAL IMPACT CLASSIFICATION
# --------------------------------------------------

def classify_impact():
    input_vcf = OUTPUT_DIR / "TRIO.quality_rare.vcf.gz"
    output_tsv = OUTPUT_DIR / "functional_impact.tsv"

    query_format = "%CHROM\t%POS\t%REF\t%ALT\t%INFO/CSQ\n"

    process = subprocess.Popen(
        ["bcftools", "query", "-f", query_format, str(input_vcf)],
        stdout=subprocess.PIPE,
        text=True
    )

    counts = {
        "HIGH": 0,
        "MODERATE": 0,
        "OTHER": 0,
        "NO_CSQ": 0
    }

    with output_tsv.open("w") as output:
        output.write("CHROM\tPOS\tREF\tALT\tIMPACT\n")

        for line in process.stdout:
            chrom, pos, ref, alt, csq = line.rstrip("\n").split("\t", 4)

            if csq == ".":
                impact = "NO_CSQ"
            else:
                # VEP CSQ format normally places IMPACT
                # in the third pipe-separated field.
                impacts = {
                    annotation.split("|")[2]
                    for annotation in csq.split(",")
                    if len(annotation.split("|")) > 2
                }

                if "HIGH" in impacts:
                    impact = "HIGH"
                elif "MODERATE" in impacts:
                    impact = "MODERATE"
                else:
                    impact = "OTHER"

            counts[impact] += 1

            output.write(
                f"{chrom}\t{pos}\t{ref}\t{alt}\t{impact}\n"
            )

    if process.wait() != 0:
        raise RuntimeError("bcftools query failed.")

    print("\nFunctional impact classification:")

    for category, count in counts.items():
        print(f"  {category}: {count}")

    total = counts["HIGH"] + counts["MODERATE"]
    print(f"  HIGH/MODERATE total: {total}")
    print(f"Output: {output_tsv}")

    if (
        counts["HIGH"] == 96
        and counts["MODERATE"] == 1095
        and total == 1191
    ):
        print("PASS: Functional impact counts match Step 17.")
    else:
        print("WARNING: Functional impact counts differ from Step 17.")



# --------------------------------------------------
# 7. COMBINE INHERITANCE AND FUNCTIONAL IMPACT
# --------------------------------------------------

def combine_evidence():
    inheritance_file = OUTPUT_DIR / "inheritance_classification.tsv"
    impact_file = OUTPUT_DIR / "functional_impact.tsv"
    output_file = OUTPUT_DIR / "candidate_evidence.tsv"

    import csv

    def variant_key(row):
        return (
            row["CHROM"],
            row["POS"],
            row["REF"],
            row["ALT"]
        )

    with impact_file.open() as handle:
        impact_lookup = {
            variant_key(row): row["IMPACT"]
            for row in csv.DictReader(handle, delimiter="\t")
        }

    counts = {
        "homozygous_recessive": 0,
        "potential_de_novo": 0,
        "paternal": 0,
        "maternal": 0
    }

    with inheritance_file.open() as source, \
         output_file.open("w") as destination:

        reader = csv.DictReader(source, delimiter="\t")
        fieldnames = reader.fieldnames + ["IMPACT"]

        writer = csv.DictWriter(
            destination,
            fieldnames=fieldnames,
            delimiter="\t"
        )
        writer.writeheader()

        for row in reader:
            key = variant_key(row)

            if key not in impact_lookup:
                raise ValueError(f"Missing impact for variant: {key}")

            row["IMPACT"] = impact_lookup[key]
            writer.writerow(row)

            if (
                row["IMPACT"] in {"HIGH", "MODERATE"}
                and row["INHERITANCE"] in counts
            ):
                counts[row["INHERITANCE"]] += 1

    expected = {
        "homozygous_recessive": 11,
        "potential_de_novo": 5,
        "paternal": 259,
        "maternal": 238
    }

    print("\nHIGH/MODERATE variants by inheritance:")

    for category, count in counts.items():
        print(f"  {category}: {count}")

    print(f"Output: {output_file}")

    if counts == expected:
        print("PASS: Candidate counts match Step 17.")
    else:
        print("WARNING: Candidate counts differ from Step 17.")



# --------------------------------------------------
# 8. PRELIMINARY COMPOUND HETEROZYGOUS SCREENING
# --------------------------------------------------

def screen_compound_heterozygotes():
    import csv
    from collections import defaultdict

    input_vcf = OUTPUT_DIR / "TRIO.quality_rare.vcf.gz"
    evidence_file = OUTPUT_DIR / "candidate_evidence.tsv"

    parental_output = OUTPUT_DIR / "parental_gene_variants.tsv"
    gene_output = OUTPUT_DIR / "compound_het_genes.tsv"

    # Read inheritance and functional impact classifications.
    with evidence_file.open() as handle:
        evidence = {
            (row["CHROM"], row["POS"], row["REF"], row["ALT"]): row
            for row in csv.DictReader(handle, delimiter="\t")
        }

    # Extract variant-level VEP annotations.
    query_format = "%CHROM\t%POS\t%REF\t%ALT\t%INFO/CSQ\n"

    process = subprocess.Popen(
        ["bcftools", "query", "-f", query_format, str(input_vcf)],
        stdout=subprocess.PIPE,
        text=True
    )

    gene_variants = defaultdict(lambda: {"paternal": set(), "maternal": set()})

    for line in process.stdout:
        chrom, pos, ref, alt, csq = line.rstrip("\n").split("\t", 4)
        key = (chrom, pos, ref, alt)

        record = evidence.get(key)

        if record is None:
            raise ValueError(f"Missing evidence for {key}")

        if record["INHERITANCE"] not in {"paternal", "maternal"}:
            continue

        if record["IMPACT"] not in {"HIGH", "MODERATE"}:
            continue

        if csq == ".":
            continue

        for annotation in csq.split(","):
            fields = annotation.split("|")

            if len(fields) < 4:
                continue

            impact = fields[2]
            gene = fields[3]

            if not gene or impact not in {"HIGH", "MODERATE"}:
                continue

            gene_variants[gene][record["INHERITANCE"]].add(key)

    if process.wait() != 0:
        raise RuntimeError("bcftools query failed.")

    # Save all qualifying parental gene-variant associations.
    with parental_output.open("w") as handle:
        handle.write(
            "GENE\tINHERITANCE\tCHROM\tPOS\tREF\tALT\n"
        )

        for gene in sorted(gene_variants):
            for inheritance in ("paternal", "maternal"):
                for variant in sorted(gene_variants[gene][inheritance]):
                    handle.write(
                        f"{gene}\t{inheritance}\t"
                        + "\t".join(variant) + "\n"
                    )

    # Identify genes containing variants from both parents.
    candidate_genes = []

    with gene_output.open("w") as handle:
        handle.write(
            "GENE\tPATERNAL_VARIANTS\tMATERNAL_VARIANTS\n"
        )

        for gene in sorted(gene_variants):
            paternal = gene_variants[gene]["paternal"]
            maternal = gene_variants[gene]["maternal"]

            if paternal and maternal:
                candidate_genes.append(gene)

                handle.write(
                    f"{gene}\t{len(paternal)}\t{len(maternal)}\n"
                )

    print("\nPreliminary compound heterozygous genes:")
    for gene in candidate_genes:
        print(f"  {gene}")

    print(f"Total candidate genes: {len(candidate_genes)}")
    print(f"Output: {gene_output}")

    expected_genes = {
        "BTN2A2", "CIP2A", "DNAH1", "FHAD1",
        "MATN2", "OR10G9", "URB2"
    }

    if set(candidate_genes) == expected_genes:
        print("PASS: Compound heterozygous genes match Step 17.")
    else:
        print("WARNING: Compound heterozygous genes differ from Step 17.")



# --------------------------------------------------
# 9. FINAL CANDIDATE EVIDENCE TABLE
# --------------------------------------------------

def generate_candidate_table():
    import csv

    input_vcf = OUTPUT_DIR / "TRIO.quality_rare.vcf.gz"
    evidence_file = OUTPUT_DIR / "candidate_evidence.tsv"
    output_file = OUTPUT_DIR / "final_candidate_table.tsv"

    with evidence_file.open() as handle:
        candidates = {
            (row["CHROM"], row["POS"], row["REF"], row["ALT"]): row
            for row in csv.DictReader(handle, delimiter="\t")
            if (
                row["IMPACT"] in {"HIGH", "MODERATE"}
                and row["INHERITANCE"] in {
                    "homozygous_recessive",
                    "potential_de_novo"
                }
            )
        }

    query_format = (
        "%CHROM\t%POS\t%REF\t%ALT\t"
        "%INFO/CSQ\t%INFO/CLNSIG\t"
        "%INFO/CLNREVSTAT\t%INFO/GNOMAD_AF\n"
    )

    process = subprocess.Popen(
        ["bcftools", "query", "-f", query_format, str(input_vcf)],
        stdout=subprocess.PIPE,
        text=True
    )

    fieldnames = [
        "CHROM", "POS", "REF", "ALT", "GENE",
        "CONSEQUENCE", "IMPACT", "INHERITANCE",
        "GNOMAD_AF", "CLNSIG", "CLNREVSTAT",
        "FATHER_GT", "MOTHER_GT", "PROBAND_GT"
    ]

    written = set()

    with output_file.open("w") as handle:
        writer = csv.DictWriter(
            handle, fieldnames=fieldnames, delimiter="\t"
        )
        writer.writeheader()

        for line in process.stdout:
            fields = line.rstrip("\n").split("\t", 7)

            if len(fields) != 8:
                raise ValueError(f"Unexpected annotation row: {line}")

            chrom, pos, ref, alt, csq, clnsig, revstat, af = fields
            key = (chrom, pos, ref, alt)

            if key not in candidates:
                continue

            record = candidates[key]

            # Select an annotation consistent with the
            # variant's highest-impact classification.
            selected = None

            if csq != ".":
                for annotation in csq.split(","):
                    parts = annotation.split("|")

                    if len(parts) < 4:
                        continue

                    if parts[2] == record["IMPACT"]:
                        selected = parts
                        break

            gene = selected[3] if selected else "."
            consequence = selected[1] if selected else "."

            writer.writerow({
                "CHROM": chrom,
                "POS": pos,
                "REF": ref,
                "ALT": alt,
                "GENE": gene or ".",
                "CONSEQUENCE": consequence,
                "IMPACT": record["IMPACT"],
                "INHERITANCE": record["INHERITANCE"],
                "GNOMAD_AF": af,
                "CLNSIG": clnsig,
                "CLNREVSTAT": revstat,
                "FATHER_GT": record["FATHER_GT"],
                "MOTHER_GT": record["MOTHER_GT"],
                "PROBAND_GT": record["PROBAND_GT"]
            })

            written.add(key)

    if process.wait() != 0:
        raise RuntimeError("bcftools query failed.")

    if written != set(candidates):
        raise RuntimeError(
            f"Missing {len(set(candidates) - written)} candidate variants."
        )

    print(f"\nFinal candidate variants: {len(written)}")
    print(f"Output: {output_file}")

    if len(written) == 16:
        print("PASS: Final candidate count matches Step 17.")
    else:
        print("WARNING: Candidate count differs from Step 17.")




# --------------------------------------------------
# 10. MAIN WORKFLOW
# --------------------------------------------------

def main():
    validate_inputs()
    filter_variants()
    classify_inheritance()
    classify_impact()
    combine_evidence()
    screen_compound_heterozygotes()
    generate_candidate_table()


if __name__ == "__main__":
    main()
