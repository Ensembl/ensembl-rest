ALIAS='my_sql_server'

rm -r core
mkdir -p core; ls -1 --color=no ~/proteome/ensembl-rest/t/test-genome-DBs/homo_sapiens/core | cut -f 1 -d '.'  | grep -v table | xargs -I XXX -n 1 -- echo '${ALIAS} -D anopheles_atroparvus_core_1810_93_3 -BN -e '"'"'select * from XXX;'"'"'| perl -pe '"'"'s/NULL/\\N/g'"'"' > core/XXX.txt' | bash


${ALIAS} mysqldump -d --compact anopheles_atroparvus_core_1810_93_3 > core/table.sql

echo xref.txt associated_xref.txt dependent_xref.txt identity_xref.txt object_xref.txt ontology_xref.txt unmapped_reason.txt protein_feature.txt density_feature.txt density_type.txt dependent_xref.txt interpro.txt repeat_consensus.txt repeat_feature.txt | perl -pe 's/ /\n/g'| xargs -n 1 -I XXX -- sh -c 'echo -n > core/XXX'


grep -Fw -e AXCP01009878 -e AXCP01009863 core/seq_region.txt > core/tmp; mv core/tmp core/seq_region.txt
grep -Fw -e AXCP01009878 -e AXCP01009863 core/seq_region_synonym.txt > core/tmp; mv core/tmp core/seq_region_synonym.txt
grep -Fw -e 8978 -e 10473 -e 13941 -e 8947 -e 10199 -e 13380 core/seq_region_attrib.txt > tmp; mv tmp core/seq_region_attrib.txt

grep -Fw -e 8978 -e 10473 -e 13941 -e 8947 -e 10199 -e 13380 core/assembly.txt > tmp; mv tmp core/assembly.txt
grep -Fw -e 8978 -e 8947 core/dna.txt > core/tmp; mv core/tmp core/dna.txt
grep -Fw -e 8978 -e 10473 -e 13941 -e 8947 -e 10199 -e 13380 core/gene.txt | awk '$4==10473 || $4==10199' > core/tmp; mv core/tmp core/gene.txt


grep -Fw -e 5262 -e 10991 core/transcript.txt | grep -e 5267 -e 11015 > core/tmp; mv core/tmp core/transcript.txt

grep -Fw -e 5267 -e 11015 core/exon_transcript.txt | grep -e 22487 -e 46834 > core/tmp; mv core/tmp core/exon_transcript.txt

grep -w -e 22487 -e 46834 core/exon.txt > core/tmp; mv core/tmp core/exon.txt

grep -w -e AATE007892 -e AATE006984 core/translation.txt > core/tmp; mv core/tmp core/translation.txt

grep -w -e  5143 -e 10765 core/translation_attrib.txt > core/tmp; mv core/tmp core/translation_attrib.txt 




# find shortest toplevel with protein_coding

${ALIAS} -D anopheles_atroparvus_core_1810_93_3 -e 'select * from seq_region as sr join seq_region_attrib as sra join seq_region_attrib as sra2 where sr.seq_region_id = sra.seq_region_id and sra.attrib_type_id=6 and sra2.seq_region_id = sr.seq_region_id and sra2.attrib_type_id = 64 order by length limit 3'

seq_region_id	name	coord_system_id	length	seq_region_id	attrib_type_id	value	seq_region_id	attrib_type_id	value
10473	AXCP01009878	2	1027	10473	6	1	10473	64	1
10199	AXCP01009863	2	1050	10199	6	1	10199	64	1
10550	AXCP01009868	2	1077	10550	6	1	10550	64	1

