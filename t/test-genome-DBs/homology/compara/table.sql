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
) ENGINE=MyISAM AUTO_INCREMENT=100000103 DEFAULT CHARSET=latin1;

CREATE TABLE `CAFE_species_gene` (
  `cafe_gene_family_id` int(10) unsigned NOT NULL,
  `node_id` int(10) unsigned NOT NULL,
  `n_members` int(4) unsigned NOT NULL,
  `pvalue` double(5,4) DEFAULT NULL,
  PRIMARY KEY (`cafe_gene_family_id`,`node_id`),
  KEY `node_id` (`node_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `conservation_score` (
  `genomic_align_block_id` bigint(20) unsigned NOT NULL,
  `window_size` smallint(5) unsigned NOT NULL,
  `position` int(10) unsigned NOT NULL,
  `expected_score` blob,
  `diff_score` blob,
  KEY `genomic_align_block_id` (`genomic_align_block_id`,`window_size`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=15000000 AVG_ROW_LENGTH=841;

CREATE TABLE `constrained_element` (
  `constrained_element_id` bigint(20) unsigned NOT NULL,
  `dnafrag_id` bigint(20) unsigned NOT NULL,
  `dnafrag_start` int(12) unsigned NOT NULL,
  `dnafrag_end` int(12) unsigned NOT NULL,
  `dnafrag_strand` int(2) NOT NULL,
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  `p_value` double NOT NULL DEFAULT '0',
  `score` double NOT NULL DEFAULT '0',
  KEY `dnafrag_id` (`dnafrag_id`),
  KEY `constrained_element_id_idx` (`constrained_element_id`),
  KEY `mlssid_idx` (`method_link_species_set_id`),
  KEY `mlssid_dfId_dfStart_dfEnd_idx` (`method_link_species_set_id`,`dnafrag_id`,`dnafrag_start`,`dnafrag_end`),
  KEY `mlssid_dfId_idx` (`method_link_species_set_id`,`dnafrag_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `dnafrag` (
  `dnafrag_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `length` int(11) NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL DEFAULT '',
  `genome_db_id` int(10) unsigned NOT NULL,
  `coord_system_name` varchar(40) NOT NULL DEFAULT '',
  `cellular_component` enum('NUC','MT','PT') NOT NULL DEFAULT 'NUC',
  `is_reference` tinyint(1) NOT NULL DEFAULT '1',
  `codon_table_id` tinyint(2) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`dnafrag_id`),
  UNIQUE KEY `name` (`genome_db_id`,`name`)
) ENGINE=MyISAM AUTO_INCREMENT=14026981 DEFAULT CHARSET=latin1;

CREATE TABLE `dnafrag_region` (
  `synteny_region_id` int(10) unsigned NOT NULL DEFAULT '0',
  `dnafrag_id` bigint(20) unsigned NOT NULL DEFAULT '0',
  `dnafrag_start` int(10) unsigned NOT NULL DEFAULT '0',
  `dnafrag_end` int(10) unsigned NOT NULL DEFAULT '0',
  `dnafrag_strand` tinyint(4) NOT NULL DEFAULT '0',
  KEY `synteny` (`synteny_region_id`,`dnafrag_id`),
  KEY `synteny_reversed` (`dnafrag_id`,`synteny_region_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `exon_boundaries` (
  `gene_member_id` int(10) unsigned NOT NULL,
  `seq_member_id` int(10) unsigned NOT NULL,
  `dnafrag_start` int(11) NOT NULL,
  `dnafrag_end` int(11) NOT NULL,
  `sequence_length` int(10) unsigned NOT NULL,
  `left_over` tinyint(1) NOT NULL DEFAULT '0',
  KEY `seq_member_id` (`seq_member_id`),
  KEY `gene_member_id` (`gene_member_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `family` (
  `family_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `stable_id` varchar(40) NOT NULL,
  `version` int(10) unsigned NOT NULL,
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  `description` text,
  `description_score` double DEFAULT NULL,
  PRIMARY KEY (`family_id`),
  UNIQUE KEY `stable_id` (`stable_id`),
  KEY `method_link_species_set_id` (`method_link_species_set_id`),
  KEY `description` (`description`(255))
) ENGINE=MyISAM AUTO_INCREMENT=2611 DEFAULT CHARSET=latin1;

CREATE TABLE `family_member` (
  `family_id` int(10) unsigned NOT NULL,
  `seq_member_id` int(10) unsigned NOT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`family_id`,`seq_member_id`),
  KEY `family_id` (`family_id`),
  KEY `seq_member_id` (`seq_member_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `gene_align` (
  `gene_align_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `seq_type` varchar(40) DEFAULT NULL,
  `aln_method` varchar(40) NOT NULL DEFAULT '',
  `aln_length` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`gene_align_id`)
) ENGINE=MyISAM AUTO_INCREMENT=100002018 DEFAULT CHARSET=latin1;

CREATE TABLE `gene_align_member` (
  `gene_align_id` int(10) unsigned NOT NULL,
  `seq_member_id` int(10) unsigned NOT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`gene_align_id`,`seq_member_id`),
  KEY `seq_member_id` (`seq_member_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `gene_member` (
  `gene_member_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `stable_id` varchar(128) NOT NULL,
  `version` int(10) DEFAULT '0',
  `source_name` enum('ENSEMBLGENE','EXTERNALGENE') NOT NULL,
  `taxon_id` int(10) unsigned NOT NULL,
  `genome_db_id` int(10) unsigned DEFAULT NULL,
  `biotype_group` enum('coding','pseudogene','snoncoding','lnoncoding','mnoncoding','LRG','undefined','no_group','current_notdumped','notcurrent') NOT NULL DEFAULT 'coding',
  `canonical_member_id` int(10) unsigned DEFAULT NULL,
  `description` text,
  `dnafrag_id` bigint(20) unsigned DEFAULT NULL,
  `dnafrag_start` int(10) DEFAULT NULL,
  `dnafrag_end` int(10) DEFAULT NULL,
  `dnafrag_strand` tinyint(4) DEFAULT NULL,
  `display_label` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`gene_member_id`),
  UNIQUE KEY `stable_id` (`stable_id`),
  KEY `taxon_id` (`taxon_id`),
  KEY `genome_db_id` (`genome_db_id`),
  KEY `source_name` (`source_name`),
  KEY `canonical_member_id` (`canonical_member_id`),
  KEY `dnafrag_id_start` (`dnafrag_id`,`dnafrag_start`),
  KEY `dnafrag_id_end` (`dnafrag_id`,`dnafrag_end`)
) ENGINE=MyISAM AUTO_INCREMENT=100281325 DEFAULT CHARSET=latin1 MAX_ROWS=100000000;

CREATE TABLE `gene_member_hom_stats` (
  `gene_member_id` int(10) unsigned NOT NULL,
  `collection` varchar(40) NOT NULL,
  `families` int(10) unsigned NOT NULL DEFAULT '0',
  `gene_trees` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `gene_gain_loss_trees` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `orthologues` int(10) unsigned NOT NULL DEFAULT '0',
  `paralogues` int(10) unsigned NOT NULL DEFAULT '0',
  `homoeologues` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`gene_member_id`,`collection`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `gene_member_qc` (
  `gene_member_stable_id` varchar(128) NOT NULL,
  `genome_db_id` int(10) unsigned NOT NULL,
  `seq_member_id` int(10) DEFAULT NULL,
  `n_species` int(11) DEFAULT NULL,
  `n_orth` int(11) DEFAULT NULL,
  `avg_cov` float DEFAULT NULL,
  `status` varchar(50) NOT NULL,
  KEY `genome_db_id` (`genome_db_id`),
  KEY `gene_member_stable_id` (`gene_member_stable_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `gene_tree_node` (
  `node_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` int(10) unsigned DEFAULT NULL,
  `root_id` int(10) unsigned DEFAULT NULL,
  `left_index` int(10) NOT NULL DEFAULT '0',
  `right_index` int(10) NOT NULL DEFAULT '0',
  `distance_to_parent` double NOT NULL DEFAULT '1',
  `seq_member_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`node_id`),
  KEY `parent_id` (`parent_id`),
  KEY `seq_member_id` (`seq_member_id`),
  KEY `root_id` (`root_id`),
  KEY `root_id_left_index` (`root_id`,`left_index`)
) ENGINE=MyISAM AUTO_INCREMENT=100462681 DEFAULT CHARSET=latin1;

CREATE TABLE `gene_tree_node_attr` (
  `node_id` int(10) unsigned NOT NULL,
  `node_type` enum('duplication','dubious','speciation','gene_split') DEFAULT NULL,
  `species_tree_node_id` int(10) unsigned DEFAULT NULL,
  `bootstrap` tinyint(3) unsigned DEFAULT NULL,
  `duplication_confidence_score` double(5,4) DEFAULT NULL,
  PRIMARY KEY (`node_id`),
  KEY `species_tree_node_id` (`species_tree_node_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `gene_tree_node_tag` (
  `node_id` int(10) unsigned NOT NULL,
  `tag` varchar(50) NOT NULL,
  `value` mediumtext NOT NULL,
  KEY `node_id_tag` (`node_id`,`tag`),
  KEY `tag` (`tag`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `gene_tree_object_store` (
  `root_id` int(10) unsigned NOT NULL,
  `data_label` varchar(255) NOT NULL,
  `compressed_data` mediumblob NOT NULL,
  PRIMARY KEY (`root_id`,`data_label`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `gene_tree_root` (
  `root_id` int(10) unsigned NOT NULL,
  `member_type` enum('protein','ncrna') NOT NULL,
  `tree_type` enum('clusterset','supertree','tree') NOT NULL,
  `clusterset_id` varchar(20) NOT NULL DEFAULT 'default',
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  `species_tree_root_id` int(10) unsigned DEFAULT NULL,
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `gene_tree_root_attr` (
  `root_id` int(10) unsigned NOT NULL,
  `aln_after_filter_length` int(10) unsigned DEFAULT NULL,
  `aln_length` int(10) unsigned DEFAULT NULL,
  `aln_num_residues` int(10) unsigned DEFAULT NULL,
  `aln_percent_identity` float DEFAULT NULL,
  `best_fit_model_family` varchar(10) DEFAULT NULL,
  `best_fit_model_parameter` varchar(5) DEFAULT NULL,
  `gene_count` int(10) unsigned DEFAULT NULL,
  `k_score` float DEFAULT NULL,
  `k_score_rank` int(10) unsigned DEFAULT NULL,
  `mcoffee_scores_gene_align_id` int(10) unsigned DEFAULT NULL,
  `aln_n_removed_columns` int(10) unsigned DEFAULT NULL,
  `aln_num_of_patterns` int(10) unsigned DEFAULT NULL,
  `aln_shrinking_factor` float DEFAULT NULL,
  `spec_count` int(10) unsigned DEFAULT NULL,
  `tree_max_branch` float DEFAULT NULL,
  `tree_max_length` float DEFAULT NULL,
  `tree_num_dup_nodes` int(10) unsigned DEFAULT NULL,
  `tree_num_leaves` int(10) unsigned DEFAULT NULL,
  `tree_num_spec_nodes` int(10) unsigned DEFAULT NULL,
  `lca_node_id` int(10) unsigned DEFAULT NULL,
  `taxonomic_coverage` float DEFAULT NULL,
  `ratio_species_genes` float DEFAULT NULL,
  `model_name` varchar(40) DEFAULT NULL,
  `division` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`root_id`),
  KEY `lca_node_id` (`lca_node_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `gene_tree_root_tag` (
  `root_id` int(10) unsigned NOT NULL,
  `tag` varchar(50) NOT NULL,
  `value` mediumtext NOT NULL,
  KEY `root_id_tag` (`root_id`,`tag`),
  KEY `root_id` (`root_id`),
  KEY `tag` (`tag`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `genome_db` (
  `genome_db_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `taxon_id` int(10) unsigned DEFAULT NULL,
  `name` varchar(128) NOT NULL DEFAULT '',
  `assembly` varchar(100) NOT NULL DEFAULT '',
  `genebuild` varchar(100) NOT NULL DEFAULT '',
  `has_karyotype` tinyint(1) NOT NULL DEFAULT '0',
  `is_high_coverage` tinyint(1) NOT NULL DEFAULT '0',
  `genome_component` varchar(5) DEFAULT NULL,
  `strain_name` varchar(40) DEFAULT NULL,
  `display_name` varchar(255) DEFAULT NULL,
  `locator` varchar(400) DEFAULT NULL,
  `first_release` smallint(6) DEFAULT NULL,
  `last_release` smallint(6) DEFAULT NULL,
  PRIMARY KEY (`genome_db_id`),
  UNIQUE KEY `name` (`name`,`assembly`,`genome_component`),
  KEY `taxon_id` (`taxon_id`)
) ENGINE=MyISAM AUTO_INCREMENT=175 DEFAULT CHARSET=latin1;

CREATE TABLE `genomic_align` (
  `genomic_align_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `genomic_align_block_id` bigint(20) unsigned NOT NULL,
  `method_link_species_set_id` int(10) unsigned NOT NULL DEFAULT '0',
  `dnafrag_id` bigint(20) unsigned NOT NULL DEFAULT '0',
  `dnafrag_start` int(10) NOT NULL DEFAULT '0',
  `dnafrag_end` int(10) NOT NULL DEFAULT '0',
  `dnafrag_strand` tinyint(4) NOT NULL DEFAULT '0',
  `cigar_line` mediumtext NOT NULL,
  `visible` tinyint(2) unsigned NOT NULL DEFAULT '1',
  `node_id` bigint(20) unsigned DEFAULT NULL,
  PRIMARY KEY (`genomic_align_id`),
  KEY `genomic_align_block_id` (`genomic_align_block_id`),
  KEY `method_link_species_set_id` (`method_link_species_set_id`),
  KEY `dnafrag` (`dnafrag_id`,`method_link_species_set_id`,`dnafrag_start`,`dnafrag_end`),
  KEY `node_id` (`node_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=1000000000 AVG_ROW_LENGTH=60;

CREATE TABLE `genomic_align_block` (
  `genomic_align_block_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `method_link_species_set_id` int(10) unsigned NOT NULL DEFAULT '0',
  `score` double DEFAULT NULL,
  `perc_id` tinyint(3) unsigned DEFAULT NULL,
  `length` int(10) NOT NULL,
  `group_id` bigint(20) unsigned DEFAULT NULL,
  `level_id` tinyint(2) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`genomic_align_block_id`),
  KEY `method_link_species_set_id` (`method_link_species_set_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `genomic_align_tree` (
  `node_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` bigint(20) unsigned DEFAULT NULL,
  `root_id` bigint(20) unsigned NOT NULL DEFAULT '0',
  `left_index` int(10) NOT NULL DEFAULT '0',
  `right_index` int(10) NOT NULL DEFAULT '0',
  `left_node_id` bigint(10) DEFAULT NULL,
  `right_node_id` bigint(10) DEFAULT NULL,
  `distance_to_parent` double NOT NULL DEFAULT '1',
  PRIMARY KEY (`node_id`),
  KEY `parent_id` (`parent_id`),
  KEY `root_id` (`root_id`),
  KEY `left_index` (`root_id`,`left_index`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `hmm_annot` (
  `seq_member_id` int(10) unsigned NOT NULL,
  `model_id` varchar(40) DEFAULT NULL,
  `evalue` float DEFAULT NULL,
  PRIMARY KEY (`seq_member_id`),
  KEY `model_id` (`model_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `hmm_curated_annot` (
  `seq_member_stable_id` varchar(40) NOT NULL,
  `model_id` varchar(40) DEFAULT NULL,
  `library_version` varchar(40) NOT NULL,
  `annot_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reason` mediumtext,
  PRIMARY KEY (`seq_member_stable_id`),
  KEY `model_id` (`model_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `hmm_profile` (
  `model_id` varchar(40) NOT NULL,
  `name` varchar(40) DEFAULT NULL,
  `type` varchar(40) NOT NULL,
  `compressed_profile` mediumblob,
  `consensus` mediumtext,
  PRIMARY KEY (`model_id`,`type`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `homology` (
  `homology_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  `description` enum('ortholog_one2one','ortholog_one2many','ortholog_many2many','within_species_paralog','other_paralog','gene_split','between_species_paralog','alt_allele','homoeolog_one2one','homoeolog_one2many','homoeolog_many2many') DEFAULT NULL,
  `is_tree_compliant` tinyint(1) NOT NULL DEFAULT '0',
  `dn` float(10,5) DEFAULT NULL,
  `ds` float(10,5) DEFAULT NULL,
  `n` float(10,1) DEFAULT NULL,
  `s` float(10,1) DEFAULT NULL,
  `lnl` float(10,3) DEFAULT NULL,
  `species_tree_node_id` int(10) unsigned DEFAULT NULL,
  `gene_tree_node_id` int(10) unsigned DEFAULT NULL,
  `gene_tree_root_id` int(10) unsigned DEFAULT NULL,
  `goc_score` tinyint(3) unsigned DEFAULT NULL,
  `wga_coverage` decimal(5,2) DEFAULT NULL,
  `is_high_confidence` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`homology_id`),
  KEY `method_link_species_set_id` (`method_link_species_set_id`),
  KEY `species_tree_node_id` (`species_tree_node_id`),
  KEY `gene_tree_node_id` (`gene_tree_node_id`),
  KEY `gene_tree_root_id` (`gene_tree_root_id`)
) ENGINE=MyISAM AUTO_INCREMENT=100990070 DEFAULT CHARSET=latin1;

CREATE TABLE `homology_member` (
  `homology_id` int(10) unsigned NOT NULL,
  `gene_member_id` int(10) unsigned NOT NULL,
  `seq_member_id` int(10) unsigned DEFAULT NULL,
  `cigar_line` mediumtext,
  `perc_cov` float unsigned DEFAULT '0',
  `perc_id` float unsigned DEFAULT '0',
  `perc_pos` float unsigned DEFAULT '0',
  PRIMARY KEY (`homology_id`,`gene_member_id`),
  KEY `homology_id` (`homology_id`),
  KEY `gene_member_id` (`gene_member_id`),
  KEY `seq_member_id` (`seq_member_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=300000000;

CREATE TABLE `mapping_session` (
  `mapping_session_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type` enum('family','tree') DEFAULT NULL,
  `when_mapped` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `rel_from` int(10) unsigned DEFAULT NULL,
  `rel_to` int(10) unsigned DEFAULT NULL,
  `prefix` char(4) NOT NULL,
  PRIMARY KEY (`mapping_session_id`),
  UNIQUE KEY `type` (`type`,`rel_from`,`rel_to`,`prefix`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `member_xref` (
  `gene_member_id` int(10) unsigned NOT NULL,
  `dbprimary_acc` varchar(10) NOT NULL,
  `external_db_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`gene_member_id`,`dbprimary_acc`,`external_db_id`),
  KEY `external_db_id` (`external_db_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `meta` (
  `meta_id` int(11) NOT NULL AUTO_INCREMENT,
  `species_id` int(10) unsigned DEFAULT '1',
  `meta_key` varchar(40) NOT NULL,
  `meta_value` text NOT NULL,
  PRIMARY KEY (`meta_id`),
  UNIQUE KEY `species_key_value_idx` (`species_id`,`meta_key`,`meta_value`(255)),
  KEY `species_value_idx` (`species_id`,`meta_value`(255))
) ENGINE=MyISAM AUTO_INCREMENT=51 DEFAULT CHARSET=latin1;

CREATE TABLE `method_link` (
  `method_link_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(50) NOT NULL DEFAULT '',
  `class` varchar(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`method_link_id`),
  UNIQUE KEY `type` (`type`)
) ENGINE=MyISAM AUTO_INCREMENT=403 DEFAULT CHARSET=latin1;

CREATE TABLE `method_link_species_set` (
  `method_link_species_set_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `method_link_id` int(10) unsigned NOT NULL,
  `species_set_id` int(10) unsigned NOT NULL,
  `name` varchar(255) NOT NULL DEFAULT '',
  `source` varchar(255) NOT NULL DEFAULT 'ensembl',
  `url` varchar(255) NOT NULL DEFAULT '',
  `first_release` smallint(6) DEFAULT NULL,
  `last_release` smallint(6) DEFAULT NULL,
  PRIMARY KEY (`method_link_species_set_id`),
  UNIQUE KEY `method_link_id` (`method_link_id`,`species_set_id`),
  KEY `species_set_id` (`species_set_id`)
) ENGINE=MyISAM AUTO_INCREMENT=100070 DEFAULT CHARSET=latin1;

CREATE TABLE `method_link_species_set_attr` (
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  `n_goc_null` int(11) DEFAULT NULL,
  `n_goc_0` int(11) DEFAULT NULL,
  `n_goc_25` int(11) DEFAULT NULL,
  `n_goc_50` int(11) DEFAULT NULL,
  `n_goc_75` int(11) DEFAULT NULL,
  `n_goc_100` int(11) DEFAULT NULL,
  `perc_orth_above_goc_thresh` float DEFAULT NULL,
  `goc_quality_threshold` int(11) DEFAULT NULL,
  `wga_quality_threshold` int(11) DEFAULT NULL,
  `perc_orth_above_wga_thresh` float DEFAULT NULL,
  `threshold_on_ds` int(11) DEFAULT NULL,
  PRIMARY KEY (`method_link_species_set_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `method_link_species_set_tag` (
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  `tag` varchar(50) NOT NULL,
  `value` mediumtext NOT NULL,
  PRIMARY KEY (`method_link_species_set_id`,`tag`),
  KEY `tag` (`tag`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `ncbi_taxa_name` (
  `taxon_id` int(10) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `name_class` varchar(50) NOT NULL,
  KEY `taxon_id` (`taxon_id`),
  KEY `name` (`name`),
  KEY `name_class` (`name_class`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `other_member_sequence` (
  `seq_member_id` int(10) unsigned NOT NULL,
  `seq_type` varchar(40) NOT NULL,
  `length` int(10) NOT NULL,
  `sequence` mediumtext NOT NULL,
  PRIMARY KEY (`seq_member_id`,`seq_type`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=10000000 AVG_ROW_LENGTH=60000;

CREATE TABLE `peptide_align_feature` (
  `peptide_align_feature_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `qmember_id` int(10) unsigned NOT NULL,
  `hmember_id` int(10) unsigned NOT NULL,
  `qgenome_db_id` int(10) unsigned DEFAULT NULL,
  `hgenome_db_id` int(10) unsigned DEFAULT NULL,
  `qstart` int(10) NOT NULL DEFAULT '0',
  `qend` int(10) NOT NULL DEFAULT '0',
  `hstart` int(11) NOT NULL DEFAULT '0',
  `hend` int(11) NOT NULL DEFAULT '0',
  `score` double(16,4) NOT NULL DEFAULT '0.0000',
  `evalue` double NOT NULL,
  `align_length` int(10) NOT NULL,
  `identical_matches` int(10) NOT NULL,
  `perc_ident` int(10) NOT NULL,
  `positive_matches` int(10) NOT NULL,
  `perc_pos` int(10) NOT NULL,
  `hit_rank` int(10) NOT NULL,
  `cigar_line` mediumtext,
  PRIMARY KEY (`peptide_align_feature_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=100000000 AVG_ROW_LENGTH=133;

CREATE TABLE `seq_member` (
  `seq_member_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `stable_id` varchar(128) NOT NULL,
  `version` int(10) DEFAULT '0',
  `source_name` enum('ENSEMBLPEP','ENSEMBLTRANS','Uniprot/SPTREMBL','Uniprot/SWISSPROT','EXTERNALPEP','EXTERNALTRANS','EXTERNALCDS') NOT NULL,
  `taxon_id` int(10) unsigned NOT NULL,
  `genome_db_id` int(10) unsigned DEFAULT NULL,
  `sequence_id` int(10) unsigned DEFAULT NULL,
  `gene_member_id` int(10) unsigned DEFAULT NULL,
  `has_transcript_edits` tinyint(1) NOT NULL DEFAULT '0',
  `has_translation_edits` tinyint(1) NOT NULL DEFAULT '0',
  `description` text,
  `dnafrag_id` bigint(20) unsigned DEFAULT NULL,
  `dnafrag_start` int(10) DEFAULT NULL,
  `dnafrag_end` int(10) DEFAULT NULL,
  `dnafrag_strand` tinyint(4) DEFAULT NULL,
  `display_label` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`seq_member_id`),
  UNIQUE KEY `stable_id` (`stable_id`),
  KEY `taxon_id` (`taxon_id`),
  KEY `genome_db_id` (`genome_db_id`),
  KEY `source_name` (`source_name`),
  KEY `sequence_id` (`sequence_id`),
  KEY `gene_member_id` (`gene_member_id`),
  KEY `dnafrag_id_start` (`dnafrag_id`,`dnafrag_start`),
  KEY `dnafrag_id_end` (`dnafrag_id`,`dnafrag_end`),
  KEY `seq_member_gene_member_id_end` (`seq_member_id`,`gene_member_id`)
) ENGINE=MyISAM AUTO_INCREMENT=100289438 DEFAULT CHARSET=latin1 MAX_ROWS=100000000;

CREATE TABLE `seq_member_projection` (
  `target_seq_member_id` int(10) unsigned NOT NULL,
  `source_seq_member_id` int(10) unsigned NOT NULL,
  `identity` float(5,2) DEFAULT NULL,
  PRIMARY KEY (`target_seq_member_id`),
  KEY `source_seq_member_id` (`source_seq_member_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `seq_member_projection_stable_id` (
  `target_seq_member_id` int(10) unsigned NOT NULL,
  `source_stable_id` varchar(128) NOT NULL,
  PRIMARY KEY (`target_seq_member_id`),
  KEY `source_stable_id` (`source_stable_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `sequence` (
  `sequence_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `length` int(10) NOT NULL,
  `md5sum` char(32) NOT NULL,
  `sequence` longtext NOT NULL,
  PRIMARY KEY (`sequence_id`),
  KEY `md5sum` (`md5sum`)
) ENGINE=MyISAM AUTO_INCREMENT=100259313 DEFAULT CHARSET=latin1 MAX_ROWS=10000000 AVG_ROW_LENGTH=19000;

CREATE TABLE `species_set` (
  `species_set_id` int(10) unsigned NOT NULL,
  `genome_db_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`species_set_id`,`genome_db_id`),
  KEY `genome_db_id` (`genome_db_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `species_set_header` (
  `species_set_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `size` int(10) unsigned NOT NULL,
  `first_release` smallint(6) DEFAULT NULL,
  `last_release` smallint(6) DEFAULT NULL,
  PRIMARY KEY (`species_set_id`)
) ENGINE=MyISAM AUTO_INCREMENT=36208 DEFAULT CHARSET=latin1;

CREATE TABLE `species_set_tag` (
  `species_set_id` int(10) unsigned NOT NULL,
  `tag` varchar(50) NOT NULL,
  `value` mediumtext NOT NULL,
  PRIMARY KEY (`species_set_id`,`tag`),
  KEY `tag` (`tag`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `species_tree_node` (
  `node_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` int(10) unsigned DEFAULT NULL,
  `root_id` int(10) unsigned DEFAULT NULL,
  `left_index` int(10) NOT NULL DEFAULT '0',
  `right_index` int(10) NOT NULL DEFAULT '0',
  `distance_to_parent` double DEFAULT '1',
  `taxon_id` int(10) unsigned DEFAULT NULL,
  `genome_db_id` int(10) unsigned DEFAULT NULL,
  `node_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`node_id`),
  KEY `taxon_id` (`taxon_id`),
  KEY `genome_db_id` (`genome_db_id`),
  KEY `parent_id` (`parent_id`),
  KEY `root_id` (`root_id`,`left_index`)
) ENGINE=MyISAM AUTO_INCREMENT=40102221 DEFAULT CHARSET=latin1;

CREATE TABLE `species_tree_node_attr` (
  `node_id` int(10) unsigned NOT NULL,
  `nb_long_genes` int(11) DEFAULT NULL,
  `nb_short_genes` int(11) DEFAULT NULL,
  `avg_dupscore` float DEFAULT NULL,
  `avg_dupscore_nondub` float DEFAULT NULL,
  `nb_dubious_nodes` int(11) DEFAULT NULL,
  `nb_dup_nodes` int(11) DEFAULT NULL,
  `nb_genes` int(11) DEFAULT NULL,
  `nb_genes_in_tree` int(11) DEFAULT NULL,
  `nb_genes_in_tree_multi_species` int(11) DEFAULT NULL,
  `nb_genes_in_tree_single_species` int(11) DEFAULT NULL,
  `nb_nodes` int(11) DEFAULT NULL,
  `nb_orphan_genes` int(11) DEFAULT NULL,
  `nb_seq` int(11) DEFAULT NULL,
  `nb_spec_nodes` int(11) DEFAULT NULL,
  `nb_gene_splits` int(11) DEFAULT NULL,
  `nb_split_genes` int(11) DEFAULT NULL,
  `root_avg_gene` float DEFAULT NULL,
  `root_avg_gene_per_spec` float DEFAULT NULL,
  `root_avg_spec` float DEFAULT NULL,
  `root_max_gene` int(11) DEFAULT NULL,
  `root_max_spec` int(11) DEFAULT NULL,
  `root_min_gene` int(11) DEFAULT NULL,
  `root_min_spec` int(11) DEFAULT NULL,
  `root_nb_genes` int(11) DEFAULT NULL,
  `root_nb_trees` int(11) DEFAULT NULL,
  PRIMARY KEY (`node_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `species_tree_node_tag` (
  `node_id` int(10) unsigned NOT NULL,
  `tag` varchar(50) NOT NULL,
  `value` mediumtext NOT NULL,
  KEY `node_id_tag` (`node_id`,`tag`),
  KEY `tag` (`tag`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `species_tree_root` (
  `root_id` int(10) unsigned NOT NULL,
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  `label` varchar(256) NOT NULL DEFAULT 'default',
  PRIMARY KEY (`root_id`),
  UNIQUE KEY `method_link_species_set_id` (`method_link_species_set_id`,`label`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `stable_id_history` (
  `mapping_session_id` int(10) unsigned NOT NULL,
  `stable_id_from` varchar(40) NOT NULL DEFAULT '',
  `version_from` int(10) unsigned DEFAULT NULL,
  `stable_id_to` varchar(40) NOT NULL DEFAULT '',
  `version_to` int(10) unsigned DEFAULT NULL,
  `contribution` float DEFAULT NULL,
  PRIMARY KEY (`mapping_session_id`,`stable_id_from`,`stable_id_to`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `synteny_region` (
  `synteny_region_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `method_link_species_set_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`synteny_region_id`),
  KEY `method_link_species_set_id` (`method_link_species_set_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

