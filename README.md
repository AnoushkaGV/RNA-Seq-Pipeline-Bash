# RNA-Seq Bash Pipeline

This repository contains a user-interactive Bash script to perform a complete RNA-Seq data processing workflow from raw FASTQ files to gene-level count matrices. It supports paired-end sequencing reads and is designed for Linux environments.

## Pipeline Overview

The pipeline performs the following steps:

1. Project setup with structured directories  
2. Copying raw FASTQ files from an external drive  
3. Quality control using FastQC  
4. Read trimming using Trimmomatic  
5. Quality control after trimming  
6. Alignment to a reference genome using STAR  
7. Quantification using featureCounts

## Requirements

The following tools must be installed before running the script:

- FastQC: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
- Trimmomatic: http://www.usadellab.org/cms/?page=trimmomatic
- STAR aligner: https://github.com/alexdobin/STAR
- featureCounts (part of Subread): http://bioinf.wehi.edu.au/featureCounts/

Also required:
- `java` for Trimmomatic
- STAR genome index
- GTF annotation file (e.g., Homo_sapiens.GRCh38.95.gtf)

## Input Files

- Paired-end FASTQ files named:
  ```
  sample_R1_001.fastq.gz
  sample_R2_001.fastq.gz
  ```

- Adapter file for Trimmomatic:
  ```
  TruSeq3-PE.fa
  ```
  Usually located in Trimmomatic’s `adapters/` directory.  
  If missing, download from:
  https://github.com/usadellab/Trimmomatic/blob/main/adapters/TruSeq3-PE.fa
  
## Directory Structure Created

```
<project_name>/
├── raw/
└── output/
    ├── qc/
    ├── qc_trim/
    ├── trimmed/
    ├── align/
    └── counts/
```

## Setup

### Configure Paths in `pipeline.sh`

Open `pipeline.sh` and set the following variables:

```bash
PROJECTS_DIR="/absolute/path/to/projects"
EXTERNAL_DRIVE="/media/your_external_drive"
FASTQC_DIR="/absolute/path/to/FastQC"
TRIM_DIR="/absolute/path/to/Trim"
STAR_DIR="/absolute/path/to/STAR/bin"
GENOME_INDEX="/absolute/path/to/STAR/index"
GTF_FILE="/absolute/path/to/annotation.gtf"
```

## Running the Pipeline

Make the script executable:

```bash
chmod +x pipeline.sh
```

Run the script:

```bash
./pipeline.sh
```

Follow prompts for:
- Project name
- FASTQ folder
- Trimming thresholds
- Whether to run FastQC, alignment, and feature counting

## Output Files

For each sample (e.g., SRR123456), the script produces:

```
output/qc/SRR123456_R1_001_fastqc.html
output/qc_trim/SRR123456_R1_paired_fastqc.html
output/trimmed/SRR123456/oSRR123456_R1_paired.fastq.gz
output/align/SRR123456/SRR123456Aligned.sortedByCoord.out.bam
output/counts/SRR123456.txt
```

## Trimming Parameters Used

This pipeline uses the following Trimmomatic setting, optimized for Illumina TruSeq adapters:

```bash
ILLUMINACLIP:TruSeq3-PE.fa:2:30:10:keepBothReads
```

Adapter trimming setting for paired-end Illumina reads using Trimmomatic, allowing 2 seed mismatches, with clip thresholds of 30 (palindrome) and 10 (simple clip) and retaining both reads.

## Troubleshooting

- Ensure adapter file is present or provide full path in the script
- Modify `gunzip` usage if disk space is limited
