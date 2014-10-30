-- Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

CREATE TABLE assembly (

  asm_seq_region_id           INT(10) UNSIGNED NOT NULL,
  cmp_seq_region_id           INT(10) UNSIGNED NOT NULL,
  asm_start                   INT(10) NOT NULL,
  asm_end                     INT(10) NOT NULL,
  cmp_start                   INT(10) NOT NULL,
  cmp_end                     INT(10) NOT NULL,
  ori                         TINYINT  NOT NULL,

  KEY cmp_seq_region_idx (cmp_seq_region_id),
  KEY asm_seq_region_idx (asm_seq_region_id, asm_start),
  UNIQUE KEY all_idx (asm_seq_region_id, cmp_seq_region_id, asm_start, asm_end, cmp_start, cmp_end, ori)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE assembly_exception (

  assembly_exception_id       INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  seq_region_id               INT(10) UNSIGNED NOT NULL,
  seq_region_start            INT(10) UNSIGNED NOT NULL,
  seq_region_end              INT(10) UNSIGNED NOT NULL,
  exc_type                    ENUM('HAP', 'PAR',
                                'PATCH_FIX', 'PATCH_NOVEL') NOT NULL,
  exc_seq_region_id           INT(10) UNSIGNED NOT NULL,
  exc_seq_region_start        INT(10) UNSIGNED NOT NULL,
  exc_seq_region_end          INT(10) UNSIGNED NOT NULL,
  ori                         INT NOT NULL,

  PRIMARY KEY (assembly_exception_id),
  KEY sr_idx (seq_region_id, seq_region_start),
  KEY ex_idx (exc_seq_region_id, exc_seq_region_start)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE coord_system (

  coord_system_id             INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  species_id                  INT(10) UNSIGNED NOT NULL DEFAULT 1,
  name                        VARCHAR(40) NOT NULL,
  version                     VARCHAR(255) DEFAULT NULL,
  rank                        INT NOT NULL,
  attrib                      SET('default_version', 'sequence_level'),

  PRIMARY   KEY (coord_system_id),
  UNIQUE    KEY rank_idx (rank, species_id),
  UNIQUE    KEY name_idx (name, version, species_id),
            KEY species_idx (species_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE data_file (
  data_file_id      INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  coord_system_id   INT(10) UNSIGNED NOT NULL,
  analysis_id       SMALLINT UNSIGNED NOT NULL,
  name              VARCHAR(100) NOT NULL,
  version_lock      TINYINT(1) DEFAULT 0 NOT NULL,
  absolute          TINYINT(1) DEFAULT 0 NOT NULL,
  url               TEXT,
  file_type         ENUM('BAM','BIGBED','BIGWIG','VCF'),

  PRIMARY KEY (data_file_id),
  UNIQUE KEY df_unq_idx(coord_system_id, analysis_id, name, file_type),
  INDEX df_name_idx(name),
  INDEX df_analysis_idx(analysis_id)
) COLLATE=latin1_swedish_ci ENGINE=MyISAM;

CREATE TABLE dna (

  seq_region_id       INT(10) UNSIGNED NOT NULL,
  sequence            LONGTEXT NOT NULL,

  PRIMARY KEY (seq_region_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM MAX_ROWS=750000 AVG_ROW_LENGTH=19000;

CREATE TABLE genome_statistics(

  genome_statistics_id     INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  statistic                VARCHAR(128) NOT NULL,
  value                    INT(10) UNSIGNED DEFAULT '0' NOT NULL,
  species_id               INT UNSIGNED DEFAULT 1,
  attrib_type_id           INT(10) UNSIGNED DEFAULT NULL,
  timestamp                DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',

  PRIMARY KEY (genome_statistics_id),
  UNIQUE KEY stats_uniq(statistic, attrib_type_id, species_id),
  KEY stats_idx (statistic, attrib_type_id, species_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;

CREATE TABLE karyotype (
  karyotype_id                INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  seq_region_id               INT(10) UNSIGNED NOT NULL,
  seq_region_start            INT(10) UNSIGNED NOT NULL,
  seq_region_end              INT(10) UNSIGNED NOT NULL,
  band                        VARCHAR(40) DEFAULT NULL,
  stain                       VARCHAR(40) DEFAULT NULL,

  PRIMARY KEY (karyotype_id),
  KEY region_band_idx (seq_region_id,band)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE IF NOT EXISTS meta (

  meta_id                     INT NOT NULL AUTO_INCREMENT,
  species_id                  INT UNSIGNED DEFAULT 1,
  meta_key                    VARCHAR(40) NOT NULL,
  meta_value                  VARCHAR(255) BINARY,

  PRIMARY   KEY (meta_id),
  UNIQUE    KEY species_key_value_idx (species_id, meta_key, meta_value),
            KEY species_value_idx (species_id, meta_value)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


# Add schema type and schema version to the meta table.
INSERT INTO meta (species_id, meta_key, meta_value) VALUES
  (NULL, 'schema_type',     'core'),
  (NULL, 'schema_version',  '78');

# Patches included in this schema file:
# NOTE: At start of release cycle, remove patch entries from last release.
# NOTE: Avoid line-breaks in values.
INSERT INTO meta (species_id, meta_key, meta_value)
  VALUES (NULL, 'patch', 'patch_77_78_a.sql|schema_version');
INSERT INTO meta (species_id, meta_key, meta_value)
  VALUES (NULL, 'patch', 'patch_77_78_b.sql|source_column_increase');
INSERT INTO meta (species_id, meta_key, meta_value) 
  VALUES (NULL, 'patch', 'patch_77_78_c.sql|Change unmapped_reason_id from smallint to int');


CREATE TABLE meta_coord (

  table_name                  VARCHAR(40) NOT NULL,
  coord_system_id             INT(10) UNSIGNED NOT NULL,
  max_length                  INT,

  UNIQUE KEY cs_table_name_idx (coord_system_id, table_name)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE seq_region (

  seq_region_id               INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  name                        VARCHAR(40) NOT NULL,
  coord_system_id             INT(10) UNSIGNED NOT NULL,
  length                      INT(10) UNSIGNED NOT NULL,

  PRIMARY KEY (seq_region_id),
  UNIQUE KEY name_cs_idx (name, coord_system_id),
  KEY cs_idx (coord_system_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE seq_region_synonym (

  seq_region_synonym_id       INT UNSIGNED NOT NULL  AUTO_INCREMENT,
  seq_region_id               INT(10) UNSIGNED NOT NULL,
  synonym                     VARCHAR(40) NOT NULL,
  external_db_id              INTEGER UNSIGNED,

  PRIMARY KEY (seq_region_synonym_id),
  UNIQUE KEY syn_idx (synonym),
  KEY seq_region_idx (seq_region_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE seq_region_attrib (

  seq_region_id               INT(10) UNSIGNED NOT NULL DEFAULT '0',
  attrib_type_id              SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  value                       TEXT NOT NULL,

  KEY type_val_idx (attrib_type_id, value(40)),
  KEY val_only_idx (value(40)),
  KEY seq_region_idx (seq_region_id),
  UNIQUE KEY region_attribx (seq_region_id, attrib_type_id, value(500))

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;

CREATE TABLE alt_allele (
        alt_allele_id INT UNSIGNED AUTO_INCREMENT, 
        alt_allele_group_id INT UNSIGNED NOT NULL, 
        gene_id INT UNSIGNED NOT NULL,

        PRIMARY KEY (alt_allele_id),
        UNIQUE KEY gene_idx (gene_id),
        KEY (gene_id,alt_allele_group_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;

CREATE TABLE alt_allele_attrib (
         alt_allele_id INT UNSIGNED,
         attrib ENUM('IS_REPRESENTATIVE',
                     'IS_MOST_COMMON_ALLELE',
                     'IN_CORRECTED_ASSEMBLY',
                     'HAS_CODING_POTENTIAL',
                     'IN_ARTIFICIALLY_DUPLICATED_ASSEMBLY',
                     'IN_SYNTENIC_REGION',
                     'HAS_SAME_UNDERLYING_DNA_SEQUENCE',
                     'IN_BROKEN_ASSEMBLY_REGION',
                     'IS_VALID_ALTERNATE',
                     'SAME_AS_REPRESENTATIVE',
                     'SAME_AS_ANOTHER_ALLELE',
                     'MANUALLY_ASSIGNED',
                     'AUTOMATICALLY_ASSIGNED'),

        KEY aa_idx (alt_allele_id,attrib)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE alt_allele_group (

         alt_allele_group_id INT UNSIGNED AUTO_INCREMENT,

         PRIMARY KEY (alt_allele_group_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE IF NOT EXISTS analysis (

  analysis_id                 SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  created                     datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  logic_name                  VARCHAR(128) NOT NULL,
  db                          VARCHAR(120),
  db_version                  VARCHAR(40),
  db_file                     VARCHAR(120),
  program                     VARCHAR(80),
  program_version             VARCHAR(40),
  program_file                VARCHAR(80),
  parameters                  TEXT,
  module                      VARCHAR(80),
  module_version              VARCHAR(40),
  gff_source                  VARCHAR(40),
  gff_feature                 VARCHAR(40),

  PRIMARY KEY (analysis_id),
  UNIQUE KEY logic_name_idx (logic_name)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE IF NOT EXISTS analysis_description (

  analysis_id                  SMALLINT UNSIGNED NOT NULL,
  description                  TEXT,
  display_label                VARCHAR(255) NOT NULL,
  displayable                  BOOLEAN NOT NULL DEFAULT 1,
  web_data                     TEXT,

  UNIQUE KEY analysis_idx (analysis_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE attrib_type (

  attrib_type_id              SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
  code                        VARCHAR(20) NOT NULL DEFAULT '',
  name                        VARCHAR(255) NOT NULL DEFAULT '',
  description                 TEXT,

  PRIMARY KEY (attrib_type_id),
  UNIQUE KEY code_idx (code)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE dna_align_feature (

  dna_align_feature_id        INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  seq_region_id               INT(10) UNSIGNED NOT NULL,
  seq_region_start            INT(10) UNSIGNED NOT NULL,
  seq_region_end              INT(10) UNSIGNED NOT NULL,
  seq_region_strand           TINYINT(1) NOT NULL,
  hit_start                   INT NOT NULL,
  hit_end                     INT NOT NULL,
  hit_strand                  TINYINT(1) NOT NULL,
  hit_name                    VARCHAR(40) NOT NULL,
  analysis_id                 SMALLINT UNSIGNED NOT NULL,
  score                       DOUBLE,
  evalue                      DOUBLE,
  perc_ident                  FLOAT,
  cigar_line                  TEXT,
  external_db_id              INTEGER UNSIGNED,
  hcoverage                   DOUBLE,
  external_data               TEXT,

  PRIMARY KEY (dna_align_feature_id),
  KEY seq_region_idx (seq_region_id, analysis_id, seq_region_start, score),
  KEY seq_region_idx_2 (seq_region_id, seq_region_start),
  KEY hit_idx (hit_name),
  KEY analysis_idx (analysis_id),
  KEY external_db_idx (external_db_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM MAX_ROWS=100000000 AVG_ROW_LENGTH=80;


CREATE TABLE exon (

  exon_id                     INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  seq_region_id               INT(10) UNSIGNED NOT NULL,
  seq_region_start            INT(10) UNSIGNED NOT NULL,
  seq_region_end              INT(10) UNSIGNED NOT NULL,
  seq_region_strand           TINYINT(2) NOT NULL,

  phase                       TINYINT(2) NOT NULL,
  end_phase                   TINYINT(2) NOT NULL,

  is_current                  BOOLEAN NOT NULL DEFAULT 1,
  is_constitutive             BOOLEAN NOT NULL DEFAULT 0,

  stable_id                   VARCHAR(128) DEFAULT NULL,
  version                     SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  created_date                DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified_date               DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',

  PRIMARY KEY (exon_id),
  KEY seq_region_idx (seq_region_id, seq_region_start),
  KEY stable_id_idx (stable_id, version)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE exon_transcript (

  exon_id                     INT(10) UNSIGNED NOT NULL,
  transcript_id               INT(10) UNSIGNED NOT NULL,
  rank                        INT(10) NOT NULL,

  PRIMARY KEY (exon_id,transcript_id,rank),
  KEY transcript (transcript_id),
  KEY exon (exon_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE gene (

  gene_id                     INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  biotype                     VARCHAR(40) NOT NULL,
  analysis_id                 SMALLINT UNSIGNED NOT NULL,
  seq_region_id               INT(10) UNSIGNED NOT NULL,
  seq_region_start            INT(10) UNSIGNED NOT NULL,
  seq_region_end              INT(10) UNSIGNED NOT NULL,
  seq_region_strand           TINYINT(2) NOT NULL,
  display_xref_id             INT(10) UNSIGNED,
  source                      VARCHAR(40) NOT NULL,
  status                      ENUM('KNOWN', 'NOVEL', 'PUTATIVE', 'PREDICTED', 'KNOWN_BY_PROJECTION', 'UNKNOWN', 'ANNOTATED'),
  description                 TEXT,
  is_current                  BOOLEAN NOT NULL DEFAULT 1,
  canonical_transcript_id     INT(10) UNSIGNED NOT NULL,
  stable_id                   VARCHAR(128) DEFAULT NULL,
  version                     SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  created_date                DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified_date               DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',

  PRIMARY KEY (gene_id),
  KEY seq_region_idx (seq_region_id, seq_region_start),
  KEY xref_id_index (display_xref_id),
  KEY analysis_idx (analysis_id),
  KEY stable_id_idx (stable_id, version),
  KEY canonical_transcript_id_idx (canonical_transcript_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE gene_attrib (

  gene_id                     INT(10) UNSIGNED NOT NULL DEFAULT '0',
  attrib_type_id              SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  value                       TEXT NOT NULL,

  KEY type_val_idx (attrib_type_id, value(40)),
  KEY val_only_idx (value(40)),
  KEY gene_idx (gene_id),
  UNIQUE KEY gene_attribx (gene_id, attrib_type_id, value(500))

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;

CREATE TABLE protein_align_feature (

  protein_align_feature_id    INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  seq_region_id               INT(10) UNSIGNED NOT NULL,
  seq_region_start            INT(10) UNSIGNED NOT NULL,
  seq_region_end              INT(10) UNSIGNED NOT NULL,
  seq_region_strand           TINYINT(1) DEFAULT '1' NOT NULL,
  hit_start                   INT(10) NOT NULL,
  hit_end                     INT(10) NOT NULL,
  hit_name                    VARCHAR(40) NOT NULL,
  analysis_id                 SMALLINT UNSIGNED NOT NULL,
  score                       DOUBLE,
  evalue                      DOUBLE,
  perc_ident                  FLOAT,
  cigar_line                  TEXT,
  external_db_id              INTEGER UNSIGNED,
  hcoverage                   DOUBLE,

  PRIMARY KEY (protein_align_feature_id),
  KEY seq_region_idx (seq_region_id, analysis_id, seq_region_start, score),
  KEY seq_region_idx_2 (seq_region_id, seq_region_start),
  KEY hit_idx (hit_name),
  KEY analysis_idx (analysis_id),
  KEY external_db_idx (external_db_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM MAX_ROWS=100000000 AVG_ROW_LENGTH=80;


CREATE TABLE protein_feature (

  protein_feature_id          INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  translation_id              INT(10) UNSIGNED NOT NULL,
  seq_start                   INT(10) NOT NULL,
  seq_end                     INT(10) NOT NULL,
  hit_start                   INT(10) NOT NULL,
  hit_end                     INT(10) NOT NULL,
  hit_name                    VARCHAR(40) NOT NULL,
  analysis_id                 SMALLINT UNSIGNED NOT NULL,
  score                       DOUBLE,
  evalue                      DOUBLE,
  perc_ident                  FLOAT,
  external_data               TEXT,
  hit_description             TEXT,

  PRIMARY KEY (protein_feature_id),
  KEY translation_idx (translation_id),
  KEY hitname_idx (hit_name),
  KEY analysis_idx (analysis_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE supporting_feature (

  exon_id                     INT(10) UNSIGNED DEFAULT '0' NOT NULL,
  feature_type                ENUM('dna_align_feature','protein_align_feature'),
  feature_id                  INT(10) UNSIGNED DEFAULT '0' NOT NULL,

  UNIQUE KEY all_idx (exon_id,feature_type,feature_id),
  KEY feature_idx (feature_type,feature_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM MAX_ROWS=100000000 AVG_ROW_LENGTH=80;

CREATE TABLE transcript (

  transcript_id               INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  gene_id                     INT(10) UNSIGNED,
  analysis_id                 SMALLINT UNSIGNED NOT NULL,
  seq_region_id               INT(10) UNSIGNED NOT NULL,
  seq_region_start            INT(10) UNSIGNED NOT NULL,
  seq_region_end              INT(10) UNSIGNED NOT NULL,
  seq_region_strand           TINYINT(2) NOT NULL,
  display_xref_id             INT(10) UNSIGNED,
  source                      VARCHAR(40) NOT NULL default 'ensembl',
  biotype                     VARCHAR(40) NOT NULL,
  status                      ENUM('KNOWN', 'NOVEL', 'PUTATIVE', 'PREDICTED', 'KNOWN_BY_PROJECTION', 'UNKNOWN', 'ANNOTATED'),
  description                 TEXT,
  is_current                  BOOLEAN NOT NULL DEFAULT 1,
  canonical_translation_id    INT(10) UNSIGNED,
  stable_id                   VARCHAR(128) DEFAULT NULL,
  version                     SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  created_date                DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified_date               DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',

  PRIMARY KEY (transcript_id),
  KEY seq_region_idx (seq_region_id, seq_region_start),
  KEY gene_index (gene_id),
  KEY xref_id_index (display_xref_id),
  KEY analysis_idx (analysis_id),
  UNIQUE INDEX canonical_translation_idx (canonical_translation_id),
  KEY stable_id_idx (stable_id, version)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE transcript_attrib (

  transcript_id               INT(10) UNSIGNED NOT NULL DEFAULT '0',
  attrib_type_id              SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  value                       TEXT NOT NULL,

  KEY type_val_idx (attrib_type_id, value(40)),
  KEY val_only_idx (value(40)),
  KEY transcript_idx (transcript_id),
  UNIQUE KEY transcript_attribx (transcript_id, attrib_type_id, value(500))

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE transcript_supporting_feature (

  transcript_id               INT(10) UNSIGNED DEFAULT '0' NOT NULL,
  feature_type                ENUM('dna_align_feature','protein_align_feature'),
  feature_id                  INT(10) UNSIGNED DEFAULT '0' NOT NULL,

  UNIQUE KEY all_idx (transcript_id,feature_type,feature_id),
  KEY feature_idx (feature_type,feature_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM MAX_ROWS=100000000 AVG_ROW_LENGTH=80;



CREATE TABLE translation (

  translation_id              INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  transcript_id               INT(10) UNSIGNED NOT NULL,
  seq_start                   INT(10) NOT NULL,       # relative to exon start
  start_exon_id               INT(10) UNSIGNED NOT NULL,
  seq_end                     INT(10) NOT NULL,       # relative to exon start
  end_exon_id                 INT(10) UNSIGNED NOT NULL,
  stable_id                   VARCHAR(128) DEFAULT NULL,
  version                     SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  created_date                DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified_date               DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',

  PRIMARY KEY (translation_id),
  KEY transcript_idx (transcript_id),
  KEY stable_id_idx (stable_id, version)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE translation_attrib (

  translation_id              INT(10) UNSIGNED NOT NULL DEFAULT '0',
  attrib_type_id              SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  value                       TEXT NOT NULL,

  KEY type_val_idx (attrib_type_id, value(40)),
  KEY val_only_idx (value(40)),
  KEY translation_idx (translation_id),
  UNIQUE KEY translation_attribx (translation_id, attrib_type_id, value(500))

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;




CREATE TABLE density_feature (

  density_feature_id    INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  density_type_id       INT(10) UNSIGNED NOT NULL,
  seq_region_id         INT(10) UNSIGNED NOT NULL,
  seq_region_start      INT(10) UNSIGNED NOT NULL,
  seq_region_end        INT(10) UNSIGNED NOT NULL,
  density_value         FLOAT NOT NULL,

  PRIMARY KEY (density_feature_id),
  KEY seq_region_idx (density_type_id, seq_region_id, seq_region_start),
  KEY seq_region_id_idx (seq_region_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE density_type (

  density_type_id       INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  analysis_id           SMALLINT UNSIGNED NOT NULL,
  block_size            INT NOT NULL,
  region_features       INT NOT NULL,
  value_type            ENUM('sum','ratio') NOT NULL,

  PRIMARY KEY (density_type_id),
  UNIQUE KEY analysis_idx (analysis_id, block_size, region_features)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;

CREATE TABLE ditag (

       ditag_id          INT(10) UNSIGNED NOT NULL auto_increment,
       name              VARCHAR(30) NOT NULL,
       type              VARCHAR(30) NOT NULL,
       tag_count         smallint(6) UNSIGNED NOT NULL default 1,
       sequence          TINYTEXT NOT NULL,

       PRIMARY KEY (ditag_id)

) ENGINE=MyISAM DEFAULT CHARSET=latin1;



CREATE TABLE ditag_feature (

       ditag_feature_id   INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
       ditag_id           INT(10) UNSIGNED NOT NULL default '0',
       ditag_pair_id      INT(10) UNSIGNED NOT NULL default '0',
       seq_region_id      INT(10) UNSIGNED NOT NULL default '0',
       seq_region_start   INT(10) UNSIGNED NOT NULL default '0',
       seq_region_end     INT(10) UNSIGNED NOT NULL default '0',
       seq_region_strand  TINYINT(1) NOT NULL default '0',
       analysis_id        SMALLINT UNSIGNED NOT NULL default '0',
       hit_start          INT(10) UNSIGNED NOT NULL default '0',
       hit_end            INT(10) UNSIGNED NOT NULL default '0',
       hit_strand         TINYINT(1) NOT NULL default '0',
       cigar_line         TINYTEXT NOT NULL,
       ditag_side         ENUM('F', 'L', 'R') NOT NULL,

       PRIMARY KEY  (ditag_feature_id),
       KEY ditag_idx (ditag_id),
       KEY ditag_pair_idx (ditag_pair_id),
       KEY seq_region_idx (seq_region_id, seq_region_start, seq_region_end)

) ENGINE=MyISAM DEFAULT CHARSET=latin1;



CREATE TABLE intron_supporting_evidence (
        intron_supporting_evidence_id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
        analysis_id                   SMALLINT UNSIGNED NOT NULL,
        seq_region_id                 INT(10) UNSIGNED NOT NULL,
        seq_region_start              INT(10) UNSIGNED NOT NULL,
        seq_region_end                INT(10) UNSIGNED NOT NULL,
        seq_region_strand             TINYINT(2) NOT NULL,
        hit_name                      VARCHAR(100) NOT NULL,
        score                         DECIMAL(10,3),
        score_type                    ENUM('NONE', 'DEPTH') DEFAULT 'NONE',
        is_splice_canonical           BOOLEAN NOT NULL DEFAULT 0,

        PRIMARY KEY (intron_supporting_evidence_id),

        UNIQUE KEY (analysis_id, seq_region_id, seq_region_start, seq_region_end, seq_region_strand, hit_name),
        KEY seq_region_idx (seq_region_id, seq_region_start)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;

CREATE TABLE map (

  map_id                      INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  map_name                    VARCHAR(30) NOT NULL,

  PRIMARY KEY (map_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE marker (

  marker_id                   INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  display_marker_synonym_id   INT(10) UNSIGNED,
  left_primer                 VARCHAR(100) NOT NULL,
  right_primer                VARCHAR(100) NOT NULL,
  min_primer_dist             INT(10) UNSIGNED NOT NULL,
  max_primer_dist             INT(10) UNSIGNED NOT NULL,
  priority                    INT,
  type                        ENUM('est', 'microsatellite'),

  PRIMARY KEY (marker_id),
  KEY marker_idx (marker_id, priority),
  KEY display_idx (display_marker_synonym_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE marker_feature (

  marker_feature_id           INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  marker_id                   INT(10) UNSIGNED NOT NULL,
  seq_region_id               INT(10) UNSIGNED NOT NULL,
  seq_region_start            INT(10) UNSIGNED NOT NULL,
  seq_region_end              INT(10) UNSIGNED NOT NULL,
  analysis_id                 SMALLINT UNSIGNED NOT NULL,
  map_weight                  INT(10) UNSIGNED,

  PRIMARY KEY (marker_feature_id),
  KEY seq_region_idx (seq_region_id, seq_region_start),
  KEY analysis_idx (analysis_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE marker_map_location (

  marker_id                   INT(10) UNSIGNED NOT NULL,
  map_id                      INT(10) UNSIGNED NOT NULL,
  chromosome_name             VARCHAR(15)  NOT NULL,
  marker_synonym_id           INT(10) UNSIGNED NOT NULL,
  position                    VARCHAR(15) NOT NULL,
  lod_score                   DOUBLE,

  PRIMARY KEY (marker_id, map_id),
  KEY map_idx (map_id, chromosome_name, position)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE marker_synonym (

  marker_synonym_id           INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  marker_id                   INT(10) UNSIGNED NOT NULL,
  source                      VARCHAR(20),
  name                        VARCHAR(50),

  PRIMARY KEY (marker_synonym_id),
  KEY marker_synonym_idx (marker_synonym_id, name),
  KEY marker_idx (marker_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE misc_attrib (

  misc_feature_id             INT(10) UNSIGNED NOT NULL DEFAULT '0',
  attrib_type_id              SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  value                       TEXT NOT NULL,

  KEY type_val_idx (attrib_type_id, value(40)),
  KEY val_only_idx (value(40)),
  KEY misc_feature_idx (misc_feature_id),
  UNIQUE KEY misc_attribx (misc_feature_id, attrib_type_id, value(500))

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;




CREATE TABLE misc_feature (

  misc_feature_id             INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  seq_region_id               INT(10) UNSIGNED NOT NULL DEFAULT '0',
  seq_region_start            INT(10) UNSIGNED NOT NULL DEFAULT '0',
  seq_region_end              INT(10) UNSIGNED NOT NULL DEFAULT '0',
  seq_region_strand           TINYINT(4) NOT NULL DEFAULT '0',

  PRIMARY KEY (misc_feature_id),
  KEY seq_region_idx (seq_region_id, seq_region_start)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE misc_feature_misc_set (

  misc_feature_id             INT(10) UNSIGNED NOT NULL DEFAULT '0',
  misc_set_id                 SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',

  PRIMARY KEY (misc_feature_id, misc_set_id),
  KEY reverse_idx (misc_set_id, misc_feature_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE misc_set (

  misc_set_id                 SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
  code                        VARCHAR(25) NOT NULL DEFAULT '',
  name                        VARCHAR(255) NOT NULL DEFAULT '',
  description                 TEXT NOT NULL,
  max_length                  INT UNSIGNED NOT NULL,

  PRIMARY KEY (misc_set_id),
  UNIQUE KEY code_idx (code)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE prediction_exon (

  prediction_exon_id          INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  prediction_transcript_id    INT(10) UNSIGNED NOT NULL,
  exon_rank                   SMALLINT UNSIGNED NOT NULL,
  seq_region_id               INT(10) UNSIGNED NOT NULL,
  seq_region_start            INT(10) UNSIGNED NOT NULL,
  seq_region_end              INT(10) UNSIGNED NOT NULL,
  seq_region_strand           TINYINT NOT NULL,
  start_phase                 TINYINT NOT NULL,
  score                       DOUBLE,
  p_value                     DOUBLE,

  PRIMARY KEY (prediction_exon_id),
  KEY transcript_idx (prediction_transcript_id),
  KEY seq_region_idx (seq_region_id, seq_region_start)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE prediction_transcript (

  prediction_transcript_id    INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  seq_region_id               INT(10) UNSIGNED NOT NULL,
  seq_region_start            INT(10) UNSIGNED NOT NULL,
  seq_region_end              INT(10) UNSIGNED NOT NULL,
  seq_region_strand           TINYINT NOT NULL,
  analysis_id                 SMALLINT UNSIGNED NOT NULL,
  display_label               VARCHAR(255),

  PRIMARY KEY (prediction_transcript_id),
  KEY seq_region_idx (seq_region_id, seq_region_start),
  KEY analysis_idx (analysis_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE repeat_consensus (

  repeat_consensus_id         INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  repeat_name                 VARCHAR(255) NOT NULL,
  repeat_class                VARCHAR(100) NOT NULL,
  repeat_type                 VARCHAR(40) NOT NULL,
  repeat_consensus            TEXT,

  PRIMARY KEY (repeat_consensus_id),
  KEY name (repeat_name),
  KEY class (repeat_class),
  KEY consensus (repeat_consensus(10)),
  KEY type (repeat_type)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE repeat_feature (

  repeat_feature_id           INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  seq_region_id               INT(10) UNSIGNED NOT NULL,
  seq_region_start            INT(10) UNSIGNED NOT NULL,
  seq_region_end              INT(10) UNSIGNED NOT NULL,
  seq_region_strand           TINYINT(1) DEFAULT '1' NOT NULL,
  repeat_start                INT(10) NOT NULL,
  repeat_end                  INT(10) NOT NULL,
  repeat_consensus_id         INT(10) UNSIGNED NOT NULL,
  analysis_id                 SMALLINT UNSIGNED NOT NULL,
  score                       DOUBLE,

  PRIMARY KEY (repeat_feature_id),
  KEY seq_region_idx (seq_region_id, seq_region_start),
  KEY repeat_idx (repeat_consensus_id),
  KEY analysis_idx (analysis_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM MAX_ROWS=100000000 AVG_ROW_LENGTH=80;



CREATE TABLE simple_feature (

  simple_feature_id           INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  seq_region_id               INT(10) UNSIGNED NOT NULL,
  seq_region_start            INT(10) UNSIGNED NOT NULL,
  seq_region_end              INT(10) UNSIGNED NOT NULL,
  seq_region_strand           TINYINT(1) NOT NULL,
  display_label               VARCHAR(255) NOT NULL,
  analysis_id                 SMALLINT UNSIGNED NOT NULL,
  score                       DOUBLE,

  PRIMARY KEY (simple_feature_id),
  KEY seq_region_idx (seq_region_id, seq_region_start),
  KEY analysis_idx (analysis_id),
  KEY hit_idx (display_label)

) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE transcript_intron_supporting_evidence (
transcript_id                 INT(10) UNSIGNED NOT NULL,
intron_supporting_evidence_id INT(10) UNSIGNED NOT NULL,
previous_exon_id              INT(10) UNSIGNED NOT NULL,
next_exon_id                  INT(10) UNSIGNED NOT NULL,
PRIMARY KEY (intron_supporting_evidence_id, transcript_id),
KEY transcript_idx (transcript_id)
) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE gene_archive (

  gene_stable_id              VARCHAR(128) NOT NULL,
  gene_version                SMALLINT NOT NULL DEFAULT 1,
  transcript_stable_id        VARCHAR(128) NOT NULL,
  transcript_version          SMALLINT NOT NULL DEFAULT 1,
  translation_stable_id       VARCHAR(128),
  translation_version         SMALLINT NOT NULL DEFAULT 1,
  peptide_archive_id          INT(10) UNSIGNED,
  mapping_session_id          INT(10) UNSIGNED NOT NULL,

  KEY gene_idx (gene_stable_id, gene_version),
  KEY transcript_idx (transcript_stable_id, transcript_version),
  KEY translation_idx (translation_stable_id, translation_version),
  KEY peptide_archive_id_idx (peptide_archive_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;




CREATE TABLE mapping_session (

  mapping_session_id          INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  old_db_name                 VARCHAR(80) NOT NULL DEFAULT '',
  new_db_name                 VARCHAR(80) NOT NULL DEFAULT '',
  old_release                 VARCHAR(5) NOT NULL DEFAULT '',
  new_release                 VARCHAR(5) NOT NULL DEFAULT '',
  old_assembly                VARCHAR(20) NOT NULL DEFAULT '',
  new_assembly                VARCHAR(20) NOT NULL DEFAULT '',
  created                     DATETIME NOT NULL,

  PRIMARY KEY (mapping_session_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE peptide_archive (

  peptide_archive_id         INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  md5_checksum               VARCHAR(32),
  peptide_seq                MEDIUMTEXT NOT NULL,

  PRIMARY KEY (peptide_archive_id),
  KEY checksum (md5_checksum)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE mapping_set (

        mapping_set_id  INT(10) UNSIGNED NOT NULL,
        internal_schema_build    VARCHAR(20) NOT NULL,
        external_schema_build    VARCHAR(20) NOT NULL,

        PRIMARY KEY(mapping_set_id),
        UNIQUE KEY mapping_idx (internal_schema_build, external_schema_build)

) ENGINE=MyISAM DEFAULT CHARSET=latin1;



CREATE TABLE stable_id_event (

  old_stable_id             VARCHAR(128),
  old_version               SMALLINT,
  new_stable_id             VARCHAR(128),
  new_version               SMALLINT,
  mapping_session_id        INT(10) UNSIGNED NOT NULL DEFAULT '0',
  type                      ENUM('gene', 'transcript', 'translation') NOT NULL,
  score                     FLOAT NOT NULL DEFAULT 0,

  UNIQUE KEY uni_idx (mapping_session_id, old_stable_id, new_stable_id, type),

  KEY new_idx (new_stable_id),
  KEY old_idx (old_stable_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE seq_region_mapping (

        external_seq_region_id  INT(10) UNSIGNED NOT NULL,
        internal_seq_region_id  INT(10) UNSIGNED NOT NULL,
        mapping_set_id          INT(10) UNSIGNED NOT NULL,

        KEY mapping_set_idx (mapping_set_id)

) ENGINE=MyISAM DEFAULT CHARSET=latin1;


CREATE TABLE associated_group (

  associated_group_id            INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  description                    VARCHAR(128) DEFAULT NULL,

  PRIMARY KEY (associated_group_id)
) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE associated_xref (

  associated_xref_id             INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  object_xref_id                 INT(10) UNSIGNED DEFAULT '0' NOT NULL,
  xref_id                        INT(10) UNSIGNED DEFAULT '0' NOT NULL,
  source_xref_id                 INT(10) UNSIGNED DEFAULT NULL,
  condition_type                 VARCHAR(128) DEFAULT NULL,
  associated_group_id            INT(10) UNSIGNED DEFAULT NULL,
  rank                           INT(10) UNSIGNED DEFAULT '0',

  PRIMARY KEY (associated_xref_id),
  KEY associated_source_idx (source_xref_id),
  KEY associated_object_idx (object_xref_id),
  KEY associated_idx (xref_id),
  KEY associated_group_idx (associated_group_id),
  UNIQUE KEY object_associated_source_type_idx (object_xref_id, xref_id, source_xref_id, condition_type, associated_group_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE dependent_xref(

  object_xref_id         INT(10) UNSIGNED NOT NULL,
  master_xref_id         INT(10) UNSIGNED NOT NULL,
  dependent_xref_id      INT(10) UNSIGNED NOT NULL,

  PRIMARY KEY( object_xref_id ),
  KEY dependent ( dependent_xref_id ),
  KEY master_idx (master_xref_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE external_db (

  external_db_id              INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
  db_name                     VARCHAR(100) NOT NULL,
  db_release                  VARCHAR(255),
  status                      ENUM('KNOWNXREF','KNOWN','XREF','PRED','ORTH', 'PSEUDO') NOT NULL,
  priority                    INT NOT NULL,
  db_display_name             VARCHAR(255),
  type                        ENUM('ARRAY', 'ALT_TRANS', 'ALT_GENE', 'MISC', 'LIT', 'PRIMARY_DB_SYNONYM', 'ENSEMBL'),
  secondary_db_name           VARCHAR(255) DEFAULT NULL,
  secondary_db_table          VARCHAR(255) DEFAULT NULL,
  description                 TEXT,

  PRIMARY KEY (external_db_id),
  UNIQUE INDEX db_name_db_release_idx (db_name,db_release)
) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE external_synonym (

  xref_id                     INT(10) UNSIGNED NOT NULL,
  synonym                     VARCHAR(100) NOT NULL,

  PRIMARY KEY (xref_id, synonym),
  KEY name_index (synonym)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE identity_xref (

  object_xref_id          INT(10) UNSIGNED NOT NULL,
  xref_identity           INT(5),
  ensembl_identity        INT(5),

  xref_start              INT,
  xref_end                INT,
  ensembl_start           INT,
  ensembl_end             INT,
  cigar_line              TEXT,

  score                   DOUBLE,
  evalue                  DOUBLE,

  PRIMARY KEY (object_xref_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;

CREATE TABLE interpro (
  interpro_ac               VARCHAR(40) NOT NULL,
  id                        VARCHAR(40) NOT NULL,

  UNIQUE KEY accession_idx (interpro_ac, id),
  KEY id_idx (id)
) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE object_xref (

  object_xref_id              INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  ensembl_id                  INT(10) UNSIGNED NOT NULL,
  ensembl_object_type         ENUM('RawContig', 'Transcript', 'Gene',
                                   'Translation', 'Operon', 'OperonTranscript', 'Marker') NOT NULL,
  xref_id                     INT(10) UNSIGNED NOT NULL,
  linkage_annotation          VARCHAR(255) DEFAULT NULL,
  analysis_id                 SMALLINT UNSIGNED DEFAULT 0 NOT NULL,

  PRIMARY KEY (object_xref_id),

  UNIQUE KEY xref_idx
    (xref_id, ensembl_object_type, ensembl_id, analysis_id),

  KEY ensembl_idx (ensembl_object_type, ensembl_id),
  KEY analysis_idx (analysis_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE ontology_xref (

  object_xref_id          INT(10) UNSIGNED DEFAULT '0' NOT NULL,
  source_xref_id          INT(10) UNSIGNED DEFAULT NULL,
  linkage_type            VARCHAR(3) DEFAULT NULL,

  KEY source_idx (source_xref_id),
  KEY object_idx (object_xref_id),
  UNIQUE KEY object_source_type_idx (object_xref_id, source_xref_id, linkage_type)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE unmapped_object (

  unmapped_object_id    INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  type                  ENUM('xref', 'cDNA', 'Marker') NOT NULL,
  analysis_id           SMALLINT UNSIGNED NOT NULL,
  external_db_id        INTEGER UNSIGNED,
  identifier            VARCHAR(255) NOT NULL,
  unmapped_reason_id    INT(10) UNSIGNED NOT NULL,
  query_score           DOUBLE,
  target_score          DOUBLE,
  ensembl_id            INT(10) UNSIGNED DEFAULT '0',
  ensembl_object_type   ENUM('RawContig','Transcript','Gene','Translation') DEFAULT 'RawContig',
  parent                VARCHAR(255) DEFAULT NULL,

  PRIMARY KEY (unmapped_object_id),
  UNIQUE KEY unique_unmapped_obj_idx (ensembl_id, ensembl_object_type, identifier, unmapped_reason_id,parent, external_db_id),
  KEY id_idx (identifier(50)),
  KEY anal_exdb_idx (analysis_id, external_db_id),
  KEY ext_db_identifier_idx (external_db_id, identifier)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE unmapped_reason (

  unmapped_reason_id     INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  summary_description    VARCHAR(255),
  full_description       VARCHAR(255),

  PRIMARY KEY (unmapped_reason_id)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


CREATE TABLE xref (

   xref_id                    INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
   external_db_id             INTEGER UNSIGNED NOT NULL,
   dbprimary_acc              VARCHAR(40) NOT NULL,
   display_label              VARCHAR(128) NOT NULL,
   version                    VARCHAR(10) DEFAULT '0' NOT NULL,
   description                TEXT,
   info_type                  ENUM( 'NONE', 'PROJECTION', 'MISC', 'DEPENDENT',
                                    'DIRECT', 'SEQUENCE_MATCH',
                                    'INFERRED_PAIR', 'PROBE',
                                    'UNMAPPED', 'COORDINATE_OVERLAP', 
                                    'CHECKSUM' ) DEFAULT 'NONE' NOT NULL,
   info_text                  VARCHAR(255) DEFAULT '' NOT NULL,

   PRIMARY KEY (xref_id),
   UNIQUE KEY id_index (dbprimary_acc, external_db_id, info_type, info_text, version),
   KEY display_index (display_label),
   KEY info_type_idx (info_type)

) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE operon (
  operon_id                 INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  seq_region_id             INT(10) UNSIGNED NOT NULL,
  seq_region_start          INT(10) UNSIGNED NOT NULL,
  seq_region_end            INT(10) UNSIGNED NOT NULL,
  seq_region_strand         TINYINT(2) NOT NULL,
  display_label             VARCHAR(255) DEFAULT NULL,
  analysis_id               SMALLINT UNSIGNED NOT NULL,
  stable_id                 VARCHAR(128) DEFAULT NULL,
  version                   SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  created_date              DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified_date             DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',

  PRIMARY KEY (operon_id),
  KEY seq_region_idx (seq_region_id, seq_region_start),
  KEY name_idx (display_label),
  KEY stable_id_idx (stable_id, version)
) COLLATE=latin1_swedish_ci ENGINE=MyISAM;




CREATE TABLE operon_transcript (
  operon_transcript_id      INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  seq_region_id             INT(10) UNSIGNED NOT NULL,
  seq_region_start          INT(10) UNSIGNED NOT NULL,
  seq_region_end            INT(10) UNSIGNED NOT NULL,
  seq_region_strand         TINYINT(2) NOT NULL,
  operon_id                 INT(10) UNSIGNED NOT NULL,
  display_label             VARCHAR(255) DEFAULT NULL,
  analysis_id               SMALLINT UNSIGNED NOT NULL,
  stable_id                 VARCHAR(128) DEFAULT NULL,
  version                   SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  created_date              DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified_date             DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',

  PRIMARY KEY (operon_transcript_id),
  KEY operon_idx (operon_id),
  KEY seq_region_idx (seq_region_id, seq_region_start),
  KEY stable_id_idx (stable_id, version)
) COLLATE=latin1_swedish_ci ENGINE=MyISAM;



CREATE TABLE operon_transcript_gene (
  operon_transcript_id      INT(10) UNSIGNED,
  gene_id                   INT(10) UNSIGNED,

  KEY operon_transcript_gene_idx (operon_transcript_id,gene_id)
) COLLATE=latin1_swedish_ci ENGINE=MyISAM;


