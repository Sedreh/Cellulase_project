#Rename sequences that are duplicated

input="/home/is6/ASVs_comparison/16s_database/16s_database.fasta"
dedup_output="/home/is6/ASVs_comparison/16s_database/16s_database_nodup.fasta"

perl -ne 'if (/^>/){@a=split /_/; $h{$a[0]}++; $a[0].= ".".$h{$a[0]}; $s=join "_", @a; print $s;}else{print $_;}' $input > $dedup_output


#Building database of extracted 16s sequences from each genera for blast

output="/home/is6/ASVs_comparison/16s_database/Bacteria_database"
makeblastdb -in $dedup_output -out $output -dbtype nucl -title "database" -parse_seqids


#Blast 

Query_input="/home/is6/ASVs_comparison/sequences.fna"
Blast_results="/home/is6/ASVs_comparison/Blast_results"
mkdir $Blast_results

blastn -db $output -query $Query_input -evalue 1e-18 -out $Blast_results/alignments.outfmt6 -outfmt 6