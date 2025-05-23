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

### Clone the Repository

```bash
git clone https://github.com/<your-username>/rna-seq-pipeline.git
cd rna-seq-pipeline
```

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
ILLUMINACLIP:TruSeq3-PE.fa:2:30:10:2:keepBothReads
```

Explanation of parameters:
- `2`: Maximum mismatches allowed in the seed
- `30`: Palindrome mode clip threshold (for adapter dimer detection)
- `10`: Simple clip threshold (for standard adapter matches)
- `2`: Minimum adapter length to keep
- `keepBothReads`: Retains both reads even if only one is trimmed

These values were chosen to balance strict adapter removal with retention of high-quality paired reads for downstream alignment.

If your data used Nextera or NEB adapters, replace `TruSeq3-PE.fa` with the appropriate adapter file.

## Troubleshooting

- Ensure adapter file is present or provide full path in the script
- Modify `gunzip` usage if disk space is limited
