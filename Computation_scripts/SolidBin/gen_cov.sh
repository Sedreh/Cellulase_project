
# An example to generate coverage for hybrid dataset

# input_dir: the directory containts all data we need
# assembly: fasta file consisting of contigs
# mapdir: a temp directory to save sam/bam files
# short_read_dir: contains short read samples if any
# pb_read_dir: contains pacbio read samples if any
# ont_read_dir: contins Oxford Nanopore read samples if any
# scripts_code_dir: a directory to save scripts for generating input files

# for non-docker env, please install samtools,minimap,bedtools and add them into path
ncpu=20
scripts_code_dir="/home/ilia/projects/arriam/cellulase/nanopore/solidbin/scripts"

input_dir="/home/ilia/projects/arriam/cellulase/nanopore/solidbin/input"
assembly="${input_dir}/assembly_filt.fasta"
mapdir="${input_dir}/map"
# short_read_dir=""
ont_read_dir="${input_dir}/ont"

if [ ! -d $mapdir ]; then
mkdir $mapdir
fi

samtools faidx $assembly;
awk -v OFS='\t' {'print $1,$2'} ${assembly}.fai > ${input_dir}/length.txt;

cnt=0;

# for file in ${short_read_dir}/*; do
#    echo $file
#    let cnt=cnt+1
#    echo $cnt
#    minimap2 -t ${ncpu} -ax sr $assembly $file > "${mapdir}/sr_${cnt}.sam"
# done

# for file in ${pb_read_dir}/*; do
#     echo $file
#     let cnt=cnt+1;
#     echo $cnt
#     minimap2 -t 45 -ax map-pb $assembly $file > "${mapdir}/pb_${cnt}.sam";
# done

for file in ${ont_read_dir}/*; do
    echo $file
    let cnt=cnt+1;
    echo $cnt
    minimap2 -t ${ncpu} -ax map-ont $assembly $file > "${mapdir}/ont_${cnt}.sam";
done

for file in ${mapdir}/*.sam; do
    stub=${file%.sam}
    echo $stub
    samtools view -h -b -S $file > ${stub}.bam
    samtools view -b -F 4 ${stub}.bam > ${stub}.mapped.bam
    samtools sort -m 1000000000 ${stub}.mapped.bam -o ${stub}.mapped.sorted.bam
    bedtools genomecov -ibam ${stub}.mapped.sorted.bam -g ${input_dir}/length.txt > ${stub}_cov.txt 
done

for i in ${mapdir}/*_cov.txt; do
   echo $i
   stub=${i%_cov.txt}
   echo $stub
   awk -F"\t" '{l[$1]=l[$1]+($2 *$3);r[$1]=$4} END {for (i in l){print i","(l[i]/r[i])}}' $i > ${stub}_cov.csv
done


${scripts_code_dir}/Collate.pl $mapdir > ${input_dir}/coverage.tsv

perl -pe "s/,/\t/g;" ${input_dir}/coverage.tsv > ${input_dir}/coverage_new.tsv

