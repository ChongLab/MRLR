# MRLR (Meiotic Recombination identification by Linked-Read sequencing)

A pipeline to identify meiotic recombination events using trio samples of 10x genomics longranger vcf outputs

Author: Peng Xu

Email: pxu@uabmc.edu

Draft date: April. 30, 2018

## Description

This is a pipeline to identify meiotic recombination events that occur during gamete formation and trasmit into next generation. The input should be trio samples with vcf files generated by 10x genomics longranger software. It can also be used to achieve whole chromosomal phasing of the child genome based on pedigree haplotype comparison.

## System requirements and dependency

The program was tested on a x86_64 Linux system with a 8GB physical memory. The work can be usually finished within half an hour. Bedtools (https://github.com/arq5x/bedtools2) is required for the program.

## Installation

```
git clone https://github.com/penguab/MRLR.git
```
Then, please also add this directory to your PATH:
```
export PATH=$PWD/MRLR/:$PATH
```

## Usage

Three vcf files from trio samples of 10x genomics longranger vcf outputs are required for analysis. A new direcoty will be generated to hold the output files.
```
MRLR.sh -f <Father_vcf> -m <Mother_vcf> -c <Child_vcf> [-oablps]
  -f   father vcf file from longranger output
  -m   mother vcf file from longranger output
  -c   child vcf file from longranger output
------------optional--------
  -o   output file profix; default='trio'
  -a   min arm length (kb); default=20
  -b   min supporting barcode; default=4
  -l   min block length (kb); default=500
  -p   max breakpoint region length(kb); default=100
  -s   min SNV number; default=20
```

To test the pipeline.
```
gzip -d *.gz
```
```
MRLR.sh -f NA12891_chr20.vcf -m NA12892_chr20.vcf -c NA12878_chr20.vcf -o NA12878_chr20
```

## News
11/28/2018: update test files for the pipeline

