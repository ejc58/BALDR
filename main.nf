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
params.starpath = "/bi/home/carre/STAR_GRCh38/STAR_GRCh38_index/"

log.info """\
         Nextflow B C R   P I P E L I N E
         ================================
         species  : ${params.species}
         annot    : ${params.annot}
         reads    : ${params.reads}
         outdir   : ${params.outdir}
         STARpath : ${params.starpath}
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

 publishDir "$params.outdir/BALDR", mode: 'copy', overwrite: true
 
 input:
 set pair_id, file(reads) from read_pair_BALDR_ch

 output:
 file "**/*tabular.quant.sorted*"

 errorStrategy 'ignore'

 """
 TRINITY=`which Trinity`

 IG=`which igblastn`
 STARPROGPATH=`which STAR`
 ADAPT=`which trimmomatic | sed 's/bin\\/trimmomatic/share\\/trimmomatic-*\\/adapters\\/NexteraPE-PE.fa/g'`
 TRIM=`which trimmomatic | sed 's/bin\\/trimmomatic/share\\/trimmomatic-*\\/adapters\\/NexteraPE-PE.fa/g' | sed 's/adapters\\/NexteraPE-PE.fa/trimmomatic.jar/g'`
 
 
 $baseDir/BALDR --paired ${reads[0]},${reads[1]} \
 --trinity \$TRINITY \
 --adapter \$ADAPT \
 --trimmomatic \$TRIM \
 --igblastn \$IG \
 --db $baseDir/resources/IgBLAST_DB/human \
 --STAR \$STARPROGPATH \
 --STAR_index $params.starpath \
 --BALDR $baseDir \
 --memory ${task.memory.toGiga()}G \
 --threads ${task.cpus} \
 
 # Soft link the output files to the base directory of the working directory
 # These files are then 'seen' by publishDir
 #FILE=`ls IG-mapped_Unmapped/IgBLAST_quant_sorted*/*`
 #for f in \$FILE;do ln -s \$f; done
 """
}
