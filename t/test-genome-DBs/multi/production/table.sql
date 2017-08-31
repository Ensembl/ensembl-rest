CREATE TABLE `biotype` (
  `biotype_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT '1',
  `is_dumped` tinyint(1) NOT NULL DEFAULT '1',
  `object_type` enum('gene','transcript') NOT NULL DEFAULT 'gene',
  `db_type` set('cdna','core','coreexpressionatlas','coreexpressionest','coreexpressiongnf','funcgen','otherfeatures','rnaseq','variation','vega','presite','sangervega') NOT NULL DEFAULT 'core',
  `attrib_type_id` int(11) DEFAULT NULL,
  `description` text,
  `biotype_group` enum('coding','pseudogene','snoncoding','lnoncoding','mnoncoding','LRG','undefined','no_group') DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `modified_by` int(11) DEFAULT NULL,
  `modified_at` datetime DEFAULT NULL,
  PRIMARY KEY (`biotype_id`),
  UNIQUE KEY `name_type_idx` (`name`,`object_type`,`db_type`)
) ENGINE=MyISAM AUTO_INCREMENT=204 DEFAULT CHARSET=latin1;

