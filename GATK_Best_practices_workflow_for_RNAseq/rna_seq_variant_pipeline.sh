#!/bin/bash
#
# AUTHOR: Anand M.
# RNA-Seq variant calling pieline accoring to GATK Best practices.
# https://www.broadinstitute.org/gatk/guide/article?id=3891
#
# Call with following arguments
# bash rna_seq_variant_pipeline.sh <Input_Reads1.fq.gz> <Input_Reads2.fq.gz> <output_basename>
# 
# Assumes STAR aligner is under path
#
# GATK bundle set : one can obtain these from gatk ftp (knonw as gatk bundle)
# ftp://ftp.broadinstitute.org/bundle/2.8/hg19/
#

fwd=$1
rev=$2
bn=$3

#Path to reference genome and Index files.
star_ref="/home/csipk/NGS/ref_genomes/star_ref_index"
ref="/home/csipk/NGS/ref_genomes/hg19.fa"
#Path to gatk and picard tools
gatk="/home/csipk/NGS/GenomeAnalysisTK.jar"
picard="/home/csipk/NGS/picard-tools-1.133/picard.jar"
#Path to gatk bundle set files
millsIndels="/home/csipk/NGS/ref_genomes/Mills_and_1000G_gold_standard.indels.hg19.vcf"
KGIndels="/home/csipk/NGS/ref_genomes/1000G_phase1.indels.hg19.vcf"
dbSNP138="/home/csipk/NGS/ref_genomes/dbSNP_138.vcf"

#Create an output directory
opdir=$bn"_processed"
mkdir $opdir

#STAR 2 pass basic mode run
echo -e "["$(date)"]\tAligning.."
STAR --outFileNamePrefix $opdir/$bn --outSAMtype BAM Unsorted --outSAMstrandField intronMotif --outSAMattrRGline ID:$bn CN:CSI_HPK_lab LB:PairedEnd PL:Illumina PU:Unknown SM:$bn --genomeDir $star_ref --runThreadN 50 --readFilesCommand zcat --readFilesIn $fwd $rev --twopassMode Basic

#sambamba sort
echo -e "["$(date)"]\tSorting.."
sambamba sort -o $opdir/$bn"_sorted.bam" -p -t 50 $opdir/$bn"Aligned.out.bam"

rm $opdir/$bn"Aligned.out.bam"

#sambamba index
echo -e "["$(date)"]\tIndexing.."
sambamba index -p -t 50 $opdir/$bn"_sorted.bam"

#picard mark duplicates
echo -e "["$(date)"]\tMarking duplicates.."
java -jar $picard MarkDuplicates I=$opdir/$bn"_sorted.bam" O=$opdir/$bn"_dupMarked.bam" M=$opdir/$bn"_dup.metrics" CREATE_INDEX=true VALIDATION_STRINGENCY=SILENT 2>$opdir/$bn.MarkDuplicates.log

rm $opdir/$bn"_sorted.bam"
rm $opdir/$bn"_sorted.bam.bai"

#SplitNCigarReads
echo -e "["$(date)"]\tSpliting reads.."
java -d64 -jar $gatk -T SplitNCigarReads -R $ref -I $opdir/$bn"_dupMarked.bam" -o $opdir/$bn"_split.bam" -rf ReassignOneMappingQuality -RMQF 255 -RMQT 60 -U ALLOW_N_CIGAR_READS 2>$opdir/$bn.SplitNCigarReads.log

rm $opdir/$bn"_dupMarked.bam"
rm $opdir/$bn"_dupMarked.bai"

#Create targets for indel realignment
echo -e "["$(date)"]\tCreating targets for indel realignment.."
java -d64 -jar $gatk -T RealignerTargetCreator -R $ref -I $opdir/$bn"_split.bam" -o $opdir/$bn".intervals" -nt 50 -known $millsIndels -known $KGIndels 2>$opdir/$bn.indel.log

#Perform indel realignment
echo -e "["$(date)"]\tPerforming Indel Realignment.."
java -d64 -jar $gatk -T IndelRealigner -R $ref -I $opdir/$bn"_split.bam" -targetIntervals $opdir/$bn".intervals" -known $millsIndels -known $KGIndels -o $opdir/$bn"_processed.bam" 2>$opdir/$bn.indel2.log 

rm $opdir/$bn"_split.bam"
rm $opdir/$bn"_split.bai"

#Perform BQSR
echo -e "["$(date)"]\tPerforming BQSR.."
java -d64 -jar $gatk -T BaseRecalibrator -I $opdir/$bn"_processed.bam" -R $ref -knownSites $KGIndels -knownSites $millsIndels -knownSites $dbSNP138 -o $opdir/$bn"_recal.table" 2>$opdir/$bn.BQSR.log

#Print recalibrated reads
echo -e "["$(date)"]\tPrinting recalibrated reads.."
java -d64 -jar $gatk -T PrintReads -R $ref -I $opdir/$bn"_processed.bam" -nct 50 -BQSR $opdir/$bn"_recal.table" -o $opdir/$bn"_recal.bam" 2>$opdir/$bn.BQSR2.log

rm $opdir/$bn"_processed.bam"
rm $opdir/$bn"_processed.bai"

#Run HaplotypeCaller
echo -e "["$(date)"]\tRunning HaplotypeCaller.."
java -d64 -jar $gatk -T HaplotypeCaller -R $ref -I $opdir/$bn"_recal.bam" -dontUseSoftClippedBases -stand_call_conf 20.0 -stand_emit_conf 20.0 -o $opdir/$bn".vcf" 2>$opdir/$bn.HaplotypeCaller.log

#Filter variants
echo -e "["$(date)"]\tFiltering Variants.."
java -d64 -jar $gatk -T VariantFiltration -R $ref -V $opdir/$bn".vcf" -window 35 -cluster 3 -filterName FS -filter "FS > 30.0" -filterName QD -filter "QD < 2.0" -o $opdir/$bn"_filtered.vcf" 2>$opdir/$bn.VariantFilter.log

echo -e "["$(date)"]\tDONE!"