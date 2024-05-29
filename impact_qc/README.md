# ![IMPaCT program](docs/png/impact_data_logo_pink_horitzontal.png)

[![IMPaCT](https://img.shields.io/badge/Web%20-IMPaCT-blue)](https://impact.isciii.es/)
[![IMPaCT-isciii](https://img.shields.io/badge/Web%20-IMPaCT--isciii-red)](https://www.isciii.es/QueHacemos/Financiacion/IMPaCT/Paginas/default.aspx)
[![IMPaCT-Data](https://img.shields.io/badge/Web%20-IMPaCT--Data-1d355c.svg?labelColor=000000)](https://impact-data.bsc.es/)

## Introduction of the project

IMPaCT-Data is the IMPaCT program that aims to support the development of a common, interoperable and integrated system for the collection and analysis of clinical and molecular data by providing the knowledge and resources available in the Spanish Science and Technology System. This development will make it possible to answer research questions based on the different clinical and molecular information systems available. Fundamentally, it aims to provide researchers with a population perspective based on individual data.

The IMPaCT-Data project is divided into different work packages (WP). In the context of IMPaCT-Data WP3 (Genomics), a working group of experts worked on the generation of a specific quality control (QC) workflow for germline exome samples.

To achieve this, a set of metrics related to human genomic data was decided upon, and the toolset or software to extract these metrics was implemented in an existing variant calling workflow called Sarek, part of the nf-core community. The final outcome is a Nextflow subworkflow, called IMPaCT-QC implemented in the Sarek pipeline.

## Introduction of the subworkflow (IMPaCT-QC)

In the context of IMPaCT-Data WP3 (Genomics), a working group of experts worked towards the generation of a quality control (QC) workflow specific for germline exome samples. The final product consists of a modified version of the well-known Nextflow workflow [**Sarek**](https://github.com/nf-core/sarek/blob/3.4.0/README.md). This pipeline has been modified adding new QC metrics and tools to obtain a broader sight of the quality details of the data and the pipeline. All the new implemented features were selected by this group of experts within the IMPaCT-Data.

The goal of the IMPaCT-Data WP3 (Genomics), was to modify the Sarek workflow in order to implement new metrics and obtain a pipeline able to detect variants and also with a really good and deep QC. 

To achieve this, a set of metrics related to human genomic data was decided upon, and the toolset or software to extract these metrics was implemented in an existing variant calling workflow called Sarek, part of the nf-core community.

**nf-core/sarek** is a workflow designed to detect variants on whole genome or targeted sequencing data. Initially designed for Human, and Mouse, it can work on any species with a reference genome. Sarek can also handle tumour/normal pairs and could include additional relapses.

Aligned with the FAIR principles, the pipeline is built using *Nextflow*, a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The Nextflow DSL2 implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. 

For all these reasons, IMPaCT-Data decided to use this existing workflow and implement the new QC pipeline in it. Merging all the excellent characteristics from both parts to create a product able to help all scientists.

## Usage

Follow these instructions from Sarek, [usage](https://github.com/nf-core/sarek/tree/master#usage) and [usage.md](https://github.com/solcos/sarek/tree/master/docs/usage.md), and from IMPaCT QC subworkflow, follow [usage.md](https://github.com/solcos/sarek/blob/master/impact_qc/docs/usage.md).

## Pipeline output

For more details about the output files and reports, please refer to the [output](https://github.com/solcos/sarek/tree/master/docs/output.md) folder. To see the results of an example test run with a test dataset refer to the [results](https://github.com/solcos/sarek/tree/master/results) folder.

## Test

To perform a test with a test dataset see the [tests](https://github.com/solcos/sarek/tree/master/tests) folder.

## Metrics

### List of modules

Take into account that all the modules in the IMPaCT QC workflow can be disabled by adding the name of the module in the `--skip_tools` parameter. Note that adding `impactqc` will skip the full IMPaCT QC workflow (skips all modules).

- collectinsertsizemetrics
- collecthsmetrics
- fastqscreen
- flagstat
- imapctqc
- sexdeterrmine
- somalier

**Link to the supporting documentation associated to the QC metrics added in this workflow:**

[Metrics supporting documentation](https://docs.google.com/document/d/12OWCcNKatkdJelYyiovyil-bIXDESO_K2zeIB3vncW4/edit#heading=h.cvdlfn10wodq)
