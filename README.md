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

## Repository Structure

- `scripts/cluster_slurm/` — Sample-specific BWA-MEM alignment and GATK duplicate-marking scripts adapted from the original HPC analysis.
- `scripts/workflow/` — Scripts for coverage assessment, BQSR, variant calling, joint genotyping, VCF processing, quality filtering, VEP annotation, and downstream analyses.
- `scripts/variant_prioritization.py` — Inheritance-aware variant prioritization.
- `documents/variant_prioritization_versions.txt` — Recorded software versions for the prioritization analysis.

## Reproducibility

The analysis was performed on a SLURM-managed HPC cluster using GRCh38.p14.


### Containerization and Software Environments

GATK 4.6.2.0 and Ensembl VEP 115.2 were executed using **Docker-derived Apptainer containers** on the SLURM-managed HPC cluster, providing version-specific software environments. BWA-MEM, samtools, and bcftools were accessed through HPC environment modules.

Container image sources, reconstruction commands, software versions, and reproducibility considerations are documented in [`containers/README.md`](containers/README.md).

The workflow uses a hybrid container/module environment and is not fully containerized.

The principal variant-processing sequence is:

1. BWA-MEM alignment and duplicate marking
2. Base quality score recalibration (BQSR)
3. GATK HaplotypeCaller in gVCF mode
4. Trio joint genotyping
5. VCF normalization using bcftools
6. GATK hard filtering using VariantFiltration
7. Extraction of PASS variants
8. Chromosome-name conversion and offline Ensembl VEP annotation
9. Population-frequency annotation and inheritance-aware prioritization

The repository contains individual analysis scripts rather than a fully automated end-to-end workflow. Some scripts support project-directory configuration through the `WES_PROJECT_DIR` environment variable; the default points to the original HPC scratch-directory layout.

The scripts depend on the relevant reference files, sequencing data, annotation resources, software modules, and Apptainer images. Large input datasets, reference resources, and container images are not distributed in this repository.

The recovered shell scripts have been checked for Bash syntax, but the adapted workflow has not been rerun end to end. The variant-prioritization script was separately tested against the original annotated VCF.

`11b_extract_pass_variants.sh` reconstructs a previously undocumented PASS-extraction step. Its expected output was verified against the original analysis: all 68,523 PASS variant records matched exactly.

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

Harsono, I. W., Ariani, Y., Benyamin, B., Fadilah, F., Pujianto, D. A., Hafifah, C. N., & Prawitasari, T. (2024). Clinical phenotype and trio whole exome sequencing data from a patient with glycogen storage disease IV in Indonesia. Data in brief, 58, 111231. DOI: https://doi.org/10.1016/j.dib.2024.111231 

This project represents an independent computational reanalysis
of publicly available trio-WES data from the original study.

The original researchers are acknowledged as the source of the
sequencing data. The downstream analysis and variant prioritization
presented here were performed as part of this reanalysis.
