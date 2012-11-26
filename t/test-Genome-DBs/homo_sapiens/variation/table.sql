CREATE TABLE `allele` (
  `allele_id` int(11) NOT NULL AUTO_INCREMENT,
  `variation_id` int(11) unsigned NOT NULL,
  `subsnp_id` int(11) unsigned DEFAULT NULL,
  `allele_code_id` int(11) unsigned NOT NULL,
  `sample_id` int(11) unsigned DEFAULT NULL,
  `frequency` float unsigned DEFAULT NULL,
  `count` int(11) unsigned DEFAULT NULL,
  `frequency_submitter_handle` int(10) DEFAULT NULL,
  PRIMARY KEY (`allele_id`),
  KEY `variation_idx` (`variation_id`),
  KEY `subsnp_idx` (`subsnp_id`),
  KEY `sample_idx` (`sample_id`)
) ENGINE=MyISAM AUTO_INCREMENT=6785 DEFAULT CHARSET=latin1;

CREATE TABLE `allele_code` (
  `allele_code_id` int(11) NOT NULL AUTO_INCREMENT,
  `allele` varchar(60000) DEFAULT NULL,
  PRIMARY KEY (`allele_code_id`),
  UNIQUE KEY `allele_idx` (`allele`(1000))
) ENGINE=MyISAM AUTO_INCREMENT=32 DEFAULT CHARSET=latin1;

CREATE TABLE `associate_study` (
  `study1_id` int(10) unsigned NOT NULL,
  `study2_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`study1_id`,`study2_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `attrib` (
  `attrib_id` int(11) unsigned NOT NULL DEFAULT '0',
  `attrib_type_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `value` text NOT NULL,
  PRIMARY KEY (`attrib_id`),
  UNIQUE KEY `type_val_idx` (`attrib_type_id`,`value`(40))
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `attrib_set` (
  `attrib_set_id` int(11) unsigned NOT NULL DEFAULT '0',
  `attrib_id` int(11) unsigned NOT NULL DEFAULT '0',
  UNIQUE KEY `set_idx` (`attrib_set_id`,`attrib_id`),
  KEY `attrib_idx` (`attrib_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `attrib_type` (
  `attrib_type_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `code` varchar(20) NOT NULL DEFAULT '',
  `name` varchar(255) NOT NULL DEFAULT '',
  `description` text,
  PRIMARY KEY (`attrib_type_id`),
  UNIQUE KEY `code_idx` (`code`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `compressed_genotype_region` (
  `sample_id` int(10) unsigned NOT NULL,
  `seq_region_id` int(10) unsigned NOT NULL,
  `seq_region_start` int(11) NOT NULL,
  `seq_region_end` int(11) NOT NULL,
  `seq_region_strand` tinyint(4) NOT NULL,
  `genotypes` blob,
  KEY `pos_idx` (`seq_region_id`,`seq_region_start`),
  KEY `sample_idx` (`sample_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `compressed_genotype_var` (
  `variation_id` int(11) unsigned NOT NULL,
  `subsnp_id` int(11) unsigned DEFAULT NULL,
  `genotypes` blob,
  KEY `variation_idx` (`variation_id`),
  KEY `subsnp_idx` (`subsnp_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `coord_system` (
  `coord_system_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `species_id` int(10) unsigned NOT NULL DEFAULT '1',
  `name` varchar(40) NOT NULL,
  `version` varchar(255) DEFAULT NULL,
  `rank` int(11) NOT NULL,
  `attrib` set('default_version','sequence_level') DEFAULT NULL,
  PRIMARY KEY (`coord_system_id`),
  UNIQUE KEY `rank_idx` (`rank`,`species_id`),
  UNIQUE KEY `name_idx` (`name`,`version`,`species_id`),
  KEY `species_idx` (`species_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `failed_allele` (
  `failed_allele_id` int(11) NOT NULL AUTO_INCREMENT,
  `allele_id` int(10) unsigned NOT NULL,
  `failed_description_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`failed_allele_id`),
  UNIQUE KEY `allele_idx` (`allele_id`,`failed_description_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `failed_description` (
  `failed_description_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `description` text NOT NULL,
  PRIMARY KEY (`failed_description_id`)
) ENGINE=MyISAM AUTO_INCREMENT=20 DEFAULT CHARSET=latin1;

CREATE TABLE `failed_structural_variation` (
  `failed_structural_variation_id` int(11) NOT NULL AUTO_INCREMENT,
  `structural_variation_id` int(10) unsigned NOT NULL,
  `failed_description_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`failed_structural_variation_id`),
  UNIQUE KEY `structural_variation_idx` (`structural_variation_id`,`failed_description_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `failed_variation` (
  `failed_variation_id` int(11) NOT NULL AUTO_INCREMENT,
  `variation_id` int(10) unsigned NOT NULL,
  `failed_description_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`failed_variation_id`),
  UNIQUE KEY `variation_idx` (`variation_id`,`failed_description_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `genotype_code` (
  `genotype_code_id` int(11) unsigned NOT NULL,
  `allele_code_id` int(11) unsigned NOT NULL,
  `haplotype_id` tinyint(2) unsigned NOT NULL,
  KEY `genotype_code_id` (`genotype_code_id`),
  KEY `allele_code_id` (`allele_code_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `individual` (
  `sample_id` int(10) unsigned NOT NULL,
  `gender` enum('Male','Female','Unknown') NOT NULL DEFAULT 'Unknown',
  `father_individual_sample_id` int(10) unsigned DEFAULT NULL,
  `mother_individual_sample_id` int(10) unsigned DEFAULT NULL,
  `individual_type_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`sample_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `individual_genotype_multiple_bp` (
  `variation_id` int(10) unsigned NOT NULL,
  `subsnp_id` int(15) unsigned DEFAULT NULL,
  `allele_1` varchar(25000) DEFAULT NULL,
  `allele_2` varchar(25000) DEFAULT NULL,
  `sample_id` int(10) unsigned DEFAULT NULL,
  KEY `variation_idx` (`variation_id`),
  KEY `subsnp_idx` (`subsnp_id`),
  KEY `sample_idx` (`sample_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `individual_population` (
  `individual_sample_id` int(10) unsigned NOT NULL,
  `population_sample_id` int(10) unsigned NOT NULL,
  KEY `individual_sample_idx` (`individual_sample_id`),
  KEY `population_sample_idx` (`population_sample_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `individual_type` (
  `individual_type_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `description` text,
  PRIMARY KEY (`individual_type_id`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;

CREATE TABLE `meta` (
  `meta_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `species_id` int(10) unsigned DEFAULT '1',
  `meta_key` varchar(40) NOT NULL,
  `meta_value` varchar(255) NOT NULL,
  PRIMARY KEY (`meta_id`),
  UNIQUE KEY `species_key_value_idx` (`species_id`,`meta_key`,`meta_value`),
  KEY `species_value_idx` (`species_id`,`meta_value`)
) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;

CREATE TABLE `meta_coord` (
  `table_name` varchar(40) NOT NULL,
  `coord_system_id` int(10) unsigned NOT NULL,
  `max_length` int(11) DEFAULT NULL,
  UNIQUE KEY `table_name` (`table_name`,`coord_system_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `motif_feature_variation` (
  `motif_feature_variation_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `variation_feature_id` int(11) unsigned NOT NULL,
  `feature_stable_id` varchar(128) DEFAULT NULL,
  `motif_feature_id` int(11) unsigned NOT NULL,
  `allele_string` text,
  `somatic` tinyint(1) NOT NULL DEFAULT '0',
  `consequence_types` set('splice_acceptor_variant','splice_donor_variant','stop_lost','coding_sequence_variant','missense_variant','stop_gained','synonymous_variant','frameshift_variant','nc_transcript_variant','non_coding_exon_variant','mature_miRNA_variant','NMD_transcript_variant','5_prime_UTR_variant','3_prime_UTR_variant','incomplete_terminal_codon_variant','intron_variant','splice_region_variant','downstream_gene_variant','upstream_gene_variant','initiator_codon_variant','stop_retained_variant','inframe_insertion','inframe_deletion','transcript_ablation','transcript_fusion','transcript_amplification','transcript_translocation','TF_binding_site_variant','TFBS_ablation','TFBS_fusion','TFBS_amplification','TFBS_translocation','regulatory_region_variant','regulatory_region_ablation','regulatory_region_fusion','regulatory_region_amplification','regulatory_region_translocation','feature_elongation','feature_truncation') DEFAULT NULL,
  `motif_name` text,
  `motif_start` int(11) unsigned DEFAULT NULL,
  `motif_end` int(11) unsigned DEFAULT NULL,
  `motif_score_delta` float DEFAULT NULL,
  `in_informative_position` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`motif_feature_variation_id`),
  KEY `variation_feature_idx` (`variation_feature_id`),
  KEY `feature_idx` (`feature_stable_id`),
  KEY `consequence_type_idx` (`consequence_types`),
  KEY `somatic_feature_idx` (`feature_stable_id`,`somatic`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `phenotype` (
  `phenotype_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`phenotype_id`),
  UNIQUE KEY `name_idx` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `population` (
  `sample_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`sample_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `population_genotype` (
  `population_genotype_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `variation_id` int(11) unsigned NOT NULL,
  `subsnp_id` int(11) unsigned DEFAULT NULL,
  `genotype_code_id` int(11) DEFAULT NULL,
  `frequency` float DEFAULT NULL,
  `sample_id` int(10) unsigned DEFAULT NULL,
  `count` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`population_genotype_id`),
  KEY `sample_idx` (`sample_id`),
  KEY `variation_idx` (`variation_id`),
  KEY `subsnp_idx` (`subsnp_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `population_structure` (
  `super_population_sample_id` int(10) unsigned NOT NULL,
  `sub_population_sample_id` int(10) unsigned NOT NULL,
  UNIQUE KEY `super_population_sample_id` (`super_population_sample_id`,`sub_population_sample_id`),
  KEY `sub_pop_sample_idx` (`sub_population_sample_id`,`super_population_sample_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `protein_function_predictions` (
  `translation_md5_id` int(11) unsigned NOT NULL,
  `analysis_attrib_id` int(11) unsigned NOT NULL,
  `prediction_matrix` mediumblob,
  PRIMARY KEY (`translation_md5_id`,`analysis_attrib_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `read_coverage` (
  `seq_region_id` int(10) unsigned NOT NULL,
  `seq_region_start` int(11) NOT NULL,
  `seq_region_end` int(11) NOT NULL,
  `level` tinyint(4) NOT NULL,
  `sample_id` int(10) unsigned NOT NULL,
  KEY `seq_region_idx` (`seq_region_id`,`seq_region_start`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `regulatory_feature_variation` (
  `regulatory_feature_variation_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `variation_feature_id` int(11) unsigned NOT NULL,
  `feature_stable_id` varchar(128) DEFAULT NULL,
  `feature_type` text,
  `allele_string` text,
  `somatic` tinyint(1) NOT NULL DEFAULT '0',
  `consequence_types` set('splice_acceptor_variant','splice_donor_variant','stop_lost','coding_sequence_variant','missense_variant','stop_gained','synonymous_variant','frameshift_variant','nc_transcript_variant','non_coding_exon_variant','mature_miRNA_variant','NMD_transcript_variant','5_prime_UTR_variant','3_prime_UTR_variant','incomplete_terminal_codon_variant','intron_variant','splice_region_variant','downstream_gene_variant','upstream_gene_variant','initiator_codon_variant','stop_retained_variant','inframe_insertion','inframe_deletion','transcript_ablation','transcript_fusion','transcript_amplification','transcript_translocation','TF_binding_site_variant','TFBS_ablation','TFBS_fusion','TFBS_amplification','TFBS_translocation','regulatory_region_variant','regulatory_region_ablation','regulatory_region_fusion','regulatory_region_amplification','regulatory_region_translocation','feature_elongation','feature_truncation') DEFAULT NULL,
  PRIMARY KEY (`regulatory_feature_variation_id`),
  KEY `variation_feature_idx` (`variation_feature_id`),
  KEY `feature_idx` (`feature_stable_id`),
  KEY `consequence_type_idx` (`consequence_types`),
  KEY `somatic_feature_idx` (`feature_stable_id`,`somatic`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `sample` (
  `sample_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `size` int(11) DEFAULT NULL,
  `description` text,
  `display` enum('REFERENCE','DEFAULT','DISPLAYABLE','UNDISPLAYABLE','LD','MARTDISPLAYABLE') DEFAULT 'UNDISPLAYABLE',
  `freqs_from_gts` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`sample_id`),
  KEY `name_idx` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

CREATE TABLE `sample_synonym` (
  `sample_synonym_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sample_id` int(10) unsigned NOT NULL,
  `source_id` int(10) unsigned NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`sample_synonym_id`),
  KEY `sample_idx` (`sample_id`),
  KEY `name` (`name`,`source_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `seq_region` (
  `seq_region_id` int(10) unsigned NOT NULL,
  `name` varchar(40) NOT NULL,
  `coord_system_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`seq_region_id`),
  UNIQUE KEY `name_cs_idx` (`name`,`coord_system_id`),
  KEY `cs_idx` (`coord_system_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `source` (
  `source_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(24) NOT NULL,
  `version` int(11) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `type` enum('chip','lsdb') DEFAULT NULL,
  `somatic_status` enum('germline','somatic','mixed') DEFAULT 'germline',
  PRIMARY KEY (`source_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

CREATE TABLE `strain_gtype_poly` (
  `variation_id` int(10) unsigned NOT NULL,
  `sample_name` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`variation_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `structural_variation` (
  `structural_variation_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `variation_name` varchar(255) DEFAULT NULL,
  `source_id` int(10) unsigned NOT NULL,
  `study_id` int(10) unsigned DEFAULT NULL,
  `class_attrib_id` int(10) unsigned NOT NULL DEFAULT '0',
  `validation_status` enum('validated','not validated','high quality') DEFAULT NULL,
  `is_evidence` tinyint(4) DEFAULT '0',
  `somatic` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`structural_variation_id`),
  KEY `name_idx` (`variation_name`),
  KEY `source_idx` (`source_id`),
  KEY `study_idx` (`study_id`),
  KEY `attrib_idx` (`class_attrib_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `structural_variation_annotation` (
  `structural_variation_annotation_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `structural_variation_id` int(10) unsigned NOT NULL,
  `clinical_attrib_id` int(10) unsigned DEFAULT NULL,
  `phenotype_id` int(10) unsigned DEFAULT NULL,
  `sample_id` int(10) unsigned DEFAULT NULL,
  `strain_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`structural_variation_annotation_id`),
  KEY `structural_variation_idx` (`structural_variation_id`),
  KEY `clinical_attrib_idx` (`clinical_attrib_id`),
  KEY `phenotype_idx` (`phenotype_id`),
  KEY `sample_idx` (`sample_id`),
  KEY `strain_idx` (`strain_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `structural_variation_association` (
  `structural_variation_id` int(10) unsigned NOT NULL,
  `supporting_structural_variation_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`structural_variation_id`,`supporting_structural_variation_id`),
  KEY `structural_variation_idx` (`structural_variation_id`),
  KEY `supporting_structural_variation_idx` (`supporting_structural_variation_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `structural_variation_feature` (
  `structural_variation_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `seq_region_id` int(10) unsigned NOT NULL,
  `outer_start` int(11) DEFAULT NULL,
  `seq_region_start` int(11) NOT NULL,
  `inner_start` int(11) DEFAULT NULL,
  `inner_end` int(11) DEFAULT NULL,
  `seq_region_end` int(11) NOT NULL,
  `outer_end` int(11) DEFAULT NULL,
  `seq_region_strand` tinyint(4) NOT NULL,
  `structural_variation_id` int(10) unsigned NOT NULL,
  `variation_name` varchar(255) DEFAULT NULL,
  `source_id` int(10) unsigned NOT NULL,
  `class_attrib_id` int(10) unsigned NOT NULL DEFAULT '0',
  `allele_string` longtext,
  `is_evidence` tinyint(1) NOT NULL DEFAULT '0',
  `somatic` tinyint(1) NOT NULL DEFAULT '0',
  `breakpoint_order` tinyint(4) DEFAULT NULL,
  `variation_set_id` set('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27','28','29','30','31','32','33','34','35','36','37','38','39','40','41','42','43','44','45','46','47','48','49','50','51','52','53','54','55','56','57','58','59','60','61','62','63','64') NOT NULL DEFAULT '',
  PRIMARY KEY (`structural_variation_feature_id`),
  KEY `pos_idx` (`seq_region_id`,`seq_region_start`,`seq_region_end`),
  KEY `structural_variation_idx` (`structural_variation_id`),
  KEY `source_idx` (`source_id`),
  KEY `attrib_idx` (`class_attrib_id`),
  KEY `variation_set_idx` (`variation_set_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `study` (
  `study_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `source_id` int(10) unsigned NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `external_reference` varchar(255) DEFAULT NULL,
  `study_type` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`study_id`),
  KEY `source_idx` (`source_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `submitter_handle` (
  `handle_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `handle` varchar(25) DEFAULT NULL,
  PRIMARY KEY (`handle_id`),
  UNIQUE KEY `handle` (`handle`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `subsnp_handle` (
  `subsnp_id` int(11) unsigned NOT NULL,
  `handle` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`subsnp_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `tagged_variation_feature` (
  `variation_feature_id` int(10) unsigned NOT NULL,
  `tagged_variation_feature_id` int(10) unsigned DEFAULT NULL,
  `sample_id` int(10) unsigned NOT NULL,
  KEY `tag_idx` (`variation_feature_id`),
  KEY `tagged_idx` (`tagged_variation_feature_id`),
  KEY `sample_idx` (`sample_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `tmp_individual_genotype_single_bp` (
  `variation_id` int(10) NOT NULL,
  `subsnp_id` int(15) unsigned DEFAULT NULL,
  `allele_1` char(1) DEFAULT NULL,
  `allele_2` char(1) DEFAULT NULL,
  `sample_id` int(11) DEFAULT NULL,
  KEY `variation_idx` (`variation_id`),
  KEY `subsnp_idx` (`subsnp_id`),
  KEY `sample_idx` (`sample_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=100000000;

CREATE TABLE `transcript_variation` (
  `transcript_variation_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `variation_feature_id` int(11) unsigned NOT NULL,
  `feature_stable_id` varchar(128) DEFAULT NULL,
  `allele_string` text,
  `somatic` tinyint(1) NOT NULL DEFAULT '0',
  `consequence_types` set('splice_acceptor_variant','splice_donor_variant','stop_lost','coding_sequence_variant','missense_variant','stop_gained','synonymous_variant','frameshift_variant','nc_transcript_variant','non_coding_exon_variant','mature_miRNA_variant','NMD_transcript_variant','5_prime_UTR_variant','3_prime_UTR_variant','incomplete_terminal_codon_variant','intron_variant','splice_region_variant','downstream_gene_variant','upstream_gene_variant','initiator_codon_variant','stop_retained_variant','inframe_insertion','inframe_deletion','transcript_ablation','transcript_fusion','transcript_amplification','transcript_translocation','TFBS_ablation','TFBS_fusion','TFBS_amplification','TFBS_translocation','regulatory_region_ablation','regulatory_region_fusion','regulatory_region_amplification','regulatory_region_translocation','feature_elongation','feature_truncation') DEFAULT NULL,
  `cds_start` int(11) unsigned DEFAULT NULL,
  `cds_end` int(11) unsigned DEFAULT NULL,
  `cdna_start` int(11) unsigned DEFAULT NULL,
  `cdna_end` int(11) unsigned DEFAULT NULL,
  `translation_start` int(11) unsigned DEFAULT NULL,
  `translation_end` int(11) unsigned DEFAULT NULL,
  `distance_to_transcript` int(11) unsigned DEFAULT NULL,
  `codon_allele_string` text,
  `pep_allele_string` text,
  `hgvs_genomic` text,
  `hgvs_transcript` text,
  `hgvs_protein` text,
  `polyphen_prediction` enum('unknown','benign','possibly damaging','probably damaging') DEFAULT NULL,
  `polyphen_score` float DEFAULT NULL,
  `sift_prediction` enum('tolerated','deleterious') DEFAULT NULL,
  `sift_score` float DEFAULT NULL,
  PRIMARY KEY (`transcript_variation_id`),
  KEY `variation_feature_idx` (`variation_feature_id`),
  KEY `feature_idx` (`feature_stable_id`),
  KEY `consequence_type_idx` (`consequence_types`),
  KEY `somatic_feature_idx` (`feature_stable_id`,`somatic`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `translation_md5` (
  `translation_md5_id` int(11) NOT NULL AUTO_INCREMENT,
  `translation_md5` char(32) NOT NULL,
  PRIMARY KEY (`translation_md5_id`),
  UNIQUE KEY `md5_idx` (`translation_md5`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `variation` (
  `variation_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `source_id` int(10) unsigned NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `validation_status` set('cluster','freq','submitter','doublehit','hapmap','1000Genome','failed','precious') DEFAULT NULL,
  `ancestral_allele` varchar(255) DEFAULT NULL,
  `flipped` tinyint(1) unsigned DEFAULT NULL,
  `class_attrib_id` int(10) unsigned DEFAULT '0',
  `somatic` tinyint(1) NOT NULL DEFAULT '0',
  `minor_allele` char(1) DEFAULT NULL,
  `minor_allele_freq` float DEFAULT NULL,
  `minor_allele_count` int(10) unsigned DEFAULT NULL,
  `clinical_significance_attrib_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`variation_id`),
  UNIQUE KEY `name` (`name`),
  KEY `source_idx` (`source_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

CREATE TABLE `variation_annotation` (
  `variation_annotation_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `variation_id` int(10) unsigned NOT NULL,
  `phenotype_id` int(10) unsigned NOT NULL,
  `study_id` int(10) unsigned NOT NULL,
  `associated_gene` varchar(255) DEFAULT NULL,
  `associated_variant_risk_allele` varchar(255) DEFAULT NULL,
  `variation_names` varchar(255) DEFAULT NULL,
  `risk_allele_freq_in_controls` double DEFAULT NULL,
  `p_value` double DEFAULT NULL,
  PRIMARY KEY (`variation_annotation_id`),
  KEY `variation_idx` (`variation_id`),
  KEY `phenotype_idx` (`phenotype_id`),
  KEY `study_idx` (`study_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `variation_feature` (
  `variation_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `seq_region_id` int(10) unsigned NOT NULL,
  `seq_region_start` int(11) NOT NULL,
  `seq_region_end` int(11) NOT NULL,
  `seq_region_strand` tinyint(4) NOT NULL,
  `variation_id` int(10) unsigned NOT NULL,
  `allele_string` varchar(50000) DEFAULT NULL,
  `variation_name` varchar(255) DEFAULT NULL,
  `map_weight` int(11) NOT NULL,
  `flags` set('genotyped') DEFAULT NULL,
  `source_id` int(10) unsigned NOT NULL,
  `validation_status` set('cluster','freq','submitter','doublehit','hapmap','1000Genome','precious') DEFAULT NULL,
  `consequence_types` set('intergenic_variant','splice_acceptor_variant','splice_donor_variant','stop_lost','coding_sequence_variant','missense_variant','stop_gained','synonymous_variant','frameshift_variant','nc_transcript_variant','non_coding_exon_variant','mature_miRNA_variant','NMD_transcript_variant','5_prime_UTR_variant','3_prime_UTR_variant','incomplete_terminal_codon_variant','intron_variant','splice_region_variant','downstream_gene_variant','upstream_gene_variant','initiator_codon_variant','stop_retained_variant','inframe_insertion','inframe_deletion','transcript_ablation','transcript_fusion','transcript_amplification','transcript_translocation','TFBS_ablation','TFBS_fusion','TFBS_amplification','TFBS_translocation','regulatory_region_ablation','regulatory_region_fusion','regulatory_region_amplification','regulatory_region_translocation','feature_elongation','feature_truncation') NOT NULL DEFAULT 'intergenic_variant',
  `variation_set_id` set('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27','28','29','30','31','32','33','34','35','36','37','38','39','40','41','42','43','44','45','46','47','48','49','50','51','52','53','54','55','56','57','58','59','60','61','62','63','64') NOT NULL DEFAULT '',
  `class_attrib_id` int(10) unsigned DEFAULT '0',
  `somatic` tinyint(1) NOT NULL DEFAULT '0',
  `minor_allele` char(1) DEFAULT NULL,
  `minor_allele_freq` float DEFAULT NULL,
  `minor_allele_count` int(10) unsigned DEFAULT NULL,
  `alignment_quality` double DEFAULT NULL,
  PRIMARY KEY (`variation_feature_id`),
  KEY `pos_idx` (`seq_region_id`,`seq_region_start`,`seq_region_end`),
  KEY `variation_idx` (`variation_id`),
  KEY `variation_set_idx` (`variation_set_id`),
  KEY `consequence_type_idx` (`consequence_types`)
) ENGINE=MyISAM AUTO_INCREMENT=32 DEFAULT CHARSET=latin1;

CREATE TABLE `variation_set` (
  `variation_set_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `description` text,
  `short_name_attrib_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`variation_set_id`),
  KEY `name_idx` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `variation_set_structural_variation` (
  `structural_variation_id` int(10) unsigned NOT NULL,
  `variation_set_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`structural_variation_id`,`variation_set_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `variation_set_structure` (
  `variation_set_super` int(10) unsigned NOT NULL,
  `variation_set_sub` int(10) unsigned NOT NULL,
  PRIMARY KEY (`variation_set_super`,`variation_set_sub`),
  KEY `sub_idx` (`variation_set_sub`,`variation_set_super`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `variation_set_variation` (
  `variation_id` int(10) unsigned NOT NULL,
  `variation_set_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`variation_id`,`variation_set_id`),
  KEY `variation_set_idx` (`variation_set_id`,`variation_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `variation_synonym` (
  `variation_synonym_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `variation_id` int(10) unsigned NOT NULL,
  `subsnp_id` int(15) unsigned DEFAULT NULL,
  `source_id` int(10) unsigned NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `moltype` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`variation_synonym_id`),
  UNIQUE KEY `name` (`name`,`source_id`),
  KEY `variation_idx` (`variation_id`),
  KEY `subsnp_idx` (`subsnp_id`),
  KEY `source_idx` (`source_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

