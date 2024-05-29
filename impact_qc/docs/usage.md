# IMPaCT QC: Usage

## Introduction

IMPaCT QC is a quality control subworkflow implemented for the Sarek workflow designed specifically for germline on whole exome, or targeted sequencing data.

To know more about the Sarek workflow usage: [README.md](https://github.com/nf-core/sarek/tree/master/docs#nf-coresarek-documentation)

## Usage

To execute the IMPaCT QC subworkflow you need to follow the instructions of the actual `Sarek` workflow (or all the `Nextflow` pipelines) and only add to the main command the configuration file of IMPaCT-QC workflow named `impact_qc.config` that is in the `impact_qc/conf` folder, using the `-c` option flag (`-c impact_qc/conf/impact_qc.config`).

**Example command using Docker profile:** 

`$ nextflow run main.nf -profile docker -params-file ./params.yaml -c ./impact_qc/conf/impact_qc.config`

*Note that for this command you need to be in the 'Sarek' folder.*

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

**Example:** If you want to use the Human database with indexes named as `Homo_sapiens.GRCh38*bt`, you could put them in a folder named Human (as the second field in the human database in the `fastq_screen` config file), then put this folder in the `fastq_screen_conf_db/.` and then modify the `fastq_screen.conf` file removing the `#` at the start of the human database (`#DATABASE... --> DATABASE...`) and at the end put the name of your indexes with a final result similar to `DATABASE        Human   Homo_sapiens.GRCh38`.

*Note that you can also select which mapper use (`bowtie` or `bowtie2`), 'uncommenting' it,  and also you can put the desired number of threads.*

### Picard

For `CollectHsMetrics` you need to provide the necessary intervals files for the tool in the respective parameters; target intervals file (`--target-intervals`) and bait intervals file (`--bait-intervals`).

### MultiQC

Different metrics in the IMPaCT QC final MultiQC report are reported using a custom content configuration. For the the metrics 'Allelic read percentages' (the distribution of the Alternate allele percetages), 'DP distribution', 'GQ distribution' (the distribution of the GQ) and 'strand bias (SB) distribution are all configured to not be reported in the final report since the only way to do it is having one plot per sample and per variant caller executed. You can activate the plotting in the final report adding `plotallelicreadpct`, `plotdp`, `plotgq` and `plotsb`, respectively, in the `tools` parameter. These will create a plot per sample per metric per variant caller executed in the final report. We recomend setting this when you have a limited number of samples, for visualizing issues.

*Note: This is because each sample would have a different number of variants and plotting different samples in the same plot with different number of axis values, hence this is not posible.*

Bear in mind that each variant caller has a different type of strand bias format: `bcftools mpileup` outputs `SP`, `freebayes` outputs `SAP`, `SRP` and `EPP`, `haplotypecaller` outputs `FS` and `strelka2` outputs `SB`. `DeepVariant` does not output the strand bias information. Take a look at the different tools documentation to know more about it. 
