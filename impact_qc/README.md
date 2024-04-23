# ![IMPaCT program](png/impact_data_logo_pink_horitzontal.png)

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

**Link to the supporting documentation associated to the QC metrics added in this workflow:**

[Metrics supporting documentation](https://docs.google.com/document/d/12OWCcNKatkdJelYyiovyil-bIXDESO_K2zeIB3vncW4/edit#heading=h.cvdlfn10wodq)

## Configuration

As you can see in the supporting documentation, there are so many different metrics and these metrics are mesured using different tools. In this section there is an explanation on how to configure some things in order to make the pipeline work smothly.

### Somalier

The IMPaCT-QC workflow already has the sites file required for the different reference genome from the Sarek workflow, but, if you want to use a different or custom reference genome you will need to provide the necessary sites file for it in the paramater (`--somalier-sites`). You can take a look at the official `somalier` websites ([GitHub](https://github.com/brentp/somalier)) to know which sites to use. Take into account that in the folder `impact_qc/assets/sites/` you already have the sites from `somalier`downloaded.

### FastQ Screen

The program `fastq_screen` needs the index files of the desired reference genomes to work with. The user needs to build an index using `bowtie` or `bowtie2`.

- [Bowtie](https://bowtie-bio.sourceforge.net/manual.shtml)
- [Bowtie2](https://bowtie-bio.sourceforge.net/bowtie2/manual.shtml)

Both tools has their own version of building the index and you can build a new one or use the indexes that they provide and that are already build. You can find those indexes in the right site of the manuals provided.

To use the indexes in the IMPaCT-QC workflow you need to put the indexes in a folder an put the folder inside `impact_qc/assets/fastq_screen_conf_db/.`. Then you should modify the `fastq_screen`config named `impact_qc/assets/fastq_screen_conf_db/fastq_screen.conf`. In this config file you need to 'uncommnent' (remove the `#`) of the databases you want to use, put the folder name in the second field of the database, or change the folder name to the one in the config file database, and also put the 'prefix' of you indexes filename in the third field of the database line, always starting with `/`.

**Example:** If you want to use the Human database with indexes named as `Homo_sapiens.GRCh38*bt`, you could put them in a folder named Human (as the second field in the human database in the `fastq_screen` config file), then put this folder in the `fastq_screen_conf_db/.` and then modify the `fastq_screen.conf` file removing the `#` at the start of the human database (`#DATABASE... --> DATABASE...`) and at the end put the name of your indexes with a final result similar to `DATABASE        Human   /Homo_sapiens.GRCh38`.

*Note that you can also select which mapper use (`bowtie` or `bowtie2`), 'uncommenting' it,  and also you can put the desired number of threads.*

### Picard

For `CollectHsMetrics` and `CollectTargetedPcrMetrics` you need to provide the necessary intervals files for each tool in the respective parameters; target intervals file (`--target-intervals`), bait intervals file (`--bait-intervals`) and amplicon intervals file (`--amplicon-intervals`).

### MultiQC

Different metrics in the IMPaCT QC final MultiQC report are reported using a custom content configuration. For the the metrics 'Allelic read percentages' (the distribution of the Alternate allele percetages) and 'GQ distribution' (the distribution of the GQ) are both configured to not be reported in the final report since the only way to do it was to plot with one plot per sample. You can activate the plotting in the final report adding `plotallelicreadpct` and `plotgq`, respectively, in the `tools` parameter. These will create a plot per sample per metric in the final report. We recomend setting this when you have a limited number of samples, for visualizing issues.

Note: This is because each sample would have a different number of variants and plotting different samples in the same plot with different number of axis values, is not posible.

## Usage

To execute the pipeline you need to follow the instructions of the actual `Sarek` workflow (or all the `Nextflow` pipelines) and only add to the main command the configuration file of IMPaCT-QC workflow named `impact_qc.config` that is in the `impact_qc/conf` folder, using the `-c` option flag (`-c impact_qc/conf/impact_qc.config`).

**Example command using Docker profile:** 

`$ nextflow run main.nf -profile docker -params-file ./params.yaml -c ./impact_qc/conf/impact_qc.config`

*Note that for this command you need to be in the 'Sarek' folder.*

## List of modules

Take into account that all the modules in the IMPaCT QC workflow can be disabled by adding the name of the module in the `--skip_tools` parameter. Note that adding `impactqc` will skip the full IMPaCT QC workflow (skips all modules).

- collectinsertsizemetrics
- collecthsmetrics
- collecttargetedpcrmetrics
- fastqscreen
- flagstat
- imapctqc
- sexdeterrmine
- somalier

