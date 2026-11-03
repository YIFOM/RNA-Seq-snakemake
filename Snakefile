

configfile: "config.1.yml"

SAMPLES = list(config["samples"].keys())
# ---------- 总目标 ----------
rule all:
    input:
        expand("results/stringtie/{sample}.gtf", sample=SAMPLES),
        "results/gene_TPM_matrix.csv",
        "results/transcript_TPM_matrix.csv"

# ---------- 1. 质控 ----------
rule fastp:
    input:
        r1="data/{sample}.R1.raw.fastq.gz",
        r2="data/{sample}.R2.raw.fastq.gz"
    output:
        r1="results/clean/{sample}.R1.clean.fq.gz",
        r2="results/clean/{sample}.R2.clean.fq.gz",
        json="results/clean/{sample}.json",
        html="results/clean/{sample}.html"
    threads: 4
    shell:
        "fastp -i {input.r1} -I {input.r2} "
        "-o {output.r1} -O {output.r2} "
        "-j {output.json} -h {output.html} -w {threads}"

# ---------- 2. 建索引（只需跑一次） ----------
#rule hisat2_build:
#    input:
#        "reference/genome.fa"
#    output:
#        expand("reference/index/genome.{n}.ht2", n=range(1, 9))
#    shell:
#        "mkdir -p reference/index && "
#        "hisat2-build {input} reference/index/genome"

# ---------- 3. 比对 ----------
rule hisat2:
    input:
        r1="results/clean/{sample}.R1.clean.fq.gz",
        r2="results/clean/{sample}.R2.clean.fq.gz",
        idx=expand("reference/S0.genome.new.{n}.ht2", n=range(1, 9))
    output:
        "results/mapping/{sample}.sam"
    threads: 20
    params:
        index="reference/S0.genome.new"
    shell:
        "hisat2 -p {threads} --dta -x {params.index} "
        "-1 {input.r1} -2 {input.r2} -S {output}"

# ---------- 4. 排序 + 索引 ----------
rule samtools_sort:
    input:
        "results/mapping/{sample}.sam"
    output:
        bam="results/mapping/{sample}.bam",
        bai="results/mapping/{sample}.bam.bai"
    threads: 4
    shell:
        "samtools sort -@ {threads} -o {output.bam} {input} && "
        "samtools index {output.bam}"

# ---------- 5. StringTie 组装 ----------
rule stringtie:
    input:
        bam="results/mapping/{sample}.bam",
        gtf="reference/S0.genome.new.gtf"
    output:
        "results/stringtie/{sample}.gtf"
    threads: 3
    shell:
        "stringtie -p {threads} -e -G {input.gtf} "
        "-o {output} {input.bam}"

# ---------- 6. 汇总 count / TPM ----------
rule prepDE_input:
    input:
        gtfs=expand("results/stringtie/{sample}.gtf", sample=SAMPLES)
    output:
        "results/prepDE_input.txt"
    run:
        with open(output[0], "w") as f:
            for s in SAMPLES:
                f.write(f"{s}\tresults/stringtie/{s}.gtf\n")

rule prepDE:
    input:
        sample_list="results/prepDE_input.txt"
    output:
        gene_count="results/gene_count_matrix.csv",
        transcript_count="results/transcript_count_matrix.csv"
    shell:
        "python3 scripts/step4_prepDE.py3 -i {input.sample_list} "
        "-g {output.gene_count} -t {output.transcript_count}"

rule getTPM:
    input:
        sample_list="results/prepDE_input.txt",
        gene_count="results/gene_count_matrix.csv",
        transcript_count="results/transcript_count_matrix.csv"
    output:
        "results/gene_TPM_matrix.csv",
        "results/transcript_TPM_matrix.csv"
    shell:
        "python2 scripts/step5_getTPM.py -i {input.sample_list} "
        "-g {output[0]} -t {output[1]}"
