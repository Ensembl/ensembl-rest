CREATE TABLE `alt_id` (
  `alt_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `term_id` int(10) unsigned NOT NULL,
  `accession` varchar(64) NOT NULL,
  PRIMARY KEY (`alt_id`),
  UNIQUE KEY `term_alt_idx` (`term_id`,`alt_id`),
  KEY `accession_idx` (`accession`(50))
) ENGINE=MyISAM DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC;

CREATE TABLE `closure` (
  `closure_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `child_term_id` int(10) unsigned NOT NULL,
  `parent_term_id` int(10) unsigned NOT NULL,
  `subparent_term_id` int(10) unsigned DEFAULT NULL,
  `distance` tinyint(3) unsigned NOT NULL,
  `ontology_id` int(10) unsigned NOT NULL,
  `confident_relationship` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`closure_id`),
  UNIQUE KEY `child_parent_idx` (`child_term_id`,`parent_term_id`,`subparent_term_id`,`ontology_id`),
  KEY `parent_subparent_idx` (`parent_term_id`,`subparent_term_id`)
) ENGINE=MyISAM AUTO_INCREMENT=21061 DEFAULT CHARSET=latin1 ROW_FORMAT=FIXED;

CREATE TABLE `meta` (
  `meta_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `meta_key` varchar(64) NOT NULL,
  `meta_value` varchar(255) NOT NULL,
  `species_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`meta_id`),
  UNIQUE KEY `key_value_idx` (`meta_key`,`meta_value`)
) ENGINE=MyISAM AUTO_INCREMENT=66 DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC;

CREATE TABLE `ontology` (
  `ontology_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `namespace` varchar(64) NOT NULL,
  `data_version` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`ontology_id`),
  UNIQUE KEY `name_namespace_idx` (`name`,`namespace`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC;

CREATE TABLE `relation` (
  `relation_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `child_term_id` int(10) unsigned NOT NULL,
  `parent_term_id` int(10) unsigned NOT NULL,
  `relation_type_id` int(10) unsigned NOT NULL,
  `intersection_of` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `ontology_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`relation_id`),
  UNIQUE KEY `child_parent_idx` (`child_term_id`,`parent_term_id`,`relation_type_id`,`intersection_of`,`ontology_id`),
  KEY `parent_idx` (`parent_term_id`)
) ENGINE=MyISAM AUTO_INCREMENT=14141 DEFAULT CHARSET=latin1 ROW_FORMAT=FIXED;

CREATE TABLE `relation_type` (
  `relation_type_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  PRIMARY KEY (`relation_type_id`),
  UNIQUE KEY `name_idx` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=52 DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC;

CREATE TABLE `subset` (
  `subset_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `definition` varchar(1023) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  PRIMARY KEY (`subset_id`),
  UNIQUE KEY `name_idx` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC;

CREATE TABLE `synonym` (
  `synonym_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `term_id` int(10) unsigned NOT NULL,
  `name` mediumtext COLLATE utf8_swedish_ci NOT NULL,
  `type` enum('EXACT','BROAD','NARROW','RELATED') COLLATE utf8_swedish_ci DEFAULT NULL,
  `dbxref` varchar(256) COLLATE utf8_swedish_ci NOT NULL,
  PRIMARY KEY (`synonym_id`),
  UNIQUE KEY `term_synonym_idx` (`term_id`,`synonym_id`),
  KEY `name_idx` (`name`(50))
) ENGINE=MyISAM AUTO_INCREMENT=145221 DEFAULT CHARSET=utf8 COLLATE=utf8_swedish_ci ROW_FORMAT=DYNAMIC;

CREATE TABLE `term` (
  `term_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ontology_id` int(10) unsigned NOT NULL,
  `subsets` text,
  `accession` varchar(64) NOT NULL,
  `name` varchar(255) NOT NULL,
  `definition` text,
  `is_root` int(11) NOT NULL DEFAULT '0',
  `is_obsolete` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`term_id`),
  UNIQUE KEY `accession_idx` (`accession`),
  UNIQUE KEY `ontology_acc_idx` (`ontology_id`,`accession`),
  KEY `name_idx` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=70099 DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC;

