# MRLR (Meiotic Recombination identification by Linked-Read sequencing)

A pipeline to identify meiotic recombination events using trio samples of 10x genomics longranger vcf outputs

Author: Peng Xu

Email: pxu@uabmc.edu

Draft date: April. 30, 2018

## Description

This is a pipeline to identify meiotic recombination events that occur during gamete formation and trasmit into next generation. The input should be trio samples with vcf files generated by 10x genomics longranger software. It can also be used to achieve whole chromosomal phasing of the child genome based on pedigree haplotype comparison.

## System requirements and dependency

The program was tested on a x86_64 Linux system with a 8GB physical memory. The work can be usually finished within half an hour. Bedtools is required for the program. It is included in this repository.

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
MRLR.sh <Father_vcf> <Mother_vcf> <Child_vcf> <output_profix>
```

## News


