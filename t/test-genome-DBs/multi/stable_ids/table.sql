CREATE TABLE `archive_id_lookup` (
  `archive_id` varchar(128) NOT NULL,
  `species_id` int(10) unsigned NOT NULL,
  `db_type` varchar(255) NOT NULL,
  `object_type` varchar(255) NOT NULL,
  UNIQUE KEY `archive_id_lookup_idx` (`archive_id`,`species_id`,`db_type`,`object_type`),
  KEY `archive_id_db_type` (`archive_id`,`db_type`,`object_type`),
  KEY `archive_id_object_type` (`archive_id`,`object_type`),
  KEY `species_idx` (`species_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 ;

CREATE TABLE `meta` (
  `meta_id` int(11) NOT NULL AUTO_INCREMENT,
  `species_id` int(10) unsigned DEFAULT '1',
  `meta_key` varchar(40) NOT NULL,
  `meta_value` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`meta_id`),
  UNIQUE KEY `species_key_value_idx` (`species_id`,`meta_key`,`meta_value`),
  KEY `species_value_idx` (`species_id`,`meta_value`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 ;

CREATE TABLE `species` (
  `species_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `taxonomy_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`species_id`),
  UNIQUE KEY `name_idx` (`name`),
  KEY `species_ids` (`species_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 ;

CREATE TABLE `stable_id_lookup` (
  `stable_id` varchar(128) NOT NULL,
  `species_id` int(10) unsigned NOT NULL,
  `db_type` varchar(255) NOT NULL,
  `object_type` varchar(255) NOT NULL,
  UNIQUE KEY `stable_id_lookup_idx` (`stable_id`,`species_id`,`db_type`,`object_type`),
  KEY `stable_id_db_type` (`stable_id`,`db_type`,`object_type`),
  KEY `stable_id_object_type` (`stable_id`,`object_type`),
  KEY `species_idx` (`species_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 ;

