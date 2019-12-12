#!/usr/bin/env nextflow

/*
 *
 * Execute this script locally (eg on head node for debugging):
 * nextflow run ejc58/BALDR -profile standard
 *
 * Send to cluster:
 * nextflow run ejc58/BALDR -profile cluster
 *
 * 
 *
 */

/*
 * Define the input parameters
 *
 */

params.reads = "/bi/sequencing/Sample_49*_ALFNA_*/Lane*/Unaligned/*_545R_d0*{R1,R4}.fastq.gz"
params.outdir = "nf_bcr_output"
params.species = "human"
params.chains = "IGH,IGK,IGL"

log.info """\
         Nextflow B C R   P I P E L I N E
         ================================
         species: ${params.species}
         annot : ${params.annot}
         reads : ${params.reads}
         outdir: ${params.outdir}
         """
         .stripIndent()



/*
 * Creates the `read_pairs` channel that emits for each read-pair a tuple containing
 * three elements: the pair ID, the first read-pair file and the second read-pair file
 */


Channel
    .fromFilePairs( params.reads )
    .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}" }
    .into { read_pair_BASIC_ch; read_pair_VDJPuzzle_ch; read_pair_BRACER_ch; read_pair_BALDR_ch }
                                                   
process assembleBALDR{
 
 conda 'trimmomatic=0.32 trinity=2.3.2 bowtie2=2.3.0 STAR=2.5.2b IgBLAST=1.7.0 seqtk=1.2' 

 publishDir "$params.outdir/BALDR", mode: 'copy', overwrite: false, pattern: "IgBLAST_quant_sorted*"

 input:
 set pair_id, file(reads) from read_pair_BALDR_ch

 output:
 file "*" into baldr_assembled_ch

 errorStrategy 'ignore'

 """
 TRINITY=`which Trinity`

 IG=`which igblastn`
 STARPATH=`which STAR`
 ADAPT=`which trimmomatic | sed 's/bin\\/trimmomatic/share\\/trimmomatic-*\\/adapters\\/NexteraPE-PE.fa/g'`
 TRIM=`which trimmomatic | sed 's/bin\\/trimmomatic/share\\/trimmomatic-*\\/adapters\\/NexteraPE-PE.fa/g' | sed 's/adapters\\/NexteraPE-PE.fa/trimmomatic.jar/g'`
 
 
 $baseDir/BALDR --paired ${reads[0]},${reads[1]} \
 --trinity \$TRINITY \
 --adapter \$ADAPT \
 --trimmomatic \$TRIM \
 --igblastn \$IG \
 --db $baseDir/resources/IgBLAST_DB/human \
 --STAR \$STARPATH \
 --STAR_index /bi/scratch/Genomes/Human/GRCh37_Gencode_for_STAR/STAR_2.5.1b_genome_50bp \
 --BALDR $baseDir \
 --memory 64G \
 --threads 8 \
 """
}
