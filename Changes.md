# Change Log for the Ensembl REST server

# 2.0.0 - date to be advised

A transition from beta to a more stable interface for users, better documentation and more functionality.
More features will appear over time, but these will not interfere with the existing interface wherever possible.

## New Features:

  * New POST endpoints:
      - [/vep/:species/id/], [/vep/:species/region/]. The VEP endpoints have had their URLs altered, and the existing ID and region endpoints now accept POST messages containing many variants. Regions can be submitted in the formats supported by the VEP (vcf, hgvs, pileup, ensembl, and vep).

      - [/archive/id/]. The archive endpoint now supports lists of IDs in POST messages.
    
    POST messages allow the user to potentially submit huge quantities of requests, so please be kind, observe any rate and message size limits, and make your clients tolerant to timeouts and errors.

  * New [/variation] endpoint that retrieves variants linked to a gene or transcript

  * [/genetree/*] endpoints support JSON response format

  * [/feature/*] endpoints renamed to [/overlap/] to more closely represent their function

  * [/overlap/*] endpoints now support BED response format

  * HTTPS support for clients with confidentiality concerns

  * The rate limiter is more permissive. We have stepped up the rate limit from three requests per second to fifteen per second.

  * [/sequence/*] endpoints now report sequence with contextual soft-masking for features through the mask_feature option. This allows the finding of feature boundaries in raw sequence. IDs of type "cds" mask the UTRs, and IDs of type gene mask introns.

## Bugfixes:

  * Spelling of [/ontology/descendents] changed to [/ontology/descendants]

  * Documentation overhaul to better explain endpoints and parameters

  * Regulatory features appear correctly from [/overlap/*] endpoints

  * Numerous tweaks to error handling and documentation

  * [/assembly/info] renamed to [/info/assembly] to match convention

## Retirements:

  * MessagePack and Sereal formats were receiving little use and have been retired to decrease maintenance burden
  * [/genetree/*] endpoints no longer supporting phyloxml_aligned and phyloxml_sequence parameters. These have been replaced with aligned and sequence.

## Deployment issues:

  * New versions of Moose, Catalyst and Catalyst::Action::REST are causing misbehaviour with the server. Please observe the library versions required in the installation makefile until we find a way to fix this conflict.

# 1.6.0 - 26-02-2014

## New Features:

    * [/feature/] Trim features from output which overlap 5' or 3' optionally

    * [/alignment/region/] replaces [/alignment/block/region/] and [/alignment/slice/region/]


## Bugfixes:

    * The example for multiple alignments is wrong

    * XS assert_ref fails with REST feature endpoint

    * [/feature] BED output is very slow for transcripts

    * [/feature] BED output; thick and thin ends are incorrect for reverse
      strand transcripts

# 1.5.1 - 04-12-2013

## Bugfixes:

    * Removed deprecated methods from Compara

# 1.5.0 - 04-12-2013

## New Features:

    * Build a better rate limiter

    * Enable compression on REST site

    * Ensure rate limiter reports the time scale over which rate limiting occurs

    * Faster GeneTree serlialisation; JSON now supported

    * Rate limiter responds with a Retry*After header once limits have been hit

    * [/info/species] to report common names of species and taxon ids

    * [/lookup/:species/:symbol] Look up the location of an object based on a
      symbol

    * [/taxonomy/name] Allow for searching of Taxonomy nodes by any linked name


## Bugfixes:

    * Detect content in REST does not understand Accepts

    * GFF3 for cds features invalid, duplicate ids for simple features

    * Serialisations choose to send the content*type back as text/plain

    * [/homology] throws an exception when you ask for orthologues of the
      species the gene is from

    * [/xrefs/symbol/:species/:symbol] does not respond to object type filtering

    * [/xrefs] fails to report linkage types for GO xrefs


# 1.4.4 - 07-11-2013

## Bugfixes

    * [/xrefs] fails to report linkage types for ontology xrefs

    * [/homology/id] and [/homology/symbol] failed when querying for the 
      same species as the member

# 1.4.3 - 05-11-2013

## Bugfixes:

    * [/lookup/id] and [/xrefs/symbol] were using the parameter object rather than object_type

    * [/homology] endpoints would accept only one instance of target_taxon and target_species. 
      We now allow multiples as  intended

## 1.4.2 23-09-2013

# Bugfixes:

    * [/feature/id] Querying for features using a negative stranded 
      feature reversed the strand of the retrieved object

## 1.4.1 09-09-2013

## Bugfixes:

    * Lookup with a non-indexed stable identifiers in databases other than 
      core failed

# 1.4.0 03-09-2013

## New Features:

    * Improved error page when a user goes to an unknown documentation page

    * Rate limiter responds with a Retry*After header once limits have been hit

    * [/assembly/info] should return those Slices which are part of the
      karyotype

    * [/feature/translation/:id] Support the retrieval of splice sites with
      respect from a translation

    * [/feature/translation] Improved translation feature support for GFF3

    * [/info/analysis] Support retrieval of analysis logic names

    * [/info/analysis] to provide logic names available

    * [/info/biotype] Support for listing available biotypes

    * [/info/data] has been sped up for Ensembl Genomes servers (Ensembl
      Bacteria)

    * [/info/external_db] Support retrieval of external dbs

    * [/info/external_dbs] Support the retrieval of external dbs

    * [/lookup/id] Provide more information for a lookup ID

    * [info/biotypes] Support retrieval of biotypes from the rest api

## Bugfixes:

    * REST GFF CDS Line is incorrect. ID can repeat in a single GFF file

    * [/compara/homology] throws an exception when requesting ENSEMBL_PROJECTION
      ortholog alignmnets

    * [/feature/id] does not work for regulatory regions

    * [/feature/id] is failing as it thinks species is a HASH ref

    * [/genetree/symbol] and [/feature/translation] modified to default object
      type

    * [/ontology/descendents/:id] Using the zero_distance parameter destroys any
      output

    * [/ontology/id/:id] Giving a bogus ontology ID causes a stack trace

# 1.3.2 16-04-2013

## New Features:

  * [/info/species] allows you to specify a division to limit the data by

## Bugfixes:

  * [/homology/id] and [/homology/symbol] have improved error 
    reporting when IDs and symbols cannot be found

# 1.3.1 15-04-2013

##Bugfixes:

  * [/vep] could not find a region due to changes in the backing Lookup 
    object

# 1.3.0 09-04-2013

## New Features:

  * [/feature/id] allows for the querying of features overlapping a 
    stable ID
  
  * [/genetree/member/id] allows for the querying of a GeneTree by one 
    of its member's stable ID
  
  * [/genetree/member/symbol] allows for the querying of a GeneTree by
    one of its member's symbols (its name e.g. BRAF)
  
  * [/taxonomy/] provides methods for querying the Ensembl taxonomy 
    database. This is a mirror of NCBI's taxonomy.
  
  * [/ontology/] provides methods for querying the Ensembl ontology 
    database
  
  * [/lookup/id] replaces [/lookup] but the old endpoint remains active. 
    This endpoint now supports genomic location reporting of features when 
    output format is set to full. Please use the new endpoint.
  
  * Model::Registry supports use of Ensembl Genomes' Bio::EnsEMBL::LookUp 
    object to help loading bacteria datasets
  
  * All location based services no longer support underscores as a numeric 
    separator. All now support UCSC names for sequence regions
  
  * Support for CrossOrigin resource sharing via Plack::Middleware::CrossOrigin

## Configuration:

  * [/species/info] now supports the vast numbers Ensembl Bacteria brings 
    into the registry
  
  * All models if they need access to the Catalyst context object implement 
    methods to access this without explicit pass throughs. Affects all 
    Models apart from Registry

## Bugfixes:

  * Model::Registry has Bio::EnsEMBL::LookUp configuration attributes

  * Controller::Taxonomy allows for database name configuration

  * Controller::Ontology allows for database name configuration


# 1.2.0 15-02-2013

## New Features:

  * Support for Sereal encoding format from Sereal::Encoder. MIME type
    application/x-sereal is required and extension support is
    .sereal
  
  * Support for MessagePack encoding format from Data::MessagePack. MIME type
    application/x-msgpack is required and extension support is
    .msgpack

## Configuration:

  * Configuration has switched to a more Catalyst friendly method. Config
    is namespaced to the object which uses it and is accessible via local
    accessors in that object. 
    
    Registry and Documentation are prefixed with Model:: 
    Feature and Sequence are prefixed with Controller::
    All other configuration sections are unaffected

## Bugfixes:

  * [/feature] CDS no longer report a protein as an exon's ID since 
    ID should be unique in a file. Instead this is available via the 
    protein_id attribute

# 1.1.2 24-10-2012

## Output:

  * [/homology] now supports the retrieval of CDNA sequences

## Bugfixes:

  * [/feature] had incorrect documentation WRT features available

# 1.1.1 24-10-2012

## Bugfixes:

  * [/sequence/region] had not been recoded for our multiple sequence 
    changes resulting in a broken service
    
  * Documentation needs to internally escape characters like + for 
    example as Catalyst does not like this
    
  * [/vep] was attempting to multiple intron_number and exon_number 
    to avoid stringification of numerics; these two fields are not numeric

# 1.1.0 23-10-2012 

## New Features:

  * [/feature] new endpoint for retrieval of features by a genomic location

  * [/sequence] now responds to Content*type text/plain with an unformatted
    raw String of sequence

  * Plack::Middleware::Throttle is an optional install; custom extensions 
    available with this checkout. Brings rate limiting to the REST API service

  * Using CHI to cache documentation API responses
  
  * Content type detection carried out using file name extensions as well
    as the existing mechanisms. Supported on all endpoints
  
  * [/sequence] supports multiple sequences from a single identifier e.g. 
    proteins from a gene identifier
  
  * Online change log
  
  * [/genetree] now supports CDNA sequence in PhyloXML output

## Output:

  * [/vep] alleles now an array with allele_string explicit instead of as key.

  * [/info/species] reports the division of a species; Ensembl Genomes 
    extension
  
  * Mime types changed for many services to denote non-standard types. We now
    use text/x-fasta, text-x-gff3, text/x-seqxml+xml and text/x-phyloxml+xml.
  
  * [/genetree] has had NHX format retired in favor of PhyloXML
  
  * [/map] Translate coordinates for transcript/translation to genomic 
    now reports the sequence region name

## Bugfixes:

  * 2 Y regions returned from [/assembly/info/human] fixed
  
  * JSON serialiser mis-encodes numerics as Strings due to MySQL DBD issues
  
  * Location parser method does not handle GL1923.1 properly
  
  * [/genetree] parameter nh_format has no effect on the newick output

## Configuration:

  * Removal of <Compara> configuration option; new code introduced to 
    select the best compara available based upon species.division
  
  * Documentation supports variable replacement for easier configuration by
    third parties
  
  * CHI cache support in configuration; see CHI's POD and our production
    configuration about how you can configure it
  
  * URL, name and logo now configurable

# 1.0.0 05-09-2012

  * Initial revision of REST API

  * Support for comparative genomics, cross references, ID lookup, 
    mapping coordinates, sequences & variations
    
  * Information endpoints also made available

  * Documentation added for all end points

