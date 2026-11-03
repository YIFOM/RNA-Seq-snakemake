
| Step | Tool | Output |
|---|---|---|
| Quality control & trimming | fastp | `results/clean/*.R1/R2.clean.fq.gz`, JSON/HTML reports |
| Alignment | HISAT2 | `results/mapping/*.sam` |
| Sorting & indexing | samtools | `results/mapping/*.bam`, `.bam.bai` |
| Transcript assembly & quantification | StringTie | `results/stringtie/*.gtf` |
| Count matrices | step4_prepDE.py3 | `results/gene_count_matrix.csv`, `transcript_count_matrix.csv` |
| TPM matrices | step5_getTPM.py | `results/gene_TPM_matrix.csv`, `transcript_TPM_matrix.csv` |

## Requirements

### Software

The following tools must be available in `PATH` (versions listed are those used during validation; other versions are usually compatible):

- fastp >= 0.23
- HISAT2 >= 2.2
- samtools >= 1.10
- StringTie >= 2.1
- Python 3 (to run `step4_prepDE.py3`)
- Python 2 (to run `step5_getTPM.py`, which still uses Python 2 syntax)
- Snakemake >= 9.0

### Installing Snakemake (optional)

If Snakemake is not yet installed, create an isolated environment with conda:

```bash
conda create -p /path/to/envs/snakemake -c conda-forge -c bioconda -c nodefaults snakemake
conda activate /path/to/envs/snakemake
#Repository Structure
.
├── Snakefile
├── config.1.yml
├── scripts/
│   ├── step4_prepDE.py3
│   └── step5_getTPM.py
├── data/                    # raw FASTQ files (symlinks or real files)
│   ├── {sample}.R1.raw.fastq.gz
│   └── {sample}.R2.raw.fastq.gz
├── reference/
│   ├── genome.fa            # reference genome
│   ├── annotation.gtf       # reference annotation
│   └── *.ht2                # HISAT2 index (or build with hisat2-build)
└── results/                 # all outputs (created automatically at runtime)


##Raw reads
data/{sample}.R1.raw.fastq.gz
data/{sample}.R2.raw.fastq.gz
#Outputs
File	Description
results/clean/*.html	fastp QC report (open in a browser)
results/mapping/*.bam	Aligned reads
results/stringtie/*.gtf	Per-sample StringTie assemblies
results/gene_count_matrix.csv	Gene-level count matrix
results/transcript_count_matrix.csv	Transcript-level count matrix
results/gene_TPM_matrix.csv	Gene-level TPM matrix
results/transcript_TPM_matrix.csv	Transcript-level TPM matrix
```
## Usage

**1. Dry run: check the execution plan without running anything**
```bash
snakemake -n --cores 1
```
2. Full run with 20 cores
```bash
snakemake --cores 20
```
3. Generating Workflow Diagrams
```bash
snakemake --dag | dot -Tpng > dag.png



