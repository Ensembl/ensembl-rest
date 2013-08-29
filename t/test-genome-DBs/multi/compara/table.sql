CREATE TABLE `CAFE_gene_family` (
  `cafe_gene_family_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `root_id` int(10) unsigned NOT NULL,
  `lca_id` int(10) unsigned NOT NULL,
  `gene_tree_root_id` int(10) unsigned NOT NULL,
  `pvalue_avg` double(5,4) DEFAULT NULL,
  `lambdas` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`cafe_gene_family_id`),
  KEY `lca_id` (`lca_id`),
  KEY `root_id` (`root_id`),
  KEY `gene_tree_root_id` (`gene_tree_root_id`)
) ENGINE=MyISAM  ;

CREATE TABLE `CAFE_species_gene` (
  `cafe_gene_family_id` int(10) unsigned NOT NULL,
  `node_id` int(10) unsigned NOT NULL,
  `taxon_id` int(10) unsigned DEFAULT NULL,
  `n_members` int(4) unsigned NOT NULL,
  `pvalue` double(5,4) DEFAULT NULL,
  KEY `node_id` (`node_id`),
  KEY `cafe_gene_family_id` (`cafe_gene_family_id`)
) ENGINE=MyISAM ;

CREATE TABLE `conservation_score` (
  `genomic_align_block_id` bigint(20) unsigned NOT NULL,
  `window_size` smallint(5) unsigned NOT NULL,
  `position` int(10) unsigned NOT NULL,
  `expected_score` blob,
  `diff_score` blob,
  KEY `genomic_align_block_id` (`genomic_align_block_id`,`window_size`)
) ENGINE=MyISAM  MAX_ROWS=15000000 AVG_ROW_LENGTH=841;

CREATE TABLE `constrained_element` (
  `constrained_element_id` bigint(20) unsigned NOT NULL,
  `dnafrag_id` bigint(20) unsigned NOT NULL,
  `dnafrag_start` int(12) unsigned NOT NULL,
  `dnafrag_end` int(12) unsigned NOT NULL,
  `dnafrag_strand` int(2) DEFAULT NULL,
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  `p_value` double DEFAULT NULL,
  `score` double NOT NULL DEFAULT '0',
  KEY `dnafrag_id` (`dnafrag_id`),
  KEY `constrained_element_id_idx` (`constrained_element_id`),
  KEY `mlssid_idx` (`method_link_species_set_id`),
  KEY `mlssid_dfId_dfStart_dfEnd_idx` (`method_link_species_set_id`,`dnafrag_id`,`dnafrag_start`,`dnafrag_end`),
  KEY `mlssid_dfId_idx` (`method_link_species_set_id`,`dnafrag_id`)
) ENGINE=MyISAM ;

CREATE TABLE `dnafrag` (
  `dnafrag_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `length` int(11) NOT NULL DEFAULT '0',
  `name` varchar(40) NOT NULL DEFAULT '',
  `genome_db_id` int(10) unsigned NOT NULL,
  `coord_system_name` varchar(40) DEFAULT NULL,
  `is_reference` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`dnafrag_id`),
  UNIQUE KEY `name` (`genome_db_id`,`name`)
) ENGINE=MyISAM  ;

CREATE TABLE `dnafrag_region` (
  `synteny_region_id` int(10) unsigned NOT NULL DEFAULT '0',
  `dnafrag_id` bigint(20) unsigned NOT NULL DEFAULT '0',
  `dnafrag_start` int(10) unsigned NOT NULL DEFAULT '0',
  `dnafrag_end` int(10) unsigned NOT NULL DEFAULT '0',
  `dnafrag_strand` tinyint(4) NOT NULL DEFAULT '0',
  KEY `synteny` (`synteny_region_id`,`dnafrag_id`),
  KEY `synteny_reversed` (`dnafrag_id`,`synteny_region_id`)
) ENGINE=MyISAM ;

CREATE TABLE `domain` (
  `domain_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `stable_id` varchar(40) NOT NULL,
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`domain_id`),
  UNIQUE KEY `stable_id` (`stable_id`,`method_link_species_set_id`),
  KEY `method_link_species_set_id` (`method_link_species_set_id`)
) ENGINE=MyISAM ;

CREATE TABLE `domain_member` (
  `domain_id` int(10) unsigned NOT NULL,
  `member_id` int(10) unsigned NOT NULL,
  `member_start` int(10) DEFAULT NULL,
  `member_end` int(10) DEFAULT NULL,
  UNIQUE KEY `domain_id` (`domain_id`,`member_id`,`member_start`,`member_end`),
  UNIQUE KEY `member_id` (`member_id`,`domain_id`,`member_start`,`member_end`)
) ENGINE=MyISAM ;

CREATE TABLE `external_db` (
  `external_db_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `db_name` varchar(100) NOT NULL,
  `db_release` varchar(255) DEFAULT NULL,
  `status` enum('KNOWNXREF','KNOWN','XREF','PRED','ORTH','PSEUDO') NOT NULL,
  `priority` int(11) NOT NULL,
  `db_display_name` varchar(255) DEFAULT NULL,
  `type` enum('ARRAY','ALT_TRANS','ALT_GENE','MISC','LIT','PRIMARY_DB_SYNONYM','ENSEMBL') DEFAULT NULL,
  `secondary_db_name` varchar(255) DEFAULT NULL,
  `secondary_db_table` varchar(255) DEFAULT NULL,
  `description` text,
  PRIMARY KEY (`external_db_id`),
  UNIQUE KEY `db_name_db_release_idx` (`db_name`,`db_release`)
) ENGINE=MyISAM ;

CREATE TABLE `family` (
  `family_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `stable_id` varchar(40) NOT NULL,
  `version` int(10) unsigned NOT NULL,
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `description_score` double DEFAULT NULL,
  PRIMARY KEY (`family_id`),
  UNIQUE KEY `stable_id` (`stable_id`),
  KEY `method_link_species_set_id` (`method_link_species_set_id`),
  KEY `description` (`description`)
) ENGINE=MyISAM  ;

CREATE TABLE `family_member` (
  `family_id` int(10) unsigned NOT NULL,
  `member_id` int(10) unsigned NOT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`family_id`,`member_id`),
  KEY `family_id` (`family_id`),
  KEY `member_id` (`member_id`)
) ENGINE=MyISAM ;

CREATE TABLE `gene_align` (
  `gene_align_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `seq_type` varchar(40) DEFAULT NULL,
  `aln_method` varchar(40) NOT NULL DEFAULT '',
  `aln_length` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`gene_align_id`)
) ENGINE=MyISAM  ;

CREATE TABLE `gene_align_member` (
  `gene_align_id` int(10) unsigned NOT NULL,
  `member_id` int(10) unsigned NOT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`gene_align_id`,`member_id`),
  KEY `member_id` (`member_id`)
) ENGINE=MyISAM ;

CREATE TABLE `gene_tree_node` (
  `node_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` int(10) unsigned DEFAULT NULL,
  `root_id` int(10) unsigned DEFAULT NULL,
  `left_index` int(10) NOT NULL DEFAULT '0',
  `right_index` int(10) NOT NULL DEFAULT '0',
  `distance_to_parent` double NOT NULL DEFAULT '1',
  `member_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`node_id`),
  KEY `parent_id` (`parent_id`),
  KEY `member_id` (`member_id`),
  KEY `root_id` (`root_id`),
  KEY `root_id_left_index` (`root_id`,`left_index`)
) ENGINE=MyISAM  ;

CREATE TABLE `gene_tree_node_attr` (
  `node_id` int(10) unsigned NOT NULL,
  `node_type` enum('duplication','dubious','speciation','gene_split') DEFAULT NULL,
  `taxon_id` int(10) unsigned DEFAULT NULL,
  `taxon_name` varchar(255) DEFAULT NULL,
  `bootstrap` tinyint(3) unsigned DEFAULT NULL,
  `duplication_confidence_score` double(5,4) DEFAULT NULL,
  PRIMARY KEY (`node_id`)
) ENGINE=MyISAM ;

CREATE TABLE `gene_tree_node_tag` (
  `node_id` int(10) unsigned NOT NULL,
  `tag` varchar(50) NOT NULL,
  `value` mediumtext NOT NULL,
  KEY `node_id_tag` (`node_id`,`tag`),
  KEY `node_id` (`node_id`)
) ENGINE=MyISAM ;

CREATE TABLE `gene_tree_root` (
  `root_id` int(10) unsigned NOT NULL,
  `member_type` enum('protein','ncrna') NOT NULL,
  `tree_type` enum('clusterset','supertree','tree') NOT NULL,
  `clusterset_id` varchar(20) NOT NULL DEFAULT 'default',
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  `gene_align_id` int(10) unsigned DEFAULT NULL,
  `ref_root_id` int(10) unsigned DEFAULT NULL,
  `stable_id` varchar(40) DEFAULT NULL,
  `version` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`root_id`),
  UNIQUE KEY `stable_id` (`stable_id`),
  KEY `method_link_species_set_id` (`method_link_species_set_id`),
  KEY `gene_align_id` (`gene_align_id`),
  KEY `ref_root_id` (`ref_root_id`),
  KEY `tree_type` (`tree_type`)
) ENGINE=MyISAM ;

CREATE TABLE `gene_tree_root_tag` (
  `root_id` int(10) unsigned NOT NULL,
  `tag` varchar(50) NOT NULL,
  `value` mediumtext NOT NULL,
  KEY `root_id_tag` (`root_id`,`tag`),
  KEY `root_id` (`root_id`)
) ENGINE=MyISAM ;

CREATE TABLE `genome_db` (
  `genome_db_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `taxon_id` int(10) unsigned DEFAULT NULL,
  `name` varchar(40) NOT NULL DEFAULT '',
  `assembly` varchar(100) NOT NULL DEFAULT '',
  `assembly_default` tinyint(1) DEFAULT '1',
  `genebuild` varchar(100) NOT NULL DEFAULT '',
  `locator` varchar(400) DEFAULT NULL,
  PRIMARY KEY (`genome_db_id`),
  UNIQUE KEY `name` (`name`,`assembly`,`genebuild`),
  KEY `taxon_id` (`taxon_id`)
) ENGINE=MyISAM  ;

CREATE TABLE `genomic_align` (
  `genomic_align_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `genomic_align_block_id` bigint(20) unsigned NOT NULL,
  `method_link_species_set_id` int(10) unsigned NOT NULL DEFAULT '0',
  `dnafrag_id` bigint(20) unsigned NOT NULL DEFAULT '0',
  `dnafrag_start` int(10) NOT NULL DEFAULT '0',
  `dnafrag_end` int(10) NOT NULL DEFAULT '0',
  `dnafrag_strand` tinyint(4) NOT NULL DEFAULT '0',
  `cigar_line` mediumtext,
  `visible` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `node_id` bigint(20) unsigned DEFAULT NULL,
  PRIMARY KEY (`genomic_align_id`),
  KEY `genomic_align_block_id` (`genomic_align_block_id`),
  KEY `method_link_species_set_id` (`method_link_species_set_id`),
  KEY `dnafrag` (`dnafrag_id`,`method_link_species_set_id`,`dnafrag_start`,`dnafrag_end`),
  KEY `node_id` (`node_id`)
) ENGINE=MyISAM   MAX_ROWS=1000000000 AVG_ROW_LENGTH=60;

CREATE TABLE `genomic_align_block` (
  `genomic_align_block_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `method_link_species_set_id` int(10) unsigned NOT NULL DEFAULT '0',
  `score` double DEFAULT NULL,
  `perc_id` tinyint(3) unsigned DEFAULT NULL,
  `length` int(10) DEFAULT NULL,
  `group_id` bigint(20) unsigned DEFAULT NULL,
  `level_id` tinyint(2) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`genomic_align_block_id`),
  KEY `method_link_species_set_id` (`method_link_species_set_id`)
) ENGINE=MyISAM  ;

CREATE TABLE `genomic_align_tree` (
  `node_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` bigint(20) unsigned NOT NULL DEFAULT '0',
  `root_id` bigint(20) unsigned NOT NULL DEFAULT '0',
  `left_index` int(10) NOT NULL DEFAULT '0',
  `right_index` int(10) NOT NULL DEFAULT '0',
  `left_node_id` bigint(10) NOT NULL DEFAULT '0',
  `right_node_id` bigint(10) NOT NULL DEFAULT '0',
  `distance_to_parent` double NOT NULL DEFAULT '1',
  PRIMARY KEY (`node_id`),
  KEY `parent_id` (`parent_id`),
  KEY `root_id` (`root_id`),
  KEY `left_index` (`root_id`,`left_index`)
) ENGINE=MyISAM  ;

CREATE TABLE `hmm_profile` (
  `model_id` varchar(40) NOT NULL,
  `name` varchar(40) DEFAULT NULL,
  `type` varchar(40) NOT NULL,
  `hc_profile` mediumtext,
  `consensus` mediumtext,
  PRIMARY KEY (`model_id`,`type`)
) ENGINE=MyISAM ;

CREATE TABLE `homology` (
  `homology_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  `description` enum('ortholog_one2one','apparent_ortholog_one2one','ortholog_one2many','ortholog_many2many','within_species_paralog','other_paralog','putative_gene_split','contiguous_gene_split','between_species_paralog','possible_ortholog','UBRH','BRH','MBRH','RHS','projection_unchanged','projection_altered') DEFAULT NULL,
  `subtype` varchar(40) NOT NULL DEFAULT '',
  `dn` float(10,5) DEFAULT NULL,
  `ds` float(10,5) DEFAULT NULL,
  `n` float(10,1) DEFAULT NULL,
  `s` float(10,1) DEFAULT NULL,
  `lnl` float(10,3) DEFAULT NULL,
  `threshold_on_ds` float(10,5) DEFAULT NULL,
  `ancestor_node_id` int(10) unsigned NOT NULL,
  `tree_node_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`homology_id`),
  KEY `method_link_species_set_id` (`method_link_species_set_id`),
  KEY `ancestor_node_id` (`ancestor_node_id`),
  KEY `tree_node_id` (`tree_node_id`)
) ENGINE=MyISAM  ;

CREATE TABLE `homology_member` (
  `homology_id` int(10) unsigned NOT NULL,
  `member_id` int(10) unsigned NOT NULL,
  `peptide_member_id` int(10) unsigned DEFAULT NULL,
  `cigar_line` mediumtext,
  `perc_cov` int(10) DEFAULT NULL,
  `perc_id` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  PRIMARY KEY (`homology_id`,`member_id`),
  KEY `homology_id` (`homology_id`),
  KEY `member_id` (`member_id`),
  KEY `peptide_member_id` (`peptide_member_id`)
) ENGINE=MyISAM  MAX_ROWS=300000000;

CREATE TABLE `mapping_session` (
  `mapping_session_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type` enum('family','tree') DEFAULT NULL,
  `when_mapped` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `rel_from` int(10) unsigned DEFAULT NULL,
  `rel_to` int(10) unsigned DEFAULT NULL,
  `prefix` char(4) NOT NULL,
  PRIMARY KEY (`mapping_session_id`),
  UNIQUE KEY `type` (`type`,`rel_from`,`rel_to`,`prefix`)
) ENGINE=MyISAM  ;

CREATE TABLE `member` (
  `member_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `stable_id` varchar(128) NOT NULL,
  `version` int(10) DEFAULT '0',
  `source_name` enum('ENSEMBLGENE','ENSEMBLPEP','Uniprot/SPTREMBL','Uniprot/SWISSPROT','ENSEMBLTRANS','EXTERNALCDS') NOT NULL,
  `taxon_id` int(10) unsigned NOT NULL,
  `genome_db_id` int(10) unsigned DEFAULT NULL,
  `sequence_id` int(10) unsigned DEFAULT NULL,
  `gene_member_id` int(10) unsigned DEFAULT NULL,
  `canonical_member_id` int(10) unsigned DEFAULT NULL,
  `description` text,
  `chr_name` char(40) DEFAULT NULL,
  `chr_start` int(10) DEFAULT NULL,
  `chr_end` int(10) DEFAULT NULL,
  `chr_strand` tinyint(1) NOT NULL,
  `display_label` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`member_id`),
  UNIQUE KEY `source_stable_id` (`stable_id`,`source_name`),
  KEY `taxon_id` (`taxon_id`),
  KEY `stable_id` (`stable_id`),
  KEY `source_name` (`source_name`),
  KEY `sequence_id` (`sequence_id`),
  KEY `gene_member_id` (`gene_member_id`),
  KEY `gdb_name_start_end` (`genome_db_id`,`chr_name`,`chr_start`,`chr_end`)
) ENGINE=MyISAM   MAX_ROWS=100000000;

CREATE TABLE `member_production_counts` (
  `stable_id` varchar(128) NOT NULL,
  `families` tinyint(1) unsigned DEFAULT '0',
  `gene_trees` tinyint(1) unsigned DEFAULT '0',
  `gene_gain_loss_trees` tinyint(1) unsigned DEFAULT '0',
  `orthologues` int(10) unsigned DEFAULT '0',
  `paralogues` int(10) unsigned DEFAULT '0',
  KEY `stable_id` (`stable_id`)
) ENGINE=MyISAM ;

CREATE TABLE `member_production_counts2` (
  `stable_id` varchar(128) NOT NULL,
  `families` tinyint(1) unsigned DEFAULT '0',
  `gene_trees` tinyint(1) unsigned DEFAULT '0',
  `gene_gain_loss_trees` tinyint(1) unsigned DEFAULT '0',
  `orthologues` int(10) unsigned DEFAULT '0',
  `paralogues` int(10) unsigned DEFAULT '0',
  KEY `stable_id` (`stable_id`)
) ENGINE=MyISAM ;

CREATE TABLE `member_xref` (
  `member_id` int(10) unsigned NOT NULL,
  `dbprimary_acc` varchar(10) NOT NULL,
  `external_db_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`member_id`,`dbprimary_acc`,`external_db_id`),
  KEY `external_db_id` (`external_db_id`)
) ENGINE=MyISAM ;

CREATE TABLE `meta` (
  `meta_id` int(11) NOT NULL AUTO_INCREMENT,
  `species_id` int(10) unsigned DEFAULT '1',
  `meta_key` varchar(40) NOT NULL,
  `meta_value` text NOT NULL,
  PRIMARY KEY (`meta_id`),
  UNIQUE KEY `species_key_value_idx` (`species_id`,`meta_key`,`meta_value`(255)),
  KEY `species_value_idx` (`species_id`,`meta_value`(255))
) ENGINE=MyISAM  ;

CREATE TABLE `method_link` (
  `method_link_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(50) NOT NULL DEFAULT '',
  `class` varchar(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`method_link_id`),
  UNIQUE KEY `type` (`type`)
) ENGINE=MyISAM  ;

CREATE TABLE `method_link_species_set` (
  `method_link_species_set_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `method_link_id` int(10) unsigned DEFAULT NULL,
  `species_set_id` int(10) unsigned NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL DEFAULT '',
  `source` varchar(255) NOT NULL DEFAULT 'ensembl',
  `url` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`method_link_species_set_id`),
  UNIQUE KEY `method_link_id` (`method_link_id`,`species_set_id`)
) ENGINE=MyISAM  ;

CREATE TABLE `method_link_species_set_tag` (
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  `tag` varchar(50) NOT NULL,
  `value` mediumtext,
  PRIMARY KEY (`method_link_species_set_id`,`tag`)
) ENGINE=MyISAM ;

CREATE TABLE `ncbi_taxa_name` (
  `taxon_id` int(10) unsigned NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `name_class` varchar(50) DEFAULT NULL,
  KEY `taxon_id` (`taxon_id`),
  KEY `name` (`name`),
  KEY `name_class` (`name_class`)
) ENGINE=MyISAM ;

CREATE TABLE `ncbi_taxa_node` (
  `taxon_id` int(10) unsigned NOT NULL,
  `parent_id` int(10) unsigned NOT NULL,
  `rank` char(32) NOT NULL DEFAULT '',
  `genbank_hidden_flag` tinyint(1) NOT NULL DEFAULT '0',
  `left_index` int(10) NOT NULL DEFAULT '0',
  `right_index` int(10) NOT NULL DEFAULT '0',
  `root_id` int(10) NOT NULL DEFAULT '1',
  PRIMARY KEY (`taxon_id`),
  KEY `parent_id` (`parent_id`),
  KEY `rank` (`rank`),
  KEY `left_index` (`left_index`),
  KEY `right_index` (`right_index`)
) ENGINE=MyISAM ;

CREATE TABLE `other_member_sequence` (
  `member_id` int(10) unsigned NOT NULL,
  `seq_type` varchar(40) NOT NULL,
  `length` int(10) NOT NULL,
  `sequence` mediumtext NOT NULL,
  PRIMARY KEY (`member_id`,`seq_type`)
) ENGINE=MyISAM  MAX_ROWS=10000000 AVG_ROW_LENGTH=60000;

CREATE TABLE `peptide_align_feature` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM  MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_ailuropoda_melanoleuca_109` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_anolis_carolinensis_111` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_bos_taurus_122` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_caenorhabditis_elegans_143` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_callithrix_jacchus_117` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_canis_familiaris_135` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_cavia_porcellus_69` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_choloepus_hoffmanni_78` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_ciona_intestinalis_128` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_ciona_savignyi_27` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_danio_rerio_110` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_dasypus_novemcinctus_86` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_dipodomys_ordii_83` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_drosophila_melanogaster_105` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_echinops_telfairi_33` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_equus_caballus_61` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_erinaceus_europaeus_49` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_felis_catus_139` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_gadus_morhua_126` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_gallus_gallus_142` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_gasterosteus_aculeatus_36` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_gorilla_gorilla_123` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_homo_sapiens_90` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_ictidomys_tridecemlineatus_131` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_latimeria_chalumnae_129` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_loxodonta_africana_98` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_macaca_mulatta_31` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_macropus_eugenii_91` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_meleagris_gallopavo_112` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_microcebus_murinus_58` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_monodelphis_domestica_46` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_mus_musculus_134` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_mustela_putorius_furo_138` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_myotis_lucifugus_118` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_nomascus_leucogenys_115` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_ochotona_princeps_67` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_oreochromis_niloticus_130` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_ornithorhynchus_anatinus_43` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_oryctolagus_cuniculus_108` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_oryzias_latipes_37` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_otolemur_garnettii_124` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_pan_troglodytes_125` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_pelodiscus_sinensis_136` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_petromyzon_marinus_120` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_pongo_abelii_60` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_procavia_capensis_79` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_pteropus_vampyrus_85` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_rattus_norvegicus_140` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_saccharomyces_cerevisiae_127` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_sarcophilus_harrisii_121` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_sorex_araneus_55` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_sus_scrofa_132` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_taeniopygia_guttata_87` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_takifugu_rubripes_4` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_tarsius_syrichta_82` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_tetraodon_nigroviridis_65` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `analysis_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=300000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_tupaia_belangeri_48` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_tursiops_truncatus_80` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_vicugna_pacos_84` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_xenopus_tropicalis_116` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `peptide_align_feature_xiphophorus_maculatus_137` (
  `peptide_align_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned NOT NULL,
  `hgenome_db_id` int(10) unsigned NOT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double DEFAULT NULL,
  `align_length` int(10) DEFAULT NULL,
  `identical_matches` int(10) DEFAULT NULL,
  `perc_ident` int(10) DEFAULT NULL,
  `positive_matches` int(10) DEFAULT NULL,
  `perc_pos` int(10) DEFAULT NULL,
  `hit_rank` int(10) DEFAULT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM   MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `sequence` (
  `sequence_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `length` int(10) NOT NULL,
  `sequence` longtext NOT NULL,
  PRIMARY KEY (`sequence_id`),
  KEY `sequence` (`sequence`(18))
) ENGINE=MyISAM   MAX_ROWS=10000000 AVG_ROW_LENGTH=19000;

CREATE TABLE `sitewise_aln` (
  `sitewise_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `aln_position` int(10) unsigned NOT NULL,
  `node_id` int(10) unsigned NOT NULL,
  `tree_node_id` int(10) unsigned NOT NULL,
  `omega` float(10,5) DEFAULT NULL,
  `omega_lower` float(10,5) DEFAULT NULL,
  `omega_upper` float(10,5) DEFAULT NULL,
  `optimal` float(10,5) DEFAULT NULL,
  `ncod` int(10) DEFAULT NULL,
  `threshold_on_branch_ds` float(10,5) DEFAULT NULL,
  `type` enum('single_character','random','all_gaps','constant','default','negative1','negative2','negative3','negative4','positive1','positive2','positive3','positive4','synonymous') NOT NULL,
  PRIMARY KEY (`sitewise_id`),
  UNIQUE KEY `aln_position_node_id_ds` (`aln_position`,`node_id`,`threshold_on_branch_ds`),
  KEY `tree_node_id` (`tree_node_id`),
  KEY `node_id` (`node_id`)
) ENGINE=MyISAM ;

CREATE TABLE `species_set` (
  `species_set_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `genome_db_id` int(10) unsigned DEFAULT NULL,
  UNIQUE KEY `species_set_id` (`species_set_id`,`genome_db_id`),
  KEY `genome_db_id` (`genome_db_id`)
) ENGINE=MyISAM  ;

CREATE TABLE `species_set_tag` (
  `species_set_id` int(10) unsigned NOT NULL,
  `tag` varchar(50) NOT NULL,
  `value` mediumtext,
  UNIQUE KEY `tag_species_set_id` (`species_set_id`,`tag`)
) ENGINE=MyISAM ;

CREATE TABLE `species_tree_node` (
  `node_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` int(10) unsigned DEFAULT NULL,
  `root_id` int(10) unsigned DEFAULT NULL,
  `left_index` int(10) NOT NULL DEFAULT '0',
  `right_index` int(10) NOT NULL DEFAULT '0',
  `distance_to_parent` double DEFAULT '1',
  PRIMARY KEY (`node_id`),
  KEY `parent_id` (`parent_id`),
  KEY `root_id` (`root_id`,`left_index`)
) ENGINE=MyISAM  ;

CREATE TABLE `species_tree_node_tag` (
  `node_id` int(10) unsigned NOT NULL,
  `tag` varchar(50) NOT NULL,
  `value` mediumtext NOT NULL,
  KEY `node_id_tag` (`node_id`,`tag`),
  KEY `tag_node_id` (`tag`,`node_id`),
  KEY `node_id` (`node_id`),
  KEY `tag` (`tag`)
) ENGINE=MyISAM ;

CREATE TABLE `species_tree_root` (
  `root_id` int(10) unsigned NOT NULL,
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  `species_tree` mediumtext,
  `pvalue_lim` double(5,4) DEFAULT NULL,
  PRIMARY KEY (`root_id`),
  KEY `method_link_species_set_id` (`method_link_species_set_id`)
) ENGINE=MyISAM ;

CREATE TABLE `stable_id_history` (
  `mapping_session_id` int(10) unsigned NOT NULL,
  `stable_id_from` varchar(40) NOT NULL DEFAULT '',
  `version_from` int(10) unsigned DEFAULT NULL,
  `stable_id_to` varchar(40) NOT NULL DEFAULT '',
  `version_to` int(10) unsigned DEFAULT NULL,
  `contribution` float DEFAULT NULL,
  PRIMARY KEY (`mapping_session_id`,`stable_id_from`,`stable_id_to`)
) ENGINE=MyISAM ;

CREATE TABLE `subset` (
  `subset_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `description` varchar(255) DEFAULT NULL,
  `dump_loc` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`subset_id`),
  UNIQUE KEY `description` (`description`)
) ENGINE=MyISAM ;

CREATE TABLE `subset_member` (
  `subset_id` int(10) unsigned NOT NULL,
  `member_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`subset_id`,`member_id`),
  KEY `member_id` (`member_id`)
) ENGINE=MyISAM ;

CREATE TABLE `synteny_region` (
  `synteny_region_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`synteny_region_id`),
  KEY `method_link_species_set_id` (`method_link_species_set_id`)
) ENGINE=MyISAM  ;

