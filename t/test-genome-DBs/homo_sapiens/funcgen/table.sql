-- MySQL dump 10.13  Distrib 5.6.36-82.1, for Linux (x86_64)
--
-- Host: mysql-ens-reg-prod-1.ebi.ac.uk    Database: homo_sapiens_funcgen_91_38
-- ------------------------------------------------------
-- Server version	5.6.33

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
/*!50112 SELECT COUNT(*) INTO @is_rocksdb_supported FROM INFORMATION_SCHEMA.SESSION_VARIABLES WHERE VARIABLE_NAME='rocksdb_bulk_load' */;
/*!50112 SET @save_old_rocksdb_bulk_load = IF (@is_rocksdb_supported, 'SET @old_rocksdb_bulk_load = @@rocksdb_bulk_load', 'SET @dummy_old_rocksdb_bulk_load = 0') */;
/*!50112 PREPARE s FROM @save_old_rocksdb_bulk_load */;
/*!50112 EXECUTE s */;
/*!50112 SET @enable_bulk_load = IF (@is_rocksdb_supported, 'SET SESSION rocksdb_bulk_load = 1', 'SET @dummy_rocksdb_bulk_load = 0') */;
/*!50112 PREPARE s FROM @enable_bulk_load */;
/*!50112 EXECUTE s */;
/*!50112 DEALLOCATE PREPARE s */;

--
-- Table structure for table `MTMP_probestuff_helper`
--

DROP TABLE IF EXISTS `MTMP_probestuff_helper`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `MTMP_probestuff_helper` (
  `array_name` varchar(40) DEFAULT NULL,
  `transcript_stable_id` varchar(128) DEFAULT NULL,
  `display_label` varchar(100) DEFAULT NULL,
  `array_vendor_and_name` varchar(80) DEFAULT NULL,
  `is_probeset_array` tinyint(1) DEFAULT NULL,
  KEY `transcript_idx` (`transcript_stable_id`),
  KEY `vendor_name_idx` (`array_vendor_and_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `alignment`
--

DROP TABLE IF EXISTS `alignment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `alignment` (
  `alignment_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `analysis_id` smallint(5) unsigned NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `bam_file_id` int(11) DEFAULT NULL,
  `bigwig_file_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`alignment_id`),
  UNIQUE KEY `name_idx` (`name`),
  KEY `analysis_idx` (`analysis_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2471 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `alignment_qc_chance`
--

DROP TABLE IF EXISTS `alignment_qc_chance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `alignment_qc_chance` (
  `alignment_qc_chance` int(10) unsigned NOT NULL,
  `signal_alignment_id` int(10) unsigned NOT NULL,
  `analysis_id` smallint(5) unsigned DEFAULT NULL,
  `p` double DEFAULT NULL,
  `q` double DEFAULT NULL,
  `divergence` double DEFAULT NULL,
  `z_score` double DEFAULT NULL,
  `percent_genome_enriched` double DEFAULT NULL,
  `input_scaling_factor` double DEFAULT NULL,
  `differential_percentage_enrichment` double DEFAULT NULL,
  `control_enrichment_stronger_than_chip_at_bin` double DEFAULT NULL,
  `first_nonzero_bin_at` double DEFAULT NULL,
  `pcr_amplification_bias_in_Input_coverage_of_1_percent_of_genome` double DEFAULT NULL,
  `path` varchar(512) NOT NULL,
  PRIMARY KEY (`alignment_qc_chance`)
) ENGINE=MyISAM AUTO_INCREMENT=527 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `alignment_qc_flagstats`
--

DROP TABLE IF EXISTS `alignment_qc_flagstats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `alignment_qc_flagstats` (
  `alignment_qc_flagstats_id` int(10) unsigned NOT NULL,
  `alignment_id` int(10) unsigned NOT NULL,
  `analysis_id` smallint(5) unsigned DEFAULT NULL,
  `category` varchar(100) NOT NULL,
  `qc_passed_reads` int(10) unsigned DEFAULT NULL,
  `qc_failed_reads` int(10) unsigned DEFAULT NULL,
  `path` varchar(512) NOT NULL,
  `bam_file` varchar(512) NOT NULL,
  PRIMARY KEY (`alignment_qc_flagstats_id`),
  UNIQUE KEY `name_exp_idx` (`alignment_qc_flagstats_id`,`category`)
) ENGINE=MyISAM AUTO_INCREMENT=24805 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `alignment_qc_phantom_peak`
--

DROP TABLE IF EXISTS `alignment_qc_phantom_peak`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `alignment_qc_phantom_peak` (
  `alignment_qc_phantom_peak_id` int(10) unsigned NOT NULL,
  `analysis_id` smallint(5) unsigned DEFAULT NULL,
  `alignment_id` int(10) unsigned NOT NULL,
  `filename` varchar(512) NOT NULL,
  `numReads` int(10) unsigned NOT NULL,
  `estFragLen` double DEFAULT NULL,
  `estFragLen2` double DEFAULT NULL,
  `estFragLen3` double DEFAULT NULL,
  `corr_estFragLen` double DEFAULT NULL,
  `corr_estFragLen2` double DEFAULT NULL,
  `corr_estFragLen3` double DEFAULT NULL,
  `phantomPeak` int(10) unsigned NOT NULL,
  `corr_phantomPeak` double DEFAULT NULL,
  `argmin_corr` int(10) DEFAULT NULL,
  `min_corr` double DEFAULT NULL,
  `NSC` double DEFAULT NULL,
  `RSC` double DEFAULT NULL,
  `QualityTag` int(10) DEFAULT NULL,
  `path` varchar(512) NOT NULL,
  PRIMARY KEY (`alignment_qc_phantom_peak_id`),
  KEY `filename_idx` (`filename`)
) ENGINE=MyISAM AUTO_INCREMENT=2430 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `alignment_read_file`
--

DROP TABLE IF EXISTS `alignment_read_file`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `alignment_read_file` (
  `alignment_read_file_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `alignment_id` int(10) unsigned NOT NULL,
  `read_file_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`alignment_read_file_id`,`alignment_id`),
  UNIQUE KEY `rset_table_idname_idx` (`alignment_id`,`read_file_id`)
) ENGINE=MyISAM AUTO_INCREMENT=23390 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `analysis`
--

DROP TABLE IF EXISTS `analysis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `analysis` (
  `analysis_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `logic_name` varchar(100) NOT NULL,
  `db` varchar(120) DEFAULT NULL,
  `db_version` varchar(40) DEFAULT NULL,
  `db_file` varchar(120) DEFAULT NULL,
  `program` varchar(80) DEFAULT NULL,
  `program_version` varchar(40) DEFAULT NULL,
  `program_file` varchar(80) DEFAULT NULL,
  `parameters` text,
  `module` varchar(80) DEFAULT NULL,
  `module_version` varchar(40) DEFAULT NULL,
  `gff_source` varchar(40) DEFAULT NULL,
  `gff_feature` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`analysis_id`),
  UNIQUE KEY `logic_name_idx` (`logic_name`)
) ENGINE=MyISAM AUTO_INCREMENT=126 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `analysis_description`
--

DROP TABLE IF EXISTS `analysis_description`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `analysis_description` (
  `analysis_id` smallint(5) unsigned NOT NULL,
  `description` text,
  `display_label` varchar(255) NOT NULL,
  `displayable` tinyint(1) NOT NULL DEFAULT '1',
  `web_data` text,
  UNIQUE KEY `analysis_idx` (`analysis_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `array`
--

DROP TABLE IF EXISTS `array`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `array` (
  `array_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(40) DEFAULT NULL,
  `format` varchar(20) DEFAULT NULL,
  `vendor` varchar(40) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `type` varchar(20) DEFAULT NULL,
  `class` varchar(20) DEFAULT NULL,
  `is_probeset_array` tinyint(1) NOT NULL DEFAULT '0',
  `is_linked_array` tinyint(1) NOT NULL DEFAULT '0',
  `has_sense_interrogation` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`array_id`),
  UNIQUE KEY `vendor_name_idx` (`vendor`,`name`),
  UNIQUE KEY `class_name_idx` (`class`,`name`)
) ENGINE=MyISAM AUTO_INCREMENT=35 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `array_chip`
--

DROP TABLE IF EXISTS `array_chip`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `array_chip` (
  `array_chip_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `design_id` varchar(100) DEFAULT NULL,
  `array_id` int(10) unsigned NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`array_chip_id`),
  UNIQUE KEY `array_design_idx` (`array_id`,`design_id`)
) ENGINE=MyISAM AUTO_INCREMENT=35 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `associated_feature_type`
--

DROP TABLE IF EXISTS `associated_feature_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `associated_feature_type` (
  `table_id` int(10) unsigned NOT NULL,
  `table_name` enum('annotated_feature','external_feature','regulatory_feature','feature_type') NOT NULL,
  `feature_type_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`table_id`,`table_name`,`feature_type_id`),
  KEY `feature_type_index` (`feature_type_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `associated_group`
--

DROP TABLE IF EXISTS `associated_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `associated_group` (
  `associated_group_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `description` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`associated_group_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `associated_motif_feature`
--

DROP TABLE IF EXISTS `associated_motif_feature`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `associated_motif_feature` (
  `annotated_feature_id` int(10) unsigned NOT NULL,
  `motif_feature_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`annotated_feature_id`,`motif_feature_id`),
  KEY `motif_feature_idx` (`motif_feature_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `associated_xref`
--

DROP TABLE IF EXISTS `associated_xref`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `associated_xref` (
  `associated_xref_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `object_xref_id` int(10) unsigned NOT NULL DEFAULT '0',
  `xref_id` int(10) unsigned NOT NULL DEFAULT '0',
  `source_xref_id` int(10) unsigned DEFAULT NULL,
  `condition_type` varchar(128) DEFAULT NULL,
  `associated_group_id` int(10) unsigned DEFAULT NULL,
  `rank` int(10) unsigned DEFAULT '0',
  PRIMARY KEY (`associated_xref_id`),
  UNIQUE KEY `object_associated_source_type_idx` (`object_xref_id`,`xref_id`,`source_xref_id`,`condition_type`,`associated_group_id`),
  KEY `associated_source_idx` (`source_xref_id`),
  KEY `associated_object_idx` (`object_xref_id`),
  KEY `associated_idx` (`xref_id`),
  KEY `associated_group_idx` (`associated_group_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `binding_matrix`
--

DROP TABLE IF EXISTS `binding_matrix`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `binding_matrix` (
  `binding_matrix_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(45) NOT NULL,
  `feature_type_id` int(10) unsigned NOT NULL,
  `frequencies` varchar(1000) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `analysis_id` smallint(5) unsigned NOT NULL,
  `threshold` double DEFAULT NULL,
  PRIMARY KEY (`binding_matrix_id`),
  UNIQUE KEY `name_analysis_idx` (`name`,`analysis_id`),
  KEY `feature_type_idx` (`feature_type_id`)
) ENGINE=MyISAM AUTO_INCREMENT=196 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `data_file`
--

DROP TABLE IF EXISTS `data_file`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `data_file` (
  `data_file_id` int(11) NOT NULL AUTO_INCREMENT,
  `table_id` int(10) unsigned NOT NULL,
  `table_name` varchar(32) NOT NULL,
  `path` varchar(255) NOT NULL,
  `file_type` enum('BAM','BAMCOV','BIGBED','BIGWIG','VCF','CRAM','DIR') NOT NULL DEFAULT 'BAM',
  `md5sum` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`data_file_id`),
  UNIQUE KEY `table_id_name_path_idx` (`table_id`,`table_name`,`path`),
  UNIQUE KEY `data_file_id` (`data_file_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2866 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `epigenome`
--

DROP TABLE IF EXISTS `epigenome`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `epigenome` (
  `epigenome_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(120) NOT NULL,
  `display_label` varchar(30) NOT NULL,
  `description` varchar(80) DEFAULT NULL,
  `production_name` varchar(120) DEFAULT NULL,
  `gender` enum('male','female','hermaphrodite','mixed','unknown') DEFAULT 'unknown',
  `ontology_accession` varchar(20) DEFAULT NULL,
  `ontology` enum('EFO','CL') DEFAULT NULL,
  `tissue` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`epigenome_id`),
  UNIQUE KEY `name_idx` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=126 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `experiment`
--

DROP TABLE IF EXISTS `experiment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `experiment` (
  `experiment_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) DEFAULT NULL,
  `experimental_group_id` smallint(6) unsigned DEFAULT NULL,
  `control_id` int(10) unsigned DEFAULT NULL,
  `is_control` tinyint(3) unsigned DEFAULT '0',
  `feature_type_id` int(10) unsigned NOT NULL,
  `epigenome_id` int(10) unsigned DEFAULT NULL,
  `archive_id` varchar(60) DEFAULT NULL,
  PRIMARY KEY (`experiment_id`),
  UNIQUE KEY `name_idx` (`name`),
  KEY `experimental_group_idx` (`experimental_group_id`),
  KEY `feature_type_idx` (`feature_type_id`),
  KEY `epigenome_idx` (`epigenome_id`)
) ENGINE=MyISAM AUTO_INCREMENT=1151 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `experimental_group`
--

DROP TABLE IF EXISTS `experimental_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `experimental_group` (
  `experimental_group_id` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(40) NOT NULL,
  `location` varchar(120) DEFAULT NULL,
  `contact` varchar(40) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `is_project` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`experimental_group_id`),
  UNIQUE KEY `name_idx` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `external_db`
--

DROP TABLE IF EXISTS `external_db`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `external_db` (
  `external_db_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `db_name` varchar(100) NOT NULL,
  `db_release` varchar(255) DEFAULT NULL,
  `status` enum('KNOWNXREF','KNOWN','XREF','PRED','ORTH','PSEUDO') NOT NULL,
  `dbprimary_acc_linkable` tinyint(1) NOT NULL DEFAULT '1',
  `priority` int(11) NOT NULL,
  `db_display_name` varchar(255) DEFAULT NULL,
  `type` enum('ARRAY','ALT_TRANS','MISC','LIT','PRIMARY_DB_SYNONYM','ENSEMBL') DEFAULT NULL,
  `secondary_db_name` varchar(255) DEFAULT NULL,
  `secondary_db_table` varchar(255) DEFAULT NULL,
  `description` text,
  PRIMARY KEY (`external_db_id`),
  UNIQUE KEY `db_name_release_idx` (`db_name`,`db_release`)
) ENGINE=MyISAM AUTO_INCREMENT=50834 DEFAULT CHARSET=latin1 AVG_ROW_LENGTH=80;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `external_feature`
--

DROP TABLE IF EXISTS `external_feature`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `external_feature` (
  `external_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `seq_region_id` int(10) unsigned NOT NULL,
  `seq_region_start` int(10) unsigned NOT NULL,
  `seq_region_end` int(10) unsigned NOT NULL,
  `seq_region_strand` tinyint(1) NOT NULL,
  `display_label` varchar(60) DEFAULT NULL,
  `feature_type_id` int(10) unsigned DEFAULT NULL,
  `feature_set_id` int(10) unsigned NOT NULL,
  `interdb_stable_id` mediumint(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`external_feature_id`),
  UNIQUE KEY `interdb_stable_id_idx` (`interdb_stable_id`),
  KEY `feature_type_idx` (`feature_type_id`),
  KEY `feature_set_idx` (`feature_set_id`),
  KEY `seq_region_idx` (`seq_region_id`,`seq_region_start`)
) ENGINE=MyISAM AUTO_INCREMENT=941222 DEFAULT CHARSET=latin1 MAX_ROWS=100000000 AVG_ROW_LENGTH=80;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `external_feature_file`
--

DROP TABLE IF EXISTS `external_feature_file`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `external_feature_file` (
  `external_feature_file_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) DEFAULT NULL,
  `analysis_id` smallint(5) unsigned NOT NULL,
  `epigenome_id` int(10) unsigned DEFAULT NULL,
  `feature_type_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`external_feature_file_id`),
  UNIQUE KEY `name_idx` (`name`),
  KEY `epigenome_idx` (`epigenome_id`),
  KEY `analysis_idx` (`analysis_id`)
) ENGINE=MyISAM AUTO_INCREMENT=49 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `external_synonym`
--

DROP TABLE IF EXISTS `external_synonym`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `external_synonym` (
  `xref_id` int(10) unsigned NOT NULL,
  `synonym` varchar(100) NOT NULL,
  PRIMARY KEY (`xref_id`,`synonym`),
  KEY `name_index` (`synonym`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AVG_ROW_LENGTH=20;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `feature_set`
--

DROP TABLE IF EXISTS `feature_set`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `feature_set` (
  `feature_set_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `feature_type_id` int(10) unsigned NOT NULL,
  `analysis_id` smallint(5) unsigned NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `type` enum('annotated','regulatory','external','segmentation','mirna_target') DEFAULT NULL,
  `description` varchar(80) DEFAULT NULL,
  `display_label` varchar(80) DEFAULT NULL,
  PRIMARY KEY (`feature_set_id`),
  UNIQUE KEY `name_idx` (`name`),
  KEY `feature_type_idx` (`feature_type_id`)
) ENGINE=MyISAM AUTO_INCREMENT=927 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `feature_type`
--

DROP TABLE IF EXISTS `feature_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `feature_type` (
  `feature_type_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(40) NOT NULL,
  `class` enum('Insulator','DNA','Regulatory Feature','Histone','RNA','Polymerase','Transcription Factor','Transcription Factor Complex','Regulatory Motif','Enhancer','Expression','Pseudo','Open Chromatin','Search Region','Association Locus','Segmentation State','DNA Modification','Transcription Start Site') DEFAULT NULL,
  `analysis_id` smallint(5) unsigned DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `so_accession` varchar(64) DEFAULT NULL,
  `so_name` varchar(255) DEFAULT NULL,
  `production_name` varchar(120) DEFAULT NULL,
  PRIMARY KEY (`feature_type_id`),
  UNIQUE KEY `name_class_analysis_idx` (`name`,`class`,`analysis_id`),
  KEY `so_accession_idx` (`so_accession`)
) ENGINE=MyISAM AUTO_INCREMENT=180511 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `identity_xref`
--

DROP TABLE IF EXISTS `identity_xref`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `identity_xref` (
  `object_xref_id` int(10) unsigned NOT NULL,
  `xref_identity` int(5) DEFAULT NULL,
  `ensembl_identity` int(5) DEFAULT NULL,
  `xref_start` int(11) DEFAULT NULL,
  `xref_end` int(11) DEFAULT NULL,
  `ensembl_start` int(11) DEFAULT NULL,
  `ensembl_end` int(11) DEFAULT NULL,
  `cigar_line` text,
  `score` double DEFAULT NULL,
  `evalue` double DEFAULT NULL,
  PRIMARY KEY (`object_xref_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `meta`
--

DROP TABLE IF EXISTS `meta`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `meta` (
  `meta_id` int(10) NOT NULL AUTO_INCREMENT,
  `species_id` int(10) unsigned DEFAULT '1',
  `meta_key` varchar(46) NOT NULL,
  `meta_value` varchar(950) NOT NULL,
  PRIMARY KEY (`meta_id`),
  UNIQUE KEY `species_key_value_idx` (`species_id`,`meta_key`,`meta_value`),
  KEY `species_value_idx` (`species_id`,`meta_value`)
) ENGINE=MyISAM AUTO_INCREMENT=693 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `meta_coord`
--

DROP TABLE IF EXISTS `meta_coord`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `meta_coord` (
  `table_name` varchar(40) NOT NULL,
  `coord_system_id` int(10) unsigned NOT NULL,
  `max_length` int(11) DEFAULT NULL,
  UNIQUE KEY `table_name` (`table_name`,`coord_system_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mirna_target_feature`
--

DROP TABLE IF EXISTS `mirna_target_feature`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mirna_target_feature` (
  `mirna_target_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `feature_set_id` int(10) unsigned NOT NULL,
  `feature_type_id` int(10) unsigned DEFAULT NULL,
  `accession` varchar(60) DEFAULT NULL,
  `display_label` varchar(60) DEFAULT NULL,
  `evidence` varchar(60) DEFAULT NULL,
  `interdb_stable_id` int(10) unsigned DEFAULT NULL,
  `method` varchar(60) DEFAULT NULL,
  `seq_region_id` int(10) unsigned NOT NULL,
  `seq_region_start` int(10) unsigned NOT NULL,
  `seq_region_end` int(10) unsigned NOT NULL,
  `seq_region_strand` tinyint(1) NOT NULL,
  `supporting_information` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`mirna_target_feature_id`),
  UNIQUE KEY `interdb_stable_id_idx` (`interdb_stable_id`),
  KEY `feature_type_idx` (`feature_type_id`),
  KEY `feature_set_idx` (`feature_set_id`),
  KEY `seq_region_idx` (`seq_region_id`,`seq_region_start`)
) ENGINE=MyISAM AUTO_INCREMENT=316842 DEFAULT CHARSET=latin1 MAX_ROWS=100000000;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `motif_feature`
--

DROP TABLE IF EXISTS `motif_feature`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `motif_feature` (
  `motif_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `binding_matrix_id` int(10) unsigned NOT NULL,
  `seq_region_id` int(10) unsigned NOT NULL,
  `seq_region_start` int(10) unsigned NOT NULL,
  `seq_region_end` int(10) unsigned NOT NULL,
  `seq_region_strand` tinyint(1) NOT NULL,
  `display_label` varchar(60) DEFAULT NULL,
  `score` double DEFAULT NULL,
  `interdb_stable_id` mediumint(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`motif_feature_id`),
  UNIQUE KEY `interdb_stable_id_idx` (`interdb_stable_id`),
  KEY `seq_region_idx` (`seq_region_id`,`seq_region_start`),
  KEY `binding_matrix_idx` (`binding_matrix_id`)
) ENGINE=MyISAM AUTO_INCREMENT=1290348 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `object_xref`
--

DROP TABLE IF EXISTS `object_xref`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `object_xref` (
  `object_xref_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ensembl_id` int(10) unsigned NOT NULL,
  `ensembl_object_type` enum('Epigenome','Experiment','RegulatoryFeature','ExternalFeature','AnnotatedFeature','FeatureType','MirnaTargetFeature','ProbeSet','Probe','ProbeFeature') NOT NULL,
  `xref_id` int(10) unsigned NOT NULL,
  `linkage_annotation` varchar(255) DEFAULT NULL,
  `analysis_id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`object_xref_id`),
  UNIQUE KEY `xref_idx` (`xref_id`,`ensembl_object_type`,`ensembl_id`,`analysis_id`),
  KEY `analysis_idx` (`analysis_id`),
  KEY `ensembl_idx` (`ensembl_object_type`,`ensembl_id`)
) ENGINE=MyISAM AUTO_INCREMENT=197114953 DEFAULT CHARSET=latin1 MAX_ROWS=100000000 AVG_ROW_LENGTH=40;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ontology_xref`
--

DROP TABLE IF EXISTS `ontology_xref`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ontology_xref` (
  `object_xref_id` int(10) unsigned NOT NULL DEFAULT '0',
  `source_xref_id` int(10) unsigned DEFAULT NULL,
  `linkage_type` enum('IC','IDA','IEA','IEP','IGI','IMP','IPI','ISS','NAS','ND','TAS','NR','RCA') NOT NULL,
  UNIQUE KEY `object_xref_id_2` (`object_xref_id`,`source_xref_id`,`linkage_type`),
  KEY `object_xref_id` (`object_xref_id`),
  KEY `source_xref_id` (`source_xref_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `peak`
--

DROP TABLE IF EXISTS `peak`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `peak` (
  `peak_id` int(10) unsigned NOT NULL,
  `seq_region_id` int(10) unsigned NOT NULL,
  `seq_region_start` int(10) unsigned NOT NULL,
  `seq_region_end` int(10) unsigned NOT NULL,
  `seq_region_strand` tinyint(1) NOT NULL,
  `score` double DEFAULT NULL,
  `peak_calling_id` int(10) unsigned NOT NULL,
  `summit` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`peak_id`),
  UNIQUE KEY `seq_region_feature_set_idx` (`seq_region_id`,`seq_region_start`,`peak_calling_id`),
  KEY `feature_set_idx` (`peak_calling_id`)
) ENGINE=MyISAM AUTO_INCREMENT=69669956 DEFAULT CHARSET=latin1 MAX_ROWS=100000000 AVG_ROW_LENGTH=39;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `peak_calling`
--

DROP TABLE IF EXISTS `peak_calling`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `peak_calling` (
  `peak_calling_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(300) NOT NULL,
  `display_label` varchar(300) NOT NULL,
  `feature_type_id` int(10) unsigned NOT NULL,
  `analysis_id` smallint(5) unsigned NOT NULL,
  `alignment_id` int(10) unsigned NOT NULL,
  `epigenome_id` int(10) unsigned DEFAULT NULL,
  `experiment_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`peak_calling_id`),
  UNIQUE KEY `peak_calling_id_idx` (`peak_calling_id`)
) ENGINE=MyISAM AUTO_INCREMENT=927 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `peak_calling_qc_prop_reads_in_peaks`
--

DROP TABLE IF EXISTS `peak_calling_qc_prop_reads_in_peaks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `peak_calling_qc_prop_reads_in_peaks` (
  `peak_calling_qc_prop_reads_in_peaks_id` int(10) unsigned NOT NULL,
  `analysis_id` smallint(5) unsigned DEFAULT NULL,
  `peak_calling_id` int(10) unsigned NOT NULL,
  `prop_reads_in_peaks` double DEFAULT NULL,
  `total_reads` int(10) DEFAULT NULL,
  `path` varchar(512) NOT NULL,
  `bam_file` varchar(512) NOT NULL,
  PRIMARY KEY (`peak_calling_qc_prop_reads_in_peaks_id`)
) ENGINE=MyISAM AUTO_INCREMENT=924 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `probe`
--

DROP TABLE IF EXISTS `probe`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `probe` (
  `probe_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `probe_set_id` int(10) unsigned DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `length` smallint(6) unsigned NOT NULL,
  `array_chip_id` int(10) unsigned NOT NULL,
  `class` varchar(20) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `probe_seq_id` int(10) DEFAULT NULL,
  PRIMARY KEY (`probe_id`,`name`,`array_chip_id`),
  KEY `probe_set_idx` (`probe_set_id`),
  KEY `array_chip_idx` (`array_chip_id`),
  KEY `name_idx` (`name`),
  KEY `probe_seq_idx` (`probe_seq_id`)
) ENGINE=MyISAM AUTO_INCREMENT=19941465 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `probe_feature`
--

DROP TABLE IF EXISTS `probe_feature`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `probe_feature` (
  `probe_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `seq_region_id` int(10) unsigned NOT NULL,
  `seq_region_start` int(10) NOT NULL,
  `seq_region_end` int(10) NOT NULL,
  `seq_region_strand` tinyint(4) NOT NULL,
  `probe_id` int(10) unsigned NOT NULL,
  `analysis_id` smallint(5) unsigned NOT NULL,
  `mismatches` tinyint(4) NOT NULL,
  `cigar_line` varchar(50) DEFAULT NULL,
  `hit_id` varchar(255) DEFAULT NULL,
  `source` enum('genomic','transcript') DEFAULT NULL,
  PRIMARY KEY (`probe_feature_id`),
  KEY `probe_idx` (`probe_id`),
  KEY `seq_region_probe_probe_feature_idx` (`seq_region_id`,`seq_region_start`,`seq_region_end`,`probe_id`,`probe_feature_id`)
) ENGINE=MyISAM AUTO_INCREMENT=45678169 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `probe_feature_transcript`
--

DROP TABLE IF EXISTS `probe_feature_transcript`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `probe_feature_transcript` (
  `probe_feature_transcript_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `probe_feature_id` int(10) unsigned DEFAULT NULL,
  `stable_id` varchar(128) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`probe_feature_transcript_id`),
  KEY `probe_feature_transcript_id_idx` (`probe_feature_transcript_id`),
  KEY `probe_feature_id_idx` (`probe_feature_id`)
) ENGINE=MyISAM AUTO_INCREMENT=125053220 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `probe_seq`
--

DROP TABLE IF EXISTS `probe_seq`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `probe_seq` (
  `probe_seq_id` int(10) NOT NULL AUTO_INCREMENT,
  `sequence` text NOT NULL,
  `sequence_upper` text NOT NULL,
  `sequence_upper_sha1` char(40) NOT NULL,
  PRIMARY KEY (`probe_seq_id`),
  UNIQUE KEY `sequence_upper_sha1` (`sequence_upper_sha1`)
) ENGINE=MyISAM AUTO_INCREMENT=19941465 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `probe_set`
--

DROP TABLE IF EXISTS `probe_set`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `probe_set` (
  `probe_set_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `size` smallint(6) unsigned NOT NULL,
  `family` varchar(20) DEFAULT NULL,
  `array_chip_id` int(10) DEFAULT NULL,
  PRIMARY KEY (`probe_set_id`),
  KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=1919342 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `probe_set_transcript`
--

DROP TABLE IF EXISTS `probe_set_transcript`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `probe_set_transcript` (
  `probe_set_transcript_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `probe_set_id` int(10) unsigned NOT NULL,
  `stable_id` varchar(128) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`probe_set_transcript_id`),
  KEY `probe_set_transcript_id_idx` (`probe_set_transcript_id`),
  KEY `probe_set_transcript_stable_id_idx` (`stable_id`)
) ENGINE=MyISAM AUTO_INCREMENT=4283380 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `probe_transcript`
--

DROP TABLE IF EXISTS `probe_transcript`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `probe_transcript` (
  `probe_transcript_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `probe_id` int(10) unsigned NOT NULL,
  `stable_id` varchar(128) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`probe_transcript_id`),
  KEY `probe_transcript_id` (`probe_transcript_id`),
  KEY `probe_transcript_stable_id_idx` (`stable_id`),
  KEY `probe_transcript_idx` (`probe_id`)
) ENGINE=MyISAM AUTO_INCREMENT=66343254 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `read_file`
--

DROP TABLE IF EXISTS `read_file`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `read_file` (
  `read_file_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(300) NOT NULL,
  `analysis_id` smallint(5) unsigned NOT NULL,
  `is_paired_end` tinyint(1) DEFAULT NULL,
  `paired_with` int(10) DEFAULT NULL,
  `file_size` bigint(20) DEFAULT NULL,
  `read_length` int(10) DEFAULT NULL,
  `md5sum` varchar(45) DEFAULT NULL,
  `file` text,
  `notes` text,
  PRIMARY KEY (`read_file_id`),
  UNIQUE KEY `read_file_id_idx` (`read_file_id`)
) ENGINE=MyISAM AUTO_INCREMENT=5568 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `read_file_experimental_configuration`
--

DROP TABLE IF EXISTS `read_file_experimental_configuration`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `read_file_experimental_configuration` (
  `read_file_experimental_configuration_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `read_file_id` int(10) unsigned DEFAULT NULL,
  `experiment_id` int(10) unsigned NOT NULL,
  `biological_replicate` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `technical_replicate` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `paired_end_tag` int(11) DEFAULT NULL,
  `multiple` int(11) DEFAULT '1',
  PRIMARY KEY (`read_file_experimental_configuration_id`),
  UNIQUE KEY `name_exp_idx` (`experiment_id`,`biological_replicate`,`technical_replicate`),
  KEY `experiment_idx` (`experiment_id`)
) ENGINE=MyISAM AUTO_INCREMENT=1830 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `regulatory_activity`
--

DROP TABLE IF EXISTS `regulatory_activity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regulatory_activity` (
  `regulatory_activity_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `regulatory_feature_id` int(10) unsigned DEFAULT NULL,
  `activity` enum('INACTIVE','REPRESSED','POISED','ACTIVE','NA') DEFAULT NULL,
  `epigenome_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`regulatory_activity_id`),
  UNIQUE KEY `uniqueness_constraint_idx` (`epigenome_id`,`regulatory_feature_id`),
  KEY `regulatory_feature_idx` (`regulatory_feature_id`)
) ENGINE=MyISAM AUTO_INCREMENT=61404859 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `regulatory_build`
--

DROP TABLE IF EXISTS `regulatory_build`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regulatory_build` (
  `regulatory_build_id` int(4) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(45) NOT NULL,
  `version` varchar(50) DEFAULT NULL,
  `initial_release_date` varchar(50) DEFAULT NULL,
  `last_annotation_update` varchar(50) DEFAULT NULL,
  `feature_type_id` int(4) unsigned NOT NULL,
  `analysis_id` smallint(5) unsigned NOT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT '0',
  `sample_regulatory_feature_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`regulatory_build_id`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `regulatory_build_epigenome`
--

DROP TABLE IF EXISTS `regulatory_build_epigenome`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regulatory_build_epigenome` (
  `regulatory_build_epigenome_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `regulatory_build_id` int(10) unsigned NOT NULL,
  `epigenome_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`regulatory_build_epigenome_id`)
) ENGINE=MyISAM AUTO_INCREMENT=211 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `regulatory_evidence`
--

DROP TABLE IF EXISTS `regulatory_evidence`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regulatory_evidence` (
  `regulatory_activity_id` int(10) unsigned NOT NULL,
  `attribute_feature_id` int(10) unsigned NOT NULL,
  `attribute_feature_table` enum('annotated','motif') NOT NULL DEFAULT 'annotated',
  PRIMARY KEY (`regulatory_activity_id`,`attribute_feature_table`,`attribute_feature_id`),
  KEY `attribute_feature_idx` (`attribute_feature_id`,`attribute_feature_table`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `regulatory_feature`
--

DROP TABLE IF EXISTS `regulatory_feature`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regulatory_feature` (
  `regulatory_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `feature_type_id` int(10) unsigned DEFAULT NULL,
  `seq_region_id` int(10) unsigned NOT NULL,
  `seq_region_strand` tinyint(1) NOT NULL,
  `seq_region_start` int(10) unsigned NOT NULL,
  `seq_region_end` int(10) unsigned NOT NULL,
  `stable_id` varchar(18) DEFAULT NULL,
  `bound_start_length` mediumint(3) unsigned NOT NULL,
  `bound_end_length` mediumint(3) unsigned NOT NULL,
  `epigenome_count` smallint(6) DEFAULT NULL,
  `regulatory_build_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`regulatory_feature_id`),
  UNIQUE KEY `uniqueness_constraint_idx` (`feature_type_id`,`seq_region_id`,`seq_region_strand`,`seq_region_start`,`seq_region_end`,`stable_id`,`bound_start_length`,`bound_end_length`,`regulatory_build_id`),
  KEY `feature_type_idx` (`feature_type_id`),
  KEY `stable_id_idx` (`stable_id`)
) ENGINE=MyISAM AUTO_INCREMENT=877771 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `segmentation_feature`
--

DROP TABLE IF EXISTS `segmentation_feature`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `segmentation_feature` (
  `segmentation_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `seq_region_id` int(10) unsigned NOT NULL,
  `seq_region_start` int(10) unsigned NOT NULL,
  `seq_region_end` int(10) unsigned NOT NULL,
  `seq_region_strand` tinyint(1) NOT NULL,
  `feature_type_id` int(10) unsigned DEFAULT NULL,
  `feature_set_id` int(10) unsigned DEFAULT NULL,
  `score` double DEFAULT NULL,
  `display_label` varchar(60) DEFAULT NULL,
  PRIMARY KEY (`segmentation_feature_id`),
  UNIQUE KEY `fset_seq_region_idx` (`feature_set_id`,`seq_region_id`,`seq_region_start`),
  KEY `feature_type_idx` (`feature_type_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=100000000;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `segmentation_file`
--

DROP TABLE IF EXISTS `segmentation_file`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `segmentation_file` (
  `segmentation_file_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `regulatory_build_id` int(4) unsigned DEFAULT NULL,
  `name` varchar(100) DEFAULT NULL,
  `analysis_id` smallint(5) unsigned NOT NULL,
  `epigenome_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`segmentation_file_id`),
  UNIQUE KEY `name_idx` (`name`),
  KEY `epigenome_idx` (`epigenome_id`),
  KEY `analysis_idx` (`analysis_id`)
) ENGINE=MyISAM AUTO_INCREMENT=75 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `unmapped_object`
--

DROP TABLE IF EXISTS `unmapped_object`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `unmapped_object` (
  `unmapped_object_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type` enum('xref','probe2transcript','array_mapping') NOT NULL,
  `analysis_id` smallint(5) unsigned NOT NULL,
  `external_db_id` int(10) unsigned DEFAULT NULL,
  `identifier` varchar(255) NOT NULL,
  `unmapped_reason_id` int(10) unsigned NOT NULL,
  `query_score` double DEFAULT NULL,
  `target_score` double DEFAULT NULL,
  `ensembl_id` int(10) unsigned DEFAULT '0',
  `ensembl_object_type` enum('RegulatoryFeature','ExternalFeature','AnnotatedFeature','FeatureType','Probe','ProbeSet','ProbeFeature') NOT NULL,
  `parent` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`unmapped_object_id`),
  UNIQUE KEY `unique_unmapped_obj_idx` (`ensembl_id`,`ensembl_object_type`,`identifier`,`unmapped_reason_id`,`parent`,`external_db_id`),
  KEY `anal_exdb_idx` (`analysis_id`,`external_db_id`),
  KEY `id_idx` (`identifier`(50)),
  KEY `ext_db_identifier_idx` (`external_db_id`,`identifier`)
) ENGINE=MyISAM AUTO_INCREMENT=96883064 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `unmapped_reason`
--

DROP TABLE IF EXISTS `unmapped_reason`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `unmapped_reason` (
  `unmapped_reason_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `summary_description` varchar(255) DEFAULT NULL,
  `full_description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`unmapped_reason_id`)
) ENGINE=MyISAM AUTO_INCREMENT=96165394 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `xref`
--

DROP TABLE IF EXISTS `xref`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `xref` (
  `xref_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `external_db_id` int(10) unsigned DEFAULT NULL,
  `dbprimary_acc` varchar(512) NOT NULL,
  `display_label` varchar(512) NOT NULL,
  `version` varchar(10) DEFAULT NULL,
  `description` text,
  `info_type` enum('NONE','PROJECTION','MISC','DEPENDENT','DIRECT','SEQUENCE_MATCH','INFERRED_PAIR','PROBE','UNMAPPED','COORDINATE_OVERLAP','CHECKSUM') NOT NULL DEFAULT 'NONE',
  `info_text` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`xref_id`),
  UNIQUE KEY `id_index` (`dbprimary_acc`,`external_db_id`,`info_type`,`info_text`,`version`),
  KEY `display_index` (`display_label`),
  KEY `info_type_idx` (`info_type`)
) ENGINE=MyISAM AUTO_INCREMENT=5503380 DEFAULT CHARSET=latin1 AVG_ROW_LENGTH=100;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50112 SET @disable_bulk_load = IF (@is_rocksdb_supported, 'SET SESSION rocksdb_bulk_load = @old_rocksdb_bulk_load', 'SET @dummy_rocksdb_bulk_load = 0') */;
/*!50112 PREPARE s FROM @disable_bulk_load */;
/*!50112 EXECUTE s */;
/*!50112 DEALLOCATE PREPARE s */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-10-31 14:35:00
