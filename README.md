# Trio-WES Analysis for Rare Disease Variant Discovery

## Project Overview
A trio-based whole-exome sequencing (WES) analysis investigating
candidate variants associated with glycogen storage disease type IV
(GSD IV).

The workflow covers sequencing quality control, read alignment,
variant calling, joint genotyping, functional annotation, and
inheritance-aware variant prioritization.

## Dataset
Publicly available sequencing data from NCBI SRA:

- Father: SRR27997290
- Mother: SRR27997291
- Proband: SRR27997292

Reference genome: GRCh38.p14

## Analysis Workflow
1. FASTQ quality assessment using FastQC and MultiQC
2. Read alignment and BAM processing
3. Base quality score recalibration
4. GATK HaplotypeCaller and trio joint genotyping
5. Variant quality filtering
6. Functional annotation using VEP, ClinVar, and gnomAD
7. Inheritance-aware variant prioritization
8. Candidate variant investigation

## Key Results
- 68,523 PASS variants
- 5,614 variants retained after quality and rarity screening
- 1,191 variants with HIGH or MODERATE predicted impact
- 11 homozygous recessive and 5 potential de novo candidates
  within the HIGH/MODERATE subset

A homozygous missense variant in GBE1 (GRCh38, chr3:81648954 C>G)
was identified in the proband, with both parents heterozygous.

ClinVar currently classifies the variant as uncertain significance
in the annotation used for this analysis. The observed inheritance
pattern supports its prioritization but does not establish
pathogenicity.

## Reproducibility
The variant prioritization analysis is implemented in:

`scripts/variant_prioritization.py`

Software versions are documented in:

`documents/variant_prioritization_versions.txt`

## Limitations
- Detailed phenotype-driven prioritization has not been completed.
- Missing gnomAD frequencies are not evidence of variant rarity.
- Compound heterozygous screening is preliminary.
- The full FASTQ-to-VCF workflow has not yet been automated
  into a portable workflow manager.
- Clinical pathogenicity has not been established.

## Project Status
Version 1.0: Completed variant discovery and prioritization analysis.
Further biological interpretation and workflow automation are planned.

## AI Assistance Disclosure

Anthropic's Claude (2026) was used to support documentation refinement,
technical troubleshooting, and clarification of bioinformatics workflow
concepts. AI-assisted suggestions were reviewed and tested by the project
author, who retains responsibility for the analysis, scientific
interpretation, and reported findings.

**Reference:** Anthropic. (2026). *Claude* [Large language model].
https://claude.ai/

## Data Availability and Attribution

The analysis uses publicly available trio whole-exome sequencing
data from NCBI SRA:

- Father: SRR27997290
- Mother: SRR27997291
- Proband: SRR27997292

The sequencing data remain available through NCBI SRA.

Variant-level result tables are not included in this public
repository pending review of applicable data-sharing conditions.
Aggregate analysis findings are summarized above.

## Original Publication

The sequencing data analyzed in this project were originally
published in:

*Clinical phenotype and trio whole exome sequencing data from
a patient with glycogen storage disease IV in Indonesia.*

Data in Brief.

DOI: https://doi.org/10.1016/j.dib.2024.111231

This project represents an independent computational reanalysis
of publicly available trio-WES data from the original study.

The original researchers are acknowledged as the source of the
sequencing data. The downstream analysis and variant prioritization
presented here were performed as part of this reanalysis.
