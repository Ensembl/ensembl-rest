-- Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
-- Copyright [2016-2017] EMBL-European Bioinformatics Institute
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

/**
* Ensembl funcgen table definitions
*
*
*
* Conventions:
*  - use lower case and underscores
*  - internal IDs are integers named tablename_id
*  - same name is given in foreign key relations
*
* DO NOT use '---' as a comment, this breaks in macosx mysql?!
* This also generally applies to all  --[^ ] !?
*
* Table documentation uses format parsed and defined here

*/

/**
@header  Main feature tables
@desc    These define the various genomics features and their relevant associated tables.
@colour  #FFCC66
@legend  #FFCC66 Main feature tables
*/


/**
@table  regulatory_feature
@desc   The table contains the features resulting from the regulatory build process.
@colour  #FFCC66

@column regulatory_feature_id   Internal ID
@column feature_type_id         @link feature_type ID
@column seq_region_id           @link seq_region ID
@column seq_region_start        Start position of this feature
@column seq_region_end          End position of this feature
@column seq_region_strand       Strand orientation of this feature
@column display_label           Text display label
@column stable_id               Integer stable ID without ENSR prefix *mnuhn: Not true, they do have this prefix*
@column binary_string           *deprecated*
@column bound_start_length      Distance between start of the feature and start of the bound region. Bound regions are used for promoters only. They define the flanking regions. It is an area that is predicted t
@column bound_end_length        Distance between end of the bound region and end of this feature
@column activity                Indicates the type of activity of this feature in this epigenome
@column epigenome_count         Integer, number of epigenomes in which this feature is active

@see feature_set
@see feature_type
@see seq_region

*/

DROP TABLE IF EXISTS `regulatory_feature`;
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
  -- The name "uniqueness_constraint_idx" is used in the
  -- RegulatoryFeatureAdaptor to catch issues regarding its violation.
  -- Changing the name means having to update it in the
  -- RegulatoryFeatureAdaptor as well.
  --
  UNIQUE KEY `uniqueness_constraint_idx` (`feature_type_id`,`seq_region_id`,`seq_region_strand`,`seq_region_start`,`seq_region_end`,`stable_id`,`bound_start_length`,`bound_end_length`,`regulatory_build_id`),
  KEY `feature_type_idx` (`feature_type_id`),
  KEY `stable_id_idx` (`stable_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

/**
@table  regulatory_evidence
@desc   Denormalised table defining links between a regulatory_feature and it's constituent 'attribute' features.
@colour  #FFCC66

@column regulatory_feature_id   Internal ID
@column attribute_feature_id    Table ID of attribute feature
@column attribute_feature_table Table name of attribute feature

@see annotated_feature
*/

DROP TABLE IF EXISTS `regulatory_evidence`;
CREATE TABLE `regulatory_evidence` (
  `regulatory_activity_id` int(10) unsigned NOT NULL,
  `attribute_feature_id` int(10) unsigned NOT NULL,
  `attribute_feature_table` enum('annotated','motif') NOT NULL DEFAULT 'annotated',
  PRIMARY KEY (`regulatory_activity_id`,`attribute_feature_table`,`attribute_feature_id`),
  KEY `attribute_feature_idx` (`attribute_feature_id`,`attribute_feature_table`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;



DROP TABLE IF EXISTS `regulatory_activity`;
CREATE TABLE `regulatory_activity` (
  `regulatory_activity_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `regulatory_feature_id` int(10) unsigned DEFAULT NULL,
  `activity` enum('INACTIVE','REPRESSED','POISED','ACTIVE','NA') DEFAULT NULL,
  `epigenome_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`regulatory_activity_id`),
  UNIQUE KEY `uniqueness_constraint_idx` (`epigenome_id`,`regulatory_feature_id`),
  KEY `regulatory_feature_idx` (`regulatory_feature_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;




DROP TABLE IF EXISTS `regulatory_build`;
CREATE TABLE `regulatory_build` (
  `regulatory_build_id` int(4) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(45) NOT NULL,
  `version` varchar(50) DEFAULT NULL,
  `initial_release_date` varchar(50) DEFAULT NULL,
  `last_annotation_update` varchar(50) DEFAULT NULL,
  `feature_type_id` int(4) unsigned NOT NULL,
  `analysis_id` smallint(5) unsigned NOT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT '0',
  `sample_regulatory_feature_id` int(10) unsigned,
  PRIMARY KEY (`regulatory_build_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;




DROP TABLE IF EXISTS `regulatory_build_epigenome`;
CREATE TABLE `regulatory_build_epigenome` (
  `regulatory_build_epigenome_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `regulatory_build_id` int(10) unsigned NOT NULL,
  `epigenome_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`regulatory_build_epigenome_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/**
@table  segmentation_feature
@desc   Represents a genomic segment feature as the result of an segmentation
        analysis i.e. Segway or ChromHmm
@colour  #FFCC66

@column segmentation_feature_id Internal ID
@column feature_set_id          @link feature_set ID
@column feature_type_id         @link feature_type ID
@column seq_region_id           @link seq_region ID
@column seq_region_start        Start position of this feature
@column seq_region_end          End position of this feature
@column seq_region_strand       Strand orientation of this feature
@column score                   Score derived from software
@column display_label           Text display label

@see feature_set
@see feature_type
@see seq_region
*/

DROP TABLE IF EXISTS `segmentation_feature`;
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


DROP TABLE IF EXISTS `segmentation_file`;
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/**
@table  annotated_feature
@desc   Represents a genomic feature as the result of an analysis i.e. a ChIP or DNase1 peak call.
@colour  #FFCC66

@column annotated_feature_id    Internal ID
@column feature_set_id          @link feature_set ID
@column seq_region_id           @link seq_region ID
@column seq_region_start        Start position of this feature
@column seq_region_end          End position of this feature
@column seq_region_strand       Strand orientation of this feature
@column display_label           Text display label
@column score                   Score derived from software
@column summit                  Represents peak summit for those analyses which provide it (e.g. Swembl)

@see feature_set
@see seq_region
*/

DROP TABLE IF EXISTS `annotated_feature`;
CREATE TABLE `annotated_feature` (
  `annotated_feature_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `seq_region_id` int(10) unsigned NOT NULL,
  `seq_region_start` int(10) unsigned NOT NULL,
  `seq_region_end` int(10) unsigned NOT NULL,
  `seq_region_strand` tinyint(1) NOT NULL,
  `display_label` varchar(60) DEFAULT NULL,
  `score` double DEFAULT NULL,
  `feature_set_id` int(10) unsigned NOT NULL,
  `summit` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`annotated_feature_id`),
  UNIQUE KEY `seq_region_feature_set_idx` (`seq_region_id`,`seq_region_start`,`feature_set_id`),
  KEY `feature_set_idx` (`feature_set_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=100000000 AVG_ROW_LENGTH=39;


/**
@table  motif_feature
@desc   The table contains genomic alignments of binding_matrix PWMs.
@colour  #FFCC66

@column motif_feature_id    Primary key, internal ID
@column binding_matrix_id   @link binding_matrix table
@column seq_region_id       @link seq_region table
@column seq_region_start    Start position of this feature
@column seq_region_end      End position of this feature
@column seq_region_strand   Strand orientation of this feature
@column display_label       Text display label
@column score               Score derived from alignment software (e.g.MOODS)
@column interdb_stable_id   Unique key, provides linkability between DBs

@see associated_motif_feature
@see binding_matrix
*/


DROP TABLE IF EXISTS `motif_feature`;
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/**
@table  mirna_target_feature
@desc   The table contains imports from externally curated resources e.g. cisRED, miRanda, VISTA, redFLY etc.
@colour  #FFCC66

@column mirna_target_feature_id Internal ID
@column feature_set_id          @link feature_set ID
@column feature_type_id         @link feature_type ID
@column seq_region_id           @link seq_region ID
@column accession               Accession number given by data source
@column display_label           Text display label
@column evidence                Evidence level provided by data source
@column interdb_stable_id       Unique key, provides linkability between DBs
@column method                  Method used to identify miRNA target
@column seq_region_start        Start position of this feature
@column seq_region_end          End position of this feature
@column seq_region_strand       Strand orientation of this feature
@column supporting_information  Additional information which does not fit another category

@see feature_set
@see feature_type
@see seq_region
*/


DROP TABLE IF EXISTS `mirna_target_feature`;
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=100000000;


/**
@table  associated_motif_feature
@desc   The table provides links between motif_features and annotated_features representing peaks of the relevant transcription factor.
@colour  #FFCC66

@column annotated_feature_id    @link annotated_feature table ID
@column motif_feature_id        @link motif_feature table ID

@see associated_motif_feature
*/

DROP TABLE IF EXISTS `associated_motif_feature`;
CREATE TABLE `associated_motif_feature` (
  `annotated_feature_id` int(10) unsigned NOT NULL,
  `motif_feature_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`annotated_feature_id`,`motif_feature_id`),
  KEY `motif_feature_idx` (`motif_feature_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/**
@table  binding_matrix
@desc   Contains information defining a specific binding matrix(PWM) as defined by the linked analysis e.g. Jaspar.
@colour  #FFCC66

@column binding_matrix_id  Internal table ID
@column analysis_id        @link analysis table ID
@column feature_type_id    @link feature_type table ID.
@column name               Name of PWM
@column frequencies        Matrix defining frequencing for each base at each position
@column description        Text description
@column threshold          Minimum score for Motif Features for this matrix

@see analysis
@see feature_type
*/

DROP TABLE IF EXISTS `binding_matrix`;
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/**
@table  external_feature
@desc   The table contains imports from externally curated resources e.g. cisRED, miRanda, VISTA, redFLY etc.
@colour  #FFCC66

@column external_feature_id  Internal ID
@column feature_set_id       @link feature_set ID
@column feature_type_id      @link feature_type ID
@column seq_region_id        @link seq_region ID
@column seq_region_start     Start position of this feature
@column seq_region_end       End position of this feature
@column seq_region_strand    Strand orientation of this feature
@column display_label        Text display label
@column interdb_stable_id    Unique key, provides linkability between DBs

@see feature_set
@see feature_type
@see seq_region
*/

DROP TABLE IF EXISTS `external_feature`;
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=100000000 AVG_ROW_LENGTH=80;



DROP TABLE IF EXISTS `external_feature_file`;
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/**
@table  probe_feature
@desc   The table contains genomic alignments @link probe entries.
@colour  #FFCC66

@column probe_feature_id    Internal ID
@column analysis_id         @link analysis table ID
@column probe_id            @link probe table ID
@column seq_region_id       @link seq_region table ID
@column seq_region_start    Start position of this feature
@column seq_region_end      End position of this feature
@column seq_region_strand   Strand orientation of this feature
@column mismatches          Integer, the number of bp matches for this alignment
@column cigar_line          Extended cigar line format representation of the alignment as defined here http://samtools.sourceforge.net/SAM-1.3.pdf.<br>
                            In summary:
                            <ul>
                              <li>= Seq/Alignment Match</li>
                              <li>M Alignment match/Seq mismatch</li>
                              <li>X Seq/Alignment mismatch</li>
                              <li>D Deletion</li>
                              <li>S Soft clipping, used for overhanging cdna alignments where genomic seq is unknown</li>
                            </ul>
@column hit_id              Id of the sequence on which the hit was initially made. Typically this will be the stable id of the transcript or the name of the sequence region.
@column source              The source of the sequence on which the probe was found. If set, this can be 'genomic' or 'transcript'

@see analysis
@see probe
@see seq_region
*/

DROP TABLE IF EXISTS `probe_feature`;
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `probe_feature_transcript`;
CREATE TABLE `probe_feature_transcript` (
  `probe_feature_transcript_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `probe_feature_id` int(10) unsigned DEFAULT NULL,
  `stable_id` varchar(128) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`probe_feature_transcript_id`),
  KEY `probe_feature_transcript_id_idx` (`probe_feature_transcript_id`),
  KEY `probe_feature_id_idx` (`probe_feature_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/**
@table  feature_type
@desc   Contains information about different types/classes of feature e.g. Brno nomenclature, Transcription Factor names etc.
@colour  #FFCC66

@column feature_type_id   Primary key, internal ID
@column analysis_id       @link analysis table ID
@column name              Name of feature_type
@column class             Class of feature_type
@column description       Text description
@column so_accession      Sequence ontology accession
@column so_name           Sequence ontology name
@column production_name   Name used in production

@see analysis
*/

DROP TABLE IF EXISTS `feature_type`;
CREATE TABLE `feature_type` (
  `feature_type_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(40) NOT NULL,
  `class` enum('Insulator','DNA','Regulatory Feature','Histone','RNA','Polymerase','Transcription Factor','Transcription Factor Complex','Regulatory Motif','Enhancer','Expression','Pseudo','Open Chromatin','Search Region','Association Locus','Segmentation State','DNA Modification','Transcription Start Site') DEFAULT NULL,
  `analysis_id` smallint(5) unsigned DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `so_accession` varchar(64) DEFAULT NULL,
  `so_name` varchar(255) DEFAULT NULL,
  `production_name` VARCHAR(120) DEFAULT NULL,
  PRIMARY KEY (`feature_type_id`),
  UNIQUE KEY `name_class_analysis_idx` (`name`,`class`,`analysis_id`),
  KEY `so_accession_idx` (`so_accession`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/**
@table  associated_feature_type
@desc   Link table providing many to many mapping for feature_type entries.
@colour  #FFCC66

@column table_id         Internal table_id of linked table
@column feature_type_id  Internal table_id of linked @link feature_type
@column table_name       Name of linked table

@see  feature_type
*/

DROP TABLE IF EXISTS `associated_feature_type`;
CREATE TABLE `associated_feature_type` (
  `table_id` int(10) unsigned NOT NULL,
  `table_name` enum('annotated_feature','external_feature','regulatory_feature','feature_type') NOT NULL,
  `feature_type_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`table_id`,`table_name`,`feature_type_id`),
  KEY `feature_type_index` (`feature_type_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/**

@header  Set tables
@desc    Sets are containers for distinct sets of raw and/or processed data.
@colour  #66CCFF
@legend  #66CCFF Set tables
*/

/**
@table  data_set
@desc   Defines highest level data container for associating the result of an analysis and the input data to that analysis e.g. Seq alignments(Input/ResultSet) and peak calls (FeatureSet)
@colour  #66CCFF

@column data_set_id     Internal ID
@column feature_set_id  Product @link feature_set table ID
@column name            Name of data set

@see feature_set
*/

DROP TABLE IF EXISTS `data_set`;
CREATE TABLE `data_set` (
  `data_set_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `feature_set_id` int(10) unsigned NOT NULL DEFAULT '0',
  `name` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`data_set_id`,`feature_set_id`),
  UNIQUE KEY `name_idx` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;




/**
@table  supporting_set
@desc   Defines association between @link data_set and underlying/supporting data.
@colour  #66CCFF

@column data_set_id        Internal ID
@column supporting_set_id  Table ID of supporting set
@column type               Type of supporting set e.g. result, feature or input set.

@see data_set
*/


DROP TABLE IF EXISTS `supporting_set`;
CREATE TABLE `supporting_set` (
  `data_set_id` int(10) unsigned NOT NULL,
  `supporting_set_id` int(10) unsigned NOT NULL,
  `type` enum('result','feature','input') NOT NULL DEFAULT 'result',
  PRIMARY KEY (`data_set_id`,`supporting_set_id`,`type`),
  KEY `type_idx` (`type`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/**
@table  feature_set
@desc   Container for genomic features defined by the result of an analysis e.g. peaks calls or regulatory features.
@colour  #66CCFF

@column feature_set_id  Internal ID
@column analysis_id     @link analysis ID
@column epigenome_id    @link epigenome ID
@column experiment_id   @link experiment mnuhn: According to https://www.ebi.ac.uk/panda/jira/browse/ENSREGULATION-147 this is only used in the experiment_view. AFAIK we don't use the experiment_view, so this column can be deprecated.
@column feature_type_id @link feature_type ID
@column name            Name for this feature set
@column type            Type of features contained e.g. annotated, external or regualtory
@column description     Text description
@column display_label   Shorter more readable version of name

@see analysis
@see epigenome
@see experiment
@see feature_type
*/

DROP TABLE IF EXISTS `feature_set`;
CREATE TABLE `feature_set` (
  `feature_set_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `feature_type_id` int(10) unsigned NOT NULL,
  `analysis_id` smallint(5) unsigned NOT NULL,
  `epigenome_id` int(10) unsigned DEFAULT NULL,
  `name` varchar(100) DEFAULT NULL,
  `type` enum('annotated','regulatory','external','segmentation','mirna_target') DEFAULT NULL,
  `description` varchar(80) DEFAULT NULL,
  `display_label` varchar(80) DEFAULT NULL,
  `experiment_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`feature_set_id`),
  UNIQUE KEY `name_idx` (`name`),
  KEY `feature_type_idx` (`feature_type_id`),
  KEY `experiment_idx` (`experiment_id`),
  KEY `epigenome_idx` (`epigenome_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/**
@table  feature_set_qc_prop_reads_in_peaks
@desc
@colour  #66CCFF

@column feature_set_qc_prop_reads_in_peaks_id  Internal ID
@column analysis_id                            @link analysis ID
@column feature_set_id                         @link feature set ID
@column prop_reads_in_peaks                    Proportion of reads in peaks
@column total_reads                            Total number of reads
@column path
@column bam_file

@see analysis
@see feature_set
*/

DROP TABLE IF EXISTS `feature_set_qc_prop_reads_in_peaks`;
CREATE TABLE `feature_set_qc_prop_reads_in_peaks` (
  `feature_set_qc_prop_reads_in_peaks_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `analysis_id` smallint(5) unsigned DEFAULT NULL,
  `feature_set_id` int(10) unsigned NOT NULL,
  `prop_reads_in_peaks` double DEFAULT NULL,
  `total_reads` int(10) DEFAULT NULL,
  `path` varchar(512) NOT NULL,
  `bam_file` varchar(512) NOT NULL,
  PRIMARY KEY (`feature_set_qc_prop_reads_in_peaks_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/**
@table  result_set

@desc   Think of this as an alignment or a summary of an alignment in form of a wiggleplot in bigWig format. The query used to generate the alignment is found by linking from this table over result_set_input to the input_subset table. The entry in input_subset represents the fastq file that was aligned. The reference to which it was aligned is based on the sequence of the species of the regulation database. It may be gender specific depending on the use case, so the query may have been aligned to the male or the female version of the genome depending on the details of the analysis.

Note that although the schema has objects to represent alignments, we don't store the actual alignments in the database. We only store summaries of the alignments as wiggleplots. If a result_set represents a wiggleplot, the location of the file can be found by the entry in the dbfile_registry pointing to it.

@colour  #66CCFF

@column result_set_id     Internal ID
@column analysis_id       @link analysis ID The aligner used to create this alignment.
@column epigenome_id      @link epigenome ID The epigenome from which the query sequence was derived. This is just a shortcut. THe link is redundant. The same epigenome could be obtained by linking from the input_subset table to experiment to epigenome_id.
@column experiment_id     @link experiment ID Another shortcut. This is the experiment that generated the query file for this alignment.
@column feature_type_id   @link feature_type ID Probably another shortcut to the feature type of the experiment. This would indicate how the reads were enriched.
@column name              Name of this result set, probably never used and could be dropped.
@column feature_class     Defines the class of the feature, this is used by the api for building the name of an adaptor of unkown purpose.

@see analysis
@see epigenome
@see experiment
@see feature_type
@see dbfile_registry

*/

DROP TABLE IF EXISTS `result_set`;
CREATE TABLE `result_set` (
  `result_set_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `analysis_id` smallint(5) unsigned NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `epigenome_id` int(10) unsigned DEFAULT NULL,
  `feature_type_id` int(10) unsigned DEFAULT NULL,
  `feature_class` enum('result','dna_methylation','segmentation') DEFAULT NULL,
  `experiment_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`result_set_id`),
  UNIQUE KEY `name_idx` (`name`),
  KEY `feature_type_idx` (`feature_type_id`),
  KEY `analysis_idx` (`analysis_id`),
  KEY `feature_class_idx` (`feature_class`),
  KEY `experiment_idx` (`experiment_id`),
  KEY `epigenome_idx` (`epigenome_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/**
@table  result_set_qc_chance
@desc
@colour  #66CCFF

@column result_set_qc_chance                                             Internal ID
@column signal_result_set_id
@column analysis_id                                                      @link analysis ID
@column p
@column q
@column divergence
@column z_score
@column percent_genome_enriched
@column input_scaling_factor
@column differential_percentage_enrichment
@column control_enrichment_stronger_than_chip_at_bin
@column first_nonzero_bin_at
@column pcr_amplification_bias_in_Input_coverage_of_1_percent_of_genome
@column path

@see analysis
*/

DROP TABLE IF EXISTS `result_set_qc_chance`;
CREATE TABLE `result_set_qc_chance` (
  `result_set_qc_chance_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `signal_result_set_id` int(10) unsigned DEFAULT NULL,
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
  PRIMARY KEY (`result_set_qc_chance_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/**
@table  result_set_qc_flagstats
@desc
@colour  #66CCFF

@column result_set_qc_id  Internal ID
@column result_set_id     @link result set ID
@column analysis_id       @link analysis ID
@column category
@column qc_passed_reads
@column qc_failed_reads
@column path
@column bam_file

@see result_set
@see analysis
*/

DROP TABLE IF EXISTS `result_set_qc_flagstats`;
CREATE TABLE `result_set_qc_flagstats` (
  `result_set_qc_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `result_set_id` int(10) unsigned DEFAULT NULL,
  `analysis_id` smallint(5) unsigned DEFAULT NULL,
  `category` varchar(100) NOT NULL,
  `qc_passed_reads` int(10) unsigned DEFAULT NULL,
  `qc_failed_reads` int(10) unsigned DEFAULT NULL,
  `path` varchar(512) NOT NULL,
  `bam_file` varchar(512) NOT NULL,
  PRIMARY KEY (`result_set_qc_id`),
  UNIQUE KEY `name_exp_idx` (`result_set_qc_id`,`category`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/**
@table  result_set_qc_phantom_peak
@desc
@colour  #66CCFF

@column result_set_qc_phantom_peak_id  Internal ID
@column analysis_id                    @link analysis ID
@column result_set_id                  @link result set ID
@column filename
@column numReads
@column estFragLen
@column estFragLen2
@column estFragLen3
@column corr_estFragLen
@column corr_estFragLen2
@column corr_estFragLen3
@column phantomPeak
@column corr_phantomPeak
@column argmin_corr
@column min_corr
@column NSC
@column RSC
@column QualityTag
@column path

@see analysis
@see result_set
*/

DROP TABLE IF EXISTS `result_set_qc_phantom_peak`;
CREATE TABLE `result_set_qc_phantom_peak` (
  `result_set_qc_phantom_peak_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `analysis_id` smallint(5) unsigned DEFAULT NULL,
  `result_set_id` int(10) unsigned NOT NULL,
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
  PRIMARY KEY (`result_set_qc_phantom_peak_id`),
  KEY `filename_idx` (`filename`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/**
@table  result_set_input

@desc   Many to many table for linking between result_set (alignments) and input_subset (fastq files). Fastq files are supporting sets for alignments and this table is used to link them up. The fastq files that are joined to the result_set in this table are the ones that were used to create the alignment.

@colour  #66CCFF

@column result_set_input_id Internal ID
@column result_set_id       @link result_set ID
@column table_id            The dbID for the object supporting the result_set. Since these are always fastq files in the input_subset table, this column has input_subset ids only.
@column table_name          This is always set to input_subset.

@see result_set
@see input_subset
*/

DROP TABLE IF EXISTS `result_set_input`;
CREATE TABLE `result_set_input` (
  `result_set_input_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `result_set_id` int(10) unsigned NOT NULL,
  `table_id` int(10) unsigned NOT NULL,
  `table_name` enum('input_subset') DEFAULT NULL,
  PRIMARY KEY (`result_set_input_id`,`result_set_id`),
  UNIQUE KEY `rset_table_idname_idx` (`result_set_id`,`table_id`,`table_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/**
@table  dbfile_registry
@colour  #66CCFF

@desc   This generic table contains a simple registry of paths to support
        flat file (DBFile) access. This should be left joined from the
        relevant adaptor e.g. ResultSetAdaptor.

@column table_id   Primary key of linked dbfile entity e.g. @link result_set or @link analysis
@column table_name Name of linked table
@column path       Either a full filepath or a directory which the API will use to build the filepath

@see result_set
@see analysis
*/


DROP TABLE IF EXISTS `dbfile_registry`;
CREATE TABLE `dbfile_registry` (
  `table_id` int(10) unsigned NOT NULL,
  `table_name` varchar(32) NOT NULL,
  `path` varchar(255) NOT NULL,
  `file_type` enum('BAM','BAMCOV','BIGBED','BIGWIG','VCF','CRAM','DIR') NOT NULL DEFAULT 'BAM',
  `md5sum` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`table_id`,`table_name`,`file_type`),
  UNIQUE KEY `table_id_name_path_idx` (`table_id`,`table_name`,`path`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/**
@table  input_subset
@desc   The name is not descriptive of its content, think of it as: "Fastq files from a sequencing run". The objects stored here are similar to ENA's run: http://www.ebi.ac.uk/ena/submit/preparing-xmls#run Every row in the table represents a fastq file. Fastq files link to the experiments from which they were created. Fastq files from one experiment are grouped into technical and biological replicates. If a sequencing run from one experiment generated multiple fastq files, then the technical and biological replicate numbers will be identical. Fastq files are linked to the method by which they were generated via the analysis_id column.
@colour  #66CCFF

@column input_subset_id  Internal ID
@column analysis_id      @link analysis ID The analysis column links the sequencing run to the method that was used to generate it. The current analyses used are: ChIP-Seq, DNase-Seq and FAIRE. Fastq files from sequencing controls are registered as ChIP-Seq as well.
@column epigenome_id     @link epigenome ID The epigenome that was sequenced to generate this fastq file. This is similar to ENA's sample: http://www.ebi.ac.uk/ena/submit/preparing-xmls#sample
@column experiment_id    @link experiment ID
@column feature_type_id  @link feature_type  ID: The type of assay used to generate the files from this sequencing run. Typical assays are: DNase1, CTCF, H3K4me3, PolII, H3K27me3, H3K36me3, H3K27ac, H3K4me1, NFKB, H4K20me1, H3K9ac, H3K4me2, H3K9me3 or FAIRE. Controls are linked to WCE. WCE stands for "Whole Cell Extract".
@column name             This is the name of the fastq file. It is the base name only, so it is not useful for finding the file on the file system. Sometimes the extension is missing. If you want to find the fastq file you have to join to the input_subset_tracking table and use the column local_url.
@column biological_replicate  Number of the biological replicate.
@column technical_replicate   Number of the technical replicate. There can be more than one biological or technical replicate with the same number. In that case the sequencing run produced more than one fastq file.
@column is_control            Indicates whether the files from this sequencing run are controls. This column is redundant, it should always coincide with the is_control column of the experiment it links to.

@see analysis
@see epigenome
@see experiment
@see feature_type

*/

DROP TABLE IF EXISTS `input_subset`;
CREATE TABLE `input_subset` (
  `input_subset_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `epigenome_id` int(10) unsigned DEFAULT NULL,
  `experiment_id` int(10) unsigned NOT NULL,
  `feature_type_id` int(10) unsigned NOT NULL,
  `name` varchar(300) NOT NULL,
  `biological_replicate` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `technical_replicate` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `is_control` tinyint(3) unsigned NOT NULL,
  `analysis_id` smallint(5) unsigned NOT NULL,
  `read_length` int(10) DEFAULT NULL,
  `is_paired_end` tinyint(1) DEFAULT NULL,
  `paired_with` int(10) DEFAULT NULL,
  `file_size` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`input_subset_id`),
  UNIQUE KEY `name_exp_idx` (`name`,`experiment_id`),
  KEY `analysis_idx` (`analysis_id`),
  KEY `experiment_idx` (`experiment_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=100000000 AVG_ROW_LENGTH=30;


-- epigenome_id is default NULL to support flat file imports which have not defined epigenome

/**
@header Array design tables
@colour  #FF6666
@legend  #FF6666   Array design tables
*/


/**
@table  array
@desc   Contains information defining an array or array set.
@colour  #FF6666

@column array_id    Internal ID
@column name        Name of array
@column format      Format of array e.g. EXPRESSION, TILED
@column vendor      Name of array vendor e.g. AFFY
@column description Text description
@column type        Array type e.g. OLIGO, PCR
@column class       Array class e.g. AFFY_ST, ILLUMINA_INFINIUM

*/

DROP TABLE IF EXISTS `array`;
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


-- Could clean up/rename format, type and class

/**
@table  array_chip
@desc   Represents the individual array chip design as part of an array or array set.
@colour  #FF6666

@column array_chip_id   Internal ID
@column array_id        @link array ID
@column design_id       ID/Accession defined by vendor
@column name            Name of array_chip

@see array
*/

DROP TABLE IF EXISTS `array_chip`;
CREATE TABLE `array_chip` (
  `array_chip_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `design_id` varchar(100) DEFAULT NULL,
  `array_id` int(10) unsigned NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`array_chip_id`),
  UNIQUE KEY `array_design_idx` (`array_id`,`design_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/**
@table  probe_set
@desc   The table contains information about probe sets.
@colour  #FF6666

@column probe_set_id Internal ID
@column name         Name of the probe set
@column size         Integer size of the probe set i.e. how many probe is contains
@column family       Generic descriptor for probe_set e.g. ENCODE_REGIONS, RANDOM etc. Currently not used

*/

DROP TABLE IF EXISTS `probe_set`;
CREATE TABLE `probe_set` (
  `probe_set_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `size` smallint(6) unsigned NOT NULL,
  `family` varchar(20) DEFAULT NULL,
  `array_chip_id` int(10) DEFAULT NULL,
  PRIMARY KEY (`probe_set_id`),
  KEY `name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- Clashing names may(unlikely) exist between array vendors, this is currently allowed
-- and handled with the API via the probe associations

DROP TABLE IF EXISTS `probe_set_transcript`;
CREATE TABLE `probe_set_transcript` (
  `probe_set_transcript_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `probe_set_id` int(10) unsigned NOT NULL,
  `stable_id` varchar(128) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`probe_set_transcript_id`),
  KEY `probe_set_transcript_id_idx` (`probe_set_transcript_id`),
  KEY `probe_set_transcript_stable_id_idx` (`stable_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/**
@table  probe
@desc   Defines individual probe designs across one or more array_chips. Note: The probe sequence is not stored.
@colour  #FF6666

@column probe_id      Internal ID
@column array_chip_id @link array_chip ID
@column probe_set_id  @link probe_set ID
@column name          Name of the probe set
@column length        Integer bp length of the probe
@column class         Class of the probe e.g. CONTROL, EXPERIMENTAL etc.
@column description   Text description

@see array_chip
@see probe_set
*/

DROP TABLE IF EXISTS `probe`;
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `probe_seq`;
CREATE TABLE `probe_seq` (
  `probe_seq_id` int(10) NOT NULL AUTO_INCREMENT,
  `sequence` text NOT NULL,
  `sequence_upper` text NOT NULL,
  `sequence_upper_sha1` char(40) NOT NULL,
  PRIMARY KEY (`probe_seq_id`),
  UNIQUE KEY `sequence_upper_sha1` (`sequence_upper_sha1`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `probe_transcript`;
CREATE TABLE `probe_transcript` (
  `probe_transcript_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `probe_id` int(10) unsigned NOT NULL,
  `stable_id` varchar(128) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`probe_transcript_id`),
  KEY `probe_transcript_id` (`probe_transcript_id`),
  KEY `probe_transcript_stable_id_idx` (`stable_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/**
@header Experiment tables
@desc   These define the experimental meta and raw data.
@colour  #00FF00
@legend  #00FF00 Experiment tables
*/


/**
@table  experiment
@desc   Represents a sequencing experiment. Sequencing runs (input_subsets) link to this.
@colour  #00FF00

@column experiment_id           Internal ID
@column epigenome_id            @link epigenome ID
@column experimental_group_id   @link experimental_group ID
@column control_id              @link experiment ID
@column is_control              Boolean, true means that this experiment is a control.
@column feature_type_id         @link feature_type table ID
@column description             Text description
@column name                    Name of experiment
@column primary_design_type     e.g. binding_site_identification, preferably EFO term
@column archive_id              ENA experiment identifier enabling access to specific raw data
@column display_url             Http link to source file

@see epigenome
@see experimental_group
@see feature_type
@see mage_xml
*/

DROP TABLE IF EXISTS `experiment`;
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- Can probably remove now date (and primary_design_type?) as we don't support this level of meta data
-- also have associated_design_types/experimental_design table, containing MGED/EFO ontology types?



/**
@table  experimental_group
@desc   Think: Consortium or laboratory that produced sequencing experiments (@see experiment).
@colour  #00FF00

@column experimental_group_id  Internal ID
@column contact                Contact details e.g. email
@column description            Text description
@column is_project             Large or small scale project
@column location               Geographic location of group
@column name                   Name of group
@column url                    Url for Project page

*/

DROP TABLE IF EXISTS `experimental_group`;
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/**
@header  Ancilliary tables
@desc    These contain data types which are used across many of the above tables and
         are quite often denormalised to store generic associations to several table,
         this avoids the need for multiple sets of similar tables. Some of these tables
         have been omitted from the schema diagram.
@colour  #808000
*/


/**
@table  epigenome
@desc   The epigenomes known in Ensembl regulation.
@colour  #808000

@column epigenome_id         Internal ID
@column name                 Microformat to drive the ChIP-seq pipeline, used internally only.
@column display_label        Short display label, used in the ensembl browser/website
@column description          Text description, used in the z-menu that appears when hovering over the epigenome name
@column production_name      Used to generate file or directory names
@column gender               Gender i.e. 'male', 'female', 'hermaphrodite' or 'mixed'
@column ontology_accession   External accession id
@column ontology             The resource the ontology_accession refers to, currently either EFO or CL
@column tissue               Tissue origin/type

*/

DROP TABLE IF EXISTS `epigenome`;
CREATE TABLE `epigenome` (
  `epigenome_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(120) NOT NULL,
  `display_label` varchar(30) NOT NULL,
  `description` varchar(80) DEFAULT NULL,
  `production_name` varchar(120) DEFAULT NULL,
  `gender` enum('male','female','hermaphrodite','mixed','unknown') DEFAULT NULL,
  `ontology_accession` varchar(20) DEFAULT NULL,
  `ontology` enum('EFO','CL') DEFAULT NULL,
  `tissue` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`epigenome_id`),
  UNIQUE KEY `name_idx` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/**
@table  status
@desc   Denormalised table associating funcgen records with a status.
@colour  #808000

@column table_id        Table ID of associated record
@column status_name_id  @link status_name ID
@column table_name      Table name of associated record


@see status_name
*/

DROP TABLE IF EXISTS `status`;
CREATE TABLE `status` (
  `table_id` int(10) unsigned NOT NULL DEFAULT '0',
  `table_name` varchar(32) NOT NULL DEFAULT '',
  `status_name_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`table_id`,`table_name`,`status_name_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- 32 is max length for mysql table name


/**
@table  status_name
@desc   Simple table to predefine name of status.
@colour  #808000

@column status_name_id  Internal ID
@column name            Name of status e.g. IMPORTED, DISPLAYBLE etc.

*/

DROP TABLE IF EXISTS `status_name`;
CREATE TABLE `status_name` (
  `status_name_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(60) DEFAULT NULL,
  PRIMARY KEY (`status_name_id`),
  UNIQUE KEY `status_name_idx` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;



/**

@header  Core tables
@desc    These are exact clones of the corresponding core schema tables, hence have been omitted
         from the schema diagram. See <a href='../core/core_schema.html'>core schema docs</a> for more details.
@colour  #000000
@legend  #000000 Core/Core like tables (Omited from schema diagram)
*/

/**
@table analysis
@desc Usually describes a program and some database that together are used to create a feature on a piece of sequence.
Each feature is marked with an analysis_id. The most important column is logic_name, which is used by the webteam to render a feature
 correctly on contigview (or even retrieve the right feature).
Logic_name is also used in the pipeline to identify the analysis which has to run in a given status of the pipeline.
The module column tells the pipeline which Perl module does the whole analysis, typically a RunnableDB module.
@colour  #000000

@column analysis_id                 Internal ID
@column created                     Date to distinguish newer and older versions off the same analysis.
@column logic_name                  String to identify the analysis. Used mainly inside pipeline.
@column db                          Database name.
@column db_version                  Database version.
@column db_file                     File system location of the database.
@column program                     The binary used to create a feature.
@column program_version             The binary version.
@column program_file                File system location of the binary.
@column parameters                  A parameter string which is processed by the perl module.
@column module                      Perl module names (RunnableDBS usually) executing this analysis.
@column module_version              Perl module version.
@column gff_source                  How to make a gff dump from features with this analysis.
@column gff_feature                 How to make a gff dump from features with this analysis.

@see analysis_description

*/


DROP TABLE IF EXISTS `analysis`;
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/**
@table analysis_description
@desc Allows the storage of a textual description of the analysis, as well as a "display label", primarily for the EnsEMBL web site.
@colour  #000000

@column analysis_id            Foreign key references to the @link analysis table.
@column description            Textual description of the analysis.
@column display_label          Display label for the EnsEMBL web site.
@column displayable            Flag indicating if the analysis description is to be displayed on the EnsEMBL web site.
@column web_data               Other data used by the EnsEMBL web site.

@see analysis

*/


DROP TABLE IF EXISTS `analysis_description`;
CREATE TABLE `analysis_description` (
  `analysis_id` smallint(5) unsigned NOT NULL,
  `description` text,
  `display_label` varchar(255) NOT NULL,
  `displayable` tinyint(1) NOT NULL DEFAULT '1',
  `web_data` text,
  UNIQUE KEY `analysis_idx` (`analysis_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/**
@table meta
@desc Stores data about the data in the current schema. Unlike other tables, data in the meta table is stored as key-value pairs. These data include details about the database, RegulatoryBuild and patches.  The species_id field of the meta table is used in multi-species databases and makes it possible to have species-specific meta key-value pairs.  The species-specific meta key-value pairs needs to be repeated for each species_id.  Entries in the meta table that are not specific to any one species, such as the schema.version key and any other schema-related information must have their species_id field set to NULL
. The default species_id, and the only species_id value allowed in single-species databases, is 1.
@colour  #000000


@column meta_id                    Internal identifier.
@column species_id                 Indentifies the species for multi-species databases.
@column meta_key                   Name of the meta entry, e.g. "schema_version".
@column meta_value                 Corresponding value of the key, e.g. "61".

*/


DROP TABLE IF EXISTS `meta`;
CREATE TABLE `meta` (
  `meta_id` int(10) NOT NULL AUTO_INCREMENT,
  `species_id` int(10) unsigned DEFAULT '1',
  `meta_key` varchar(46) NOT NULL,
  `meta_value` varchar(950) NOT NULL,
  PRIMARY KEY (`meta_id`),
  UNIQUE KEY `species_key_value_idx` (`species_id`,`meta_key`,`meta_value`),
  KEY `species_value_idx` (`species_id`,`meta_value`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


-- Add necessary meta values
INSERT INTO meta (meta_key, meta_value) VALUES ('schema_type', 'funcgen');
INSERT INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'schema_version', '90');

-- Update and remove these for each release to avoid erroneous patching
INSERT INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'patch', 'patch_89_90_a.sql|schema_version');
INSERT INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'patch', 'patch_89_90_b.sql|probe feature columns');
INSERT INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'patch', 'patch_89_90_c.sql|Adds stable id index for probe_transcript table');
INSERT INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'patch', 'patch_89_90_d.sql|Adds stable id index for probe_set_transcript table');


/**
@table meta_coord
@desc Describes which co-ordinate systems the different feature tables use.
@colour  #000000

@column table_name              Ensembl database table name.
@column coord_system_id         Table ID for @link coord_system
@column max_length              Longest sequence length.

@see coord_system

*/

DROP TABLE IF EXISTS `meta_coord`;
CREATE TABLE `meta_coord` (
  `table_name` varchar(40) NOT NULL,
  `coord_system_id` int(10) unsigned NOT NULL,
  `max_length` int(11) DEFAULT NULL,
  UNIQUE KEY `table_name` (`table_name`,`coord_system_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/**
@table  associated_xref
@desc   This table associates extra associated annotations with a given ontology xref evidence and source under a specific condition.   For GO this allows qualifiers (with/from) or annotation extensions to be added to a given ontology annotation.
@colour  #000000

@column associated_xref_id Associated xref id. Primary key, internal identifier
@column object_xref_id Object xref id this associated xref is linked to. Foreign key linked to the @link object_xref table
@column xref_id Xref which is the associated term. Foreign key linked to the @link xref table
@column source_xref_id Xref which is source of this association. Foreign key linked to the @link xref table
@column condition_type The type of condition this link occurs in e.g. evidence, from, residue or assigned_by
@column associated_group_id Foreign key to allow for @link associated_group
@column rank The rank in which the association occurs within an @link associated_group

@see object_xref
@see associcated_group
@see xref
*/
DROP TABLE IF EXISTS `associated_xref`;
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

/**
@table  associated_group
@desc   Groups together xref associations under a single description. Used when more than one associated xref term must be used to describe a condition
@colour  #000000

@column associated_group_id Associated group id. Primary key, internal identifier
@column description Optional description for this group
*/
DROP TABLE IF EXISTS `associated_group`;
CREATE TABLE `associated_group` (
  `associated_group_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `description` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`associated_group_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/**
@table identity_xref
@desc Describes how well a particular xref object matches the EnsEMBL object.
@colour  #000000

@column object_xref_id     Foreign key references to the @link object_xref table.
@column xref_identity      Percentage identity.
@column ensembl_identity   Percentage identity.
@column xref_start         Xref sequence start.
@column xref_end           Xref sequence end.
@column ensembl_start      Ensembl sequence start.
@column ensembl_end        Ensembl sequence end.
@column cigar_line         Used to encode gapped alignments.
@column score              Match score.
@column evalue             Match evalue.

@see object_xref

*/


DROP TABLE IF EXISTS `identity_xref`;
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


/**
@table external_synonym
@desc Some xref objects can be referred to by more than one name. This table relates names to xref IDs.
@colour  #000000

@column xref_id           Foreign key references @link xref table
@column synonym           Synonym

@see xref

*/


DROP TABLE IF EXISTS `external_synonym`;
CREATE TABLE `external_synonym` (
  `xref_id` int(10) unsigned NOT NULL,
  `synonym` varchar(100) NOT NULL,
  PRIMARY KEY (`xref_id`,`synonym`),
  KEY `name_index` (`synonym`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AVG_ROW_LENGTH=20;


/**
@table external_db
@desc Stores data about the external databases in which the objects described in the xref table are stored.
@colour  #000000

@column external_db_id              Internal identifier.
@column db_name                     Database name.
@column db_release                  Database release.
@column status                      Status, e.g. 'KNOWNXREF','KNOWN','XREF','PRED','ORTH','PSEUDO'.
@column dbprimary_acc_linkable      Indicates if primary a accession can be linked to from the EnsEMBL web site.
@column priority                    Determines which one of the xrefs will be used as the gene name.
@column db_display_name             Database display name.
@column type                        Type, e.g. 'ARRAY', 'ALT_TRANS', 'ALT_GENE', 'MISC', 'LIT', 'PRIMARY_DB_SYNONYM', 'ENSEMBL'.
@column secondary_db_name           Secondary database name.
@column secondary_db_table          Secondary database table.
@column description                 Description.


@see xref
@see unmapped_object

*/


DROP TABLE IF EXISTS `external_db`;
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AVG_ROW_LENGTH=80;


/**
@table ontology_xref
@desc This table associates ontology terms/accessions to Ensembl objects (primarily EFO/SO). NOTE: Currently not in use
@colour  #000000

@column object_xref_id          Foreign key references to the @link object_xref table.
@column source_xref_id          Foreign key references to the @link xref table.
@column linkage_type            Defines type of linkage

@see object_xref

*/


DROP TABLE IF EXISTS `ontology_xref`;
CREATE TABLE `ontology_xref` (
  `object_xref_id` int(10) unsigned NOT NULL DEFAULT '0',
  `source_xref_id` int(10) unsigned DEFAULT NULL,
  `linkage_type` enum('IC','IDA','IEA','IEP','IGI','IMP','IPI','ISS','NAS','ND','TAS','NR','RCA') NOT NULL,
  UNIQUE KEY `object_xref_id_2` (`object_xref_id`,`source_xref_id`,`linkage_type`),
  KEY `object_xref_id` (`object_xref_id`),
  KEY `source_xref_id` (`source_xref_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- This is just an empty to table to avoid having to rework all the core sql and API to accomodate eFG specific xref schema

/**
@table unmapped_reason
@desc Describes the reason why a mapping failed.
@colour  #000000

@column unmapped_reason_id           Internal identifier.
@column summary_description          Summarised description.
@column full_description             Full description.

@see unmapped_object
*/

DROP TABLE IF EXISTS `unmapped_reason`;
CREATE TABLE `unmapped_reason` (
  `unmapped_reason_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `summary_description` varchar(255) DEFAULT NULL,
  `full_description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`unmapped_reason_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/**

@header  Core like tables
@desc    These are almost exact clones of the corresponding core schema tables. Some contain extra fields or different enum values to support the funcgen schema. These have been omitted from the schema diagram.
@colour  #000000

*/

/**
@table xref
@desc Holds data about objects which are external to EnsEMBL, but need to be associated with EnsEMBL objects.
Information about the database that the external object is stored in is held in the external_db table entry referred to by the external_db column.

@column xref_id                 Primary key, internal identifier.
@column external_db_id          Foreign key references to the @link external_db table.
@column dbprimary_acc           Primary accession number.
@column display_label           Display label for the EnsEMBL web site.
@column version                 Object version.
@column description             Object description.
@column info_type               'PROJECTION', 'MISC', 'DEPENDENT','DIRECT', 'SEQUENCE_MATCH','INFERRED_PAIR', 'PROBE','UNMAPPED', 'COORDINATE_OVERLAP', 'CHECKSUM'.
@column info_text               Text

@see external_db
@see external_synonym

*/


DROP TABLE IF EXISTS `xref`;
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AVG_ROW_LENGTH=100;



/**
@table object_xref
@desc Describes links between Ensembl objects and objects held in external databases.  The Ensembl object can be one of several types; the type is held in the ensembl_object_type column.  The ID of the particular Ensembl gene, translation or whatever is given in the ensembl_id column.  The xref_id points to the entry in the xref table that holds data about the external object.  Each Ensembl object can be associated with zero or more xrefs. An xref object can be associated with one or more Ensembl objects.
@colour  #000000

@column object_xref_id            Internal identifier.
@column ensembl_id                Foreign key references to the ensembl_object_type table e.g. @link probe_set
@column ensembl_object_type       Ensembl object type e.g ProbeSet etc.
@column xref_id                   Foreign key references to the @link xref table.
@column linkage_annotation        Additional annotation on the linkage.
@column analysis_id               Foreign key references to the @link analysis table.

@see xref
@see identity_xref

*/


DROP TABLE IF EXISTS `object_xref`;
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=100000000 AVG_ROW_LENGTH=40;

/**
@table unmapped_object
@desc Describes why a particular external entity was not mapped to an ensembl one.
@colour  #000000

@column unmapped_object_id         Internal identifier.
@column type                       UnmappedObject type e.g. probe2transcript
@column analysis_id                Foreign key references to the @link analysis table.
@column external_db_id             Foreign key references to the @link external_db table.
@column identifier                 External database identifier.
@column unmapped_reason_id         Foreign key references to the @link unmapped_reason table.
@column query_score                Actual mapping query score.
@column target_score               Target mapping query score.
@column ensembl_id                 Foreign key references the table_if of the Ensembl object table e.g. @link probe_set
@column ensembl_object_type        Ensembl object type e.g. ProbeSet
@column parent                     Foreign key references to the @link dependent_xref table, in case the unmapped object is dependent on a primary external reference which wasn't mapped to an ensembl one. Not currently used for efg.

@see unmapped_reason
@see external_db
@see analysis
*/



DROP TABLE IF EXISTS `unmapped_object`;
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
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/**
@table coord_system
@desc Stores information about the available co-ordinate systems for the species identified through the species_id field.
For each species, there must be one co-ordinate system that has the attribute "top_level" and one that has the attribute "sequence_level".
NOTE: This has been extended from the core implementation to support multiple assemblies by referencing multiple core DBs.
@colour  #000000

@column coord_system_id      Internal identifier
@column name                 Co-oridinate system name, e.g. 'chromosome', 'contig', 'scaffold' etc.
@column version              Assembly
@column rank                 Co-oridinate system rank
@column attrib               Co-oridinate system attrib (e.g. "top_level", "sequence_level")
@column schema_build         Indentifies the schema_build version for the source core DB
@column core_coord_system_id Table ID of the coord_system in the source core DB
@column species_id           Indentifies the species for multi-species databases
@column is_current           This flags which coord_system entries are current with respect to mart(/website)

@see seq_region
@see meta_coord

*/


DROP TABLE IF EXISTS `coord_system`;
CREATE TABLE `coord_system` (
  `coord_system_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(40) NOT NULL,
  `version` varchar(255) NOT NULL DEFAULT '',
  `rank` int(11) NOT NULL,
  `attrib` set('default_version','sequence_level') DEFAULT NULL,
  `schema_build` varchar(10) NOT NULL DEFAULT '',
  `core_coord_system_id` int(10) NOT NULL,
  `species_id` int(10) NOT NULL DEFAULT '1',
  `is_current` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`name`,`version`,`schema_build`,`species_id`),
  KEY `name_version_idx` (`name`,`version`),
  KEY `coord_species_idx` (`species_id`),
  KEY `coord_system_id_idx` (`coord_system_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- Currently does not use attrib or rank


/**
@table seq_region
@desc Stores information about sequence regions from various core DBs.
@colour  #000000

@column seq_region_id            Internal identifier.
@column name                     Sequence region name.
@column coord_system_id          Foreign key references to the @link coord_system table.
@column core_seq_region_id       Table ID of the seq_region in the source core DB
@column schema_build             Indentifies the schema_build version for the source core DB

@see coord_system
*/



DROP TABLE IF EXISTS `seq_region`;
CREATE TABLE `seq_region` (
  `seq_region_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `coord_system_id` int(10) unsigned NOT NULL,
  `core_seq_region_id` int(10) unsigned NOT NULL,
  `schema_build` varchar(10) NOT NULL DEFAULT '',
  PRIMARY KEY (`name`,`schema_build`,`coord_system_id`),
  KEY `coord_system_id` (`coord_system_id`),
  KEY `seq_region_id_idx` (`seq_region_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- it maybe possible to have 2 seq_regions on different levels with the same name
-- hence schema_build denormalisation

-- Name is only required to enable us to add new seq_regions to the correct seq_region_id
-- It will never be used to retrieve a slice as we do that via the core DB
-- Usage: Pull back seq_region_id based schema_build and core_seq_region_id




