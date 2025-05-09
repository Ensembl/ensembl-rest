=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2025] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::REST::Model::Lookup;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use Catalyst::Exception;
use Scalar::Util qw/weaken/;

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

# Config
has 'lookup_model' => ( is => 'ro', isa => 'Str', required => 1, default => 'DatabaseIDLookup' );

has 'no_long_lookup' => (is => 'ro', isa => 'Bool');

# Per instance variables
has 'context' => (is => 'ro', weak_ref => 1);

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

sub find_cafe_by_genetree {
  my ($self, $gt) = @_;
  my $c = $self->context();
  my $compara_name = $c->request->parameters->{compara};
  my $reg = $c->model('Registry');

  my $cafa = $gt->adaptor->db()->get_CAFEGeneFamilyAdaptor();
  Catalyst::Exception->throw("No get_CAFEGeneFamily adaptor found ") unless $cafa;
  my $cafe_object = $cafa->fetch_by_GeneTree($gt);

  return $cafe_object;
  
}

sub find_genetree_by_stable_id {
  my ($self, $id) = @_;
  my $gt;
  my $c = $self->context();
  my $compara_name = $c->request->parameters->{compara};
  my $reg = $c->model('Registry');

  #Force search to use compara as the DB type
  $c->request->parameters->{db_type} = 'compara' if ! $c->request->parameters->{db_type};

  #Try to do a lookup if the ID DB is there
  my $lookup = $reg->get_DBAdaptor('multi', 'stable_ids', 1);

  if($lookup) {
    my ($species, $object_type, $db_type) = $self->find_object_location($id);
    if($species) {
      my $gta = $reg->get_adaptor($species, $db_type, $object_type);
      Catalyst::Exception->throw("No adaptor found for ID $id, species $species, object $object_type and db $db_type") unless $gta;
      $gt = $gta->fetch_by_stable_id($id);
    }
  }
  #If we haven't got one then do a linear search
  if(! $gt) {
    my $comparas = $c->model('Registry')->get_all_DBAdaptors('compara', $compara_name);

    foreach my $c (@{$comparas}) {
      my $gta = $c->get_GeneTreeAdaptor();      
      $gt = $gta->fetch_by_stable_id($id);
      last if $gt;
    }
  }
  return $gt if $gt;
  Catalyst::Exception->throw("No GeneTree found for ID $id");
}

sub find_genetree_by_member_id {
  my ($self,$id) = @_;
  my $c = $self->context();
  my $compara_name = $c->request->parameters->{compara};
  my $reg = $c->model('Registry');

  my ($species, $object_type, $db_type) = $self->find_object_location($id);
  # The rest of the method should deal with all the possible $object_type
  # and $db_type, and output the relevant error messages.
  Catalyst::Exception->throw("Unable to find given object: $id") unless $species;
  Catalyst::Exception->throw("'$id' is not an Ensembl Core object, and thus does not have a gene-tree.") if $db_type ne 'core';

  my $dba = $reg->get_best_compara_DBAdaptor($species,$compara_name);
  my $genome = $dba->get_GenomeDBAdaptor->fetch_by_name_assembly($species);
  my $member;
  if ($object_type =~ /^gene$/i) {
    $member = $dba->get_GeneMemberAdaptor->fetch_by_stable_id_GenomeDB($id, $genome);
  } elsif ($object_type  =~ /^transcript$/i) {
    my $gene_adaptor = $reg->get_adaptor($species, $db_type, 'Gene');
    my $gene = $gene_adaptor->fetch_by_transcript_stable_id($id);
    $member = $dba->get_GeneMemberAdaptor->fetch_by_stable_id_GenomeDB($gene->stable_id, $genome);
  } elsif ($object_type =~ /^translation$/i) {
    my $translation_adaptor = $reg->get_adaptor($species, $db_type, 'Translation');
    my $translation = $translation_adaptor->fetch_by_stable_id($id);
    $member = $dba->get_SeqMemberAdaptor->fetch_by_stable_id_GenomeDB($translation->stable_id, $genome);
  } elsif ($object_type =~ /^exon$/i) {
    my $gene_adaptor = $reg->get_adaptor($species, $db_type, 'Gene');
    my $gene = $gene_adaptor->fetch_by_exon_stable_id($id);
    $member = $dba->get_GeneMemberAdaptor->fetch_by_stable_id_GenomeDB($gene->stable_id, $genome);
  }
  Catalyst::Exception->throw("Could not fetch a $object_type object for ID $id") unless $member;

  my $clusterset_id = $c->request->parameters->{clusterset_id};
  my $gta = $dba->get_GeneTreeAdaptor;
  my $gt = $gta->fetch_default_for_Member($member, $clusterset_id);
  Catalyst::Exception->throw("No GeneTree found for $object_type ID $id") unless $gt;
  return $gt;
}


#Find all the Method objects in the compara database
sub find_compara_methods {
  my ($self, $class) = @_;
  my $c = $self->context();
  #default is "multi"
  my $compara = $c->request->parameters->{compara} || $c->config->{'Controller::Compara'}->{default_compara} || 'multi';
  if (lc($compara) eq 'vertebrates') {
    $compara = 'multi';
  }
  my $reg = $c->model('Registry');
  my $compara_dba = $reg->get_DBAdaptor($compara, "compara");
  my $methods;
  if($class) {
    $methods = $compara_dba->get_MethodAdaptor->fetch_all_by_class_pattern($class);
  }
  else {
    $methods = $compara_dba->get_MethodAdaptor->fetch_all();
  }
  return $methods;
}

#Find all the species_sets for this method in the compara database
sub find_compara_species_sets {
  my ($self, $method) = @_;

  my $c = $self->context();
  #default is "multi"
  my $compara = $c->request->parameters->{compara} || $c->config->{'Controller::Compara'}->{default_compara} || 'multi';
  if (lc($compara) eq 'vertebrates') {
    $compara = 'multi';
  }
  my $reg = $c->model('Registry');
  my $compara_dba = $reg->get_DBAdaptor($compara, "compara");

  my @results;

  #Get MethodLinkSpeciesSet objects
  my $mlsss = $compara_dba->get_MethodLinkSpeciesSetAdaptor->fetch_all_by_method_link_type($method);
  foreach my $mlss (@$mlsss) {
    my $species_set = {};
    my $species_set_obj = $mlss->species_set();
    my @species_set_genomes = map { $_->name } @{$species_set_obj->genome_dbs};
    $species_set->{species_set_group} = $species_set_obj->name;
    $species_set->{name} = $mlss->name;
    $species_set->{species_set} = \@species_set_genomes;
    $species_set->{method} = $mlss->method()->type();
    push(@results, $species_set);
  }
  return \@results;
}

# uses the request for more optional arguments
sub find_object_by_stable_id {
  my ($self, $id) = @_;
  my $c = $self->context();
  my ($species, $object_type, $db_type) = $self->find_object_location($id);
  return $self->find_object($id, $species, $object_type, $db_type);
}

sub find_object {
  my ($self, $id, $species, $object_type, $db_type) = @_;
  my $c = $self->context();
  my $r = $c->request();
  my $reg = $c->model('Registry');
  $object_type = $r->param('object_type') if !$object_type;
  Catalyst::Exception->throw("ID '$id' not found") unless $species;
  my $adaptor = $reg->get_adaptor($species, $db_type, $object_type);
  $c->log()->debug('Found an adaptor '.$adaptor);
  if(! $adaptor->can('fetch_by_stable_id')) {
    Catalyst::Exception->throw("Object, $object_type, type's adaptor does not support fetching by a stable ID for ID '$id'");
  }
  my $final_obj = $adaptor->fetch_by_stable_id($id);
  Catalyst::Exception->throw("No object found for ID $id") unless $final_obj;
  $c->stash()->{object} = $final_obj;
  return $final_obj;
}


sub find_objects_by_symbol {
  my ($self, $symbol) = @_;
  my $c = $self->context();
  my $db_type = $c->request->param('db_type') || 'core';
  my $external_db = $c->request->param('external_db');
  my @entries;
  my @objects_to_try = $c->request->param('object_type') ? ($c->request->param('object_type')) : qw(gene transcript translation);
  foreach my $object_type (@objects_to_try) {
    my $object_adaptor = $c->model('Registry')->get_adaptor($c->stash->{'species'}, $db_type, $object_type);
    my $objects_linked_to_symbol = $object_adaptor->fetch_all_by_external_name($symbol, $external_db);
    while(my $obj = shift @{$objects_linked_to_symbol}) {
      $c->log()->debug("Found by symbol ".$symbol." ".$obj);
      push(@entries, $obj);
    }
  }

  # If we ran out of possible symbols then switch onto using the gene's display label
  if(! @entries) {
    my $object_param = $c->request->param('object_type');
    if(! defined $object_param || (defined $object_param && $object_param eq 'gene') ) {
      my $object_adaptor = $c->model('Registry')->get_adaptor($c->stash->{'species'}, $db_type, 'gene');
      my $objects_linked_to_symbol = $object_adaptor->fetch_all_by_display_label($symbol);
      while(my $obj = shift @{$objects_linked_to_symbol}) {
        $c->log()->debug("Found by symbol ".$symbol." ".$obj);
        push(@entries, $obj);
      }
    }
  }

  return \@entries;
}

sub find_object_location {
  my ($self, $id) = @_;
  my $no_long_lookup = $self->no_long_lookup();
  my $c = $self->context();
  my $r = $c->request;
  my $log = $c->log();

  my ($object_type, $db_type, $species, $use_archive) = map { my $p = $r->param($_); $p; } qw/object_type db_type species use_archive/;
  my @captures;

  #If all 3 params were specified then let it through. User knows best
  if($object_type && $db_type && $species) {
    @captures = ($species, $object_type, $db_type);
  }
  elsif($object_type && $object_type eq 'predictiontranscript') {
    @captures = $c->model('LongDatabaseIDLookup')->find_object_location($id, $object_type, $db_type, $species);
  }
  else {
    $c->log()->debug(sprintf('Looking for %s with %s and %s in %s', $id, ($object_type || q{?}), ($db_type || q{?}), ($species || q{?})));
    my $model_name = $self->lookup_model();
    my $lookup = $c->model($model_name);
    @captures = $lookup->find_object_location($id, $object_type, $db_type, $species, $use_archive);
    #Check if we any conntent or if the 1st element was false (both mean force a long lookup)
    unless ((@captures && $captures[0]) || $no_long_lookup) {
      $c->log()->debug('Using long database lookup');
      @captures = $c->model('LongDatabaseIDLookup')->find_object_location($id, $object_type, $db_type, $species);
    }
  }

  if($log->is_debug()) {
    if(@captures && $captures[2]) {
      $log->debug(sprintf('Found %s, %s and %s', @captures[0..2]));
    }
    else {
      $log->debug('Found no ID');
      if ($use_archive) {
        my $reg = $c->model('Registry');
        my $lookup = $reg->get_DBAdaptor('multi', 'stable_ids', 1);
        Catalyst::Exception->throw("No lookup database available on server, archive lookup not possible for $id. Please contact the administrator of this server") unless $lookup;
      }
      $log->debug("No object found for $id");
    }
  }

  $c->stash(species => $captures[0], object_type => $captures[1], group => $captures[2]);

  return @captures;
}

sub fetch_archive_by_id {
  my ($self, $stable_id) = @_;

  my $c = $self->context();
  my $archive;

  my @results = $self->find_object_location($stable_id, undef, 1);
  if (!defined $results[0]) {
    Catalyst::Exception->throw("No object found for $stable_id");
  }
  my $species = $results[0];
  # We need to accept the type from find_object_location because some
  # species like C. elegans don't have a pattern the type lookup can
  # identify, and things go very badly
  my $type = $results[1] ? $results[1] : undef;
  my $adaptor = $c->model('Registry')->get_adaptor($species,'Core','ArchiveStableID');

  # Lookup the stable_id, passing along the identifier type if we have it
  $archive = $adaptor->fetch_by_stable_id($stable_id, $type);
  $c->stash()->{archive} = $archive;
}

sub find_and_locate_object {
  my ($self, $id) = @_;
  my $c = $self->context();

  my @captures = $self->find_object_location($id);
  my $species = $captures[0];
  my $object_type = $captures[1];
  my $db_type = $captures[2];
  my $features = $self->features_as_hash($id, $species, $object_type, $db_type);
  my $input_type = lc($features->{object_type});
  
  #include phenotypes for genes
  my $phenotypes = $c->request->param('phenotypes');
  if($phenotypes && $input_type eq 'gene'){
    #fetch the gene phenotype info
    $features->{'phenotypes'} = $self->phenotypes($features->{id});
  }
  
  my $expand = $c->request->param('expand');
  if ($expand) {
    if ($input_type eq 'gene') {
      $features->{'Transcript'} = $self->Transcript($features->{id}, $species, $db_type);
    } elsif ($input_type eq 'transcript') {
      $features = $self->transcript_feature($features->{id}, $species, $db_type);
    } else {
      Catalyst::Exception->throw("Expand option only available for Genes and Transcripts");
    }
  }

  return $features;
}

sub find_and_locate_list {
  my ($self, $id_list) = @_;
  my $c = $self->context();
  my %combined_list;
  while (my $id = shift @$id_list) {
    my $objs;
    try {
      $objs = find_and_locate_object($self,$id);
    }
    catch {
      $c->log->debug("No object found for ID $id");
      # No objects found, report an empty variable
    };
    $combined_list{$id} = $objs;
  }
  return \%combined_list;
}

sub find_gene_by_symbol {
  my ($self, $symbol) = @_;
  my $c = $self->context();
  my $species = $c->stash->{'species'};

  my $gene_adaptor = $c->model('Registry')->get_adaptor($species, 'core', 'Gene');
  my $gene = $gene_adaptor->fetch_by_display_label($symbol);
  Catalyst::Exception->throw(qq{No valid lookup found for symbol $symbol}) unless $gene;
  my $features = $self->features_as_hash($gene->stable_id, $species, 'Gene', 'core', $gene);

  my $expand = $c->request->param('expand');
  if ($expand) {
    $features->{'Transcript'} = $self->Transcript($features->{id}, $species, 'core');
  }

  return $features;
}

sub find_genes_by_symbol_list {
  my ($self, $list) = @_;
  my %genes;
  while (my $symbol = shift @$list) {
    try {
      my $gene = find_gene_by_symbol($self,$symbol);
      $genes{$symbol} = $gene if $gene;
    }
    catch {
      
    };
  }
  return \%genes;
}

sub Transcript {
  my ($self, $id, $species, $db_type) = @_;

  my @transcripts;
  my $features;
  my $object = $self->find_object($id, $species, 'Gene', $db_type);
  my $transcripts = $object->get_all_Transcripts;
  foreach my $transcript (@$transcripts) {
    push @transcripts, $self->transcript_feature($transcript->stable_id, $species, $db_type);
  }
  return \@transcripts;
}

sub transcript_feature {
  my ($self, $id, $species, $db_type) = @_;
  my $features;
  my $transcript = $self->find_object($id, $species, 'Transcript', $db_type);
  $features = $self->features_as_hash($id, $species, 'Transcript', $db_type, $transcript);
  $features->{Exon} = $self->Exon($transcript, $species, $db_type);
  if ($transcript->translate) {
    my $translation = $transcript->translation;
    $features->{Translation} = $self->features_as_hash($translation->stable_id, $species, 'Translation', $db_type, $translation);
  }
  if ($self->context->request->param('utr')) {
    $features->{UTR} = $self->UTR($transcript, $species, $db_type) ;
  }
  if ($self->context->request->param('mane')) {
    $features->{MANE} = $self->MANE($transcript, $species, $db_type) ;
  }
  return $features;
}

sub UTR {
  my ($self, $transcript, $species, $db_type) = @_;

  my @utrs;
  my $features;
  my $five_utr = $transcript->get_all_five_prime_UTRs();
  foreach my $five (@$five_utr) {
    push @utrs, $self->features_as_hash($transcript->stable_id, $species, 'five_prime_UTR', $db_type, $five);
  }
  my $three_utr = $transcript->get_all_three_prime_UTRs();
  foreach my $three (@$three_utr) {
    push @utrs, $self->features_as_hash($transcript->stable_id, $species, 'three_prime_UTR', $db_type, $three);
  }

  return \@utrs;
}

sub MANE {
  my ($self, $transcript, $species, $db_type) = @_;

  my @manes;

  if ($transcript->is_mane) {
    push @manes, $self->features_as_hash($transcript->stable_id, $species, 'mane', $db_type, $transcript->mane_transcript);
  }
  
  return \@manes;
}

sub Exon {
  my ($self, $transcript, $species, $db_type) = @_;

  my @exons;
  my $exons = $transcript->get_all_Exons;
  foreach my $exon(@$exons) {
    push @exons, $self->features_as_hash($exon->stable_id, $species, 'Exon', $db_type, $exon);
  }

  return \@exons;
}


sub features_as_hash {
  my ($self, $id, $species, $object_type, $db_type, $obj) = @_;

  my $c = $self->context();
  my $format = $c->request->param('format') || 'full';
  my $features;
  $features->{id} = $id;
  $features->{species} = $species;
  $features->{object_type} = $object_type;
  $features->{db_type} = $db_type;

  if ($format eq 'full') {
    $obj = $self->find_object($id, $species, $object_type, $db_type) if !$obj;
    if($obj->can('summary_as_hash')) {
      my $summary_hash = $obj->summary_as_hash();
      $features->{version} = $obj->version() * 1 if $obj->version();
# Not all features have all labels
# Seq_region_name, start and end are available for genes, transcripts and exons but not translations
      $features->{seq_region_name} = $summary_hash->{seq_region_name} if defined $summary_hash->{seq_region_name};
      if (!$obj->isa('Bio::EnsEMBL::Translation')) {
        $features->{assembly_name} = $obj->slice->coord_system->version() if $obj->slice();
      }
      $features->{start} = $summary_hash->{start} * 1 if defined $summary_hash->{start};
      $features->{end} = $summary_hash->{end} * 1 if defined $summary_hash->{end};
      $features->{strand} = $summary_hash->{strand} * 1 if defined $summary_hash->{strand};
# Translations start and end are genomic coordinates
      $features->{start} = $summary_hash->{genomic_start} if defined $summary_hash->{genomic_start};
      $features->{end} = $summary_hash->{genomic_end} if defined $summary_hash->{genomic_end};
# Translation length provided separately
      $features->{length} = $summary_hash->{length} if defined $summary_hash->{length};
# Display_name and description are available for genes and sometimes for transcripts
      $features->{display_name} = $summary_hash->{Name} if defined $summary_hash->{Name};
      $features->{description} = $summary_hash->{description} if defined $summary_hash->{description};
      $features->{version} = $summary_hash->{version} * 1 if defined $summary_hash->{version};
# Biotype, source and logic_name are only available for genes and transcripts
      $features->{biotype} = $summary_hash->{biotype} if defined $summary_hash->{biotype};
      $features->{source} = $summary_hash->{source} if defined $summary_hash->{source};
      $features->{logic_name} = $summary_hash->{logic_name} if defined $summary_hash->{logic_name};
# Parent field to link back to gene/transcript where available
      $features->{Parent} = $summary_hash->{Parent} if defined $summary_hash->{Parent};
# MANE data fields linked to transcript
      $features->{refseq_match} = $summary_hash->{refseq_match} if defined $summary_hash->{refseq_match};
      $features->{type} = $summary_hash->{type} if defined $summary_hash->{type};
      if (lc($object_type) eq 'transcript') {
        $features->{is_canonical} = $obj->is_canonical;
        $features->{length} = $obj->length;
        $features->{gencode_primary} = $obj->gencode_primary; # boolean value for having GENCODE Primary attrib
      }
      if (lc($object_type) eq 'gene') {
        $features->{canonical_transcript} = $obj->canonical_transcript->stable_id.".".$obj->canonical_transcript->version;
      }
    } else {
      Catalyst::Exception->throw(qq{ID '$id' does not support 'full' format type. Please use 'condensed'});
    }
  } else{
    $obj = $self->find_object($id, $species, $object_type, $db_type) if !$obj;
    $features->{version} = $obj->version() * 1 if $obj->version();
  }

  return $features;
}

sub find_slice {
  my ($self, $region) = @_;
  my $c = $self->context();
  my $s = $c->stash();
  # don't do this.
  my $species = $s->{species};
  # or this
  my $db_type = $s->{db_type} || 'core';
  my $adaptor = $c->model('Registry')->get_adaptor($species, $db_type, 'slice');
  Catalyst::Exception->throw("Do not know anything about the species $species and core database") unless $adaptor;
  my $coord_system_version = $c->request->param('coord_system_version');
  my $coord_system_name = $c->request->param('coord_system') || 'toplevel';
  if ($coord_system_version && !$c->request->param('coord_system')) { $coord_system_name = 'chromosome'; }
  Catalyst::Exception->throw("Coord_system $coord_system_name is not valid") if $coord_system_name !~ /^[A-Za-z]+$/;
  my ($no_warnings, $no_fuzz, $ucsc_matching) = (undef, undef, 1);
  my $slice = $adaptor->fetch_by_location($region, $coord_system_name, $coord_system_version, $no_warnings, $no_fuzz, $ucsc_matching);
  Catalyst::Exception->throw("No slice found for location $region") unless $slice;
  $s->{slice} = $slice;
  return $slice;
}

sub decode_region {
  my ($self, $region, $no_warnings, $no_errors) = @_;
  my $c = $self->context();
  my $s = $c->stash();
  ## Add sanity check before API call to avoid stack trace
  my ($region_check, $start_check, $second_delimiter, $end_check, $strand_check) = $region =~ /^([0-9A-Za-z\_\.]+):?(-?[\w]*)(\.|_|-|:*)(-?[0-9A-Z]*):?(-?[0-9]?)/;  
  $start_check = 1 if !$start_check;
  $end_check = $start_check+1 if !$end_check;
  $strand_check = 1 if !$strand_check;
  Catalyst::Exception->throw("Location $region not understood") unless $region_check;
  Catalyst::Exception->throw("$start_check is not a valid start") if ($start_check < 0 || $start_check !~ /[0-9]+/);
  Catalyst::Exception->throw("$end_check is not a valid end") if $end_check !~ /[0-9]+/;
  Catalyst::Exception->throw("$strand_check is not a valid strand") if $strand_check !~ /^-?1$/;
  my $species = $s->{species};
  my $adaptor = $c->model('Registry')->get_adaptor($species, 'core', 'slice');
  Catalyst::Exception->throw("Do not know anything about the species $species and core database")unless $adaptor;
  my ($sr_name, $start, $end, $strand) = $adaptor->parse_location_to_values($region, $no_warnings, $no_errors);
  $strand = 1 if ! defined $strand;
  Catalyst::Exception->throw("Could not decode region $region") unless $sr_name;
  $s->{sr_name} = $sr_name;
  $s->{start} = $start;
  $s->{end} = $end;
  $s->{strand}= $strand;
  return ($sr_name, $start, $end, $strand);
}

sub ontology_accession_to_OntologyTerm {
  my ($self, $accession) = @_;
  my $c = $self->context();
  my $term_adaptor = $c->model('Registry')->get_ontology_term_adaptor();
  return $term_adaptor->fetch_by_accession($accession, 1);
}

sub phenotypes {
  my ($self, $id) = @_;
  my $c = $self->context();
  my $phenotypes = $c->model('Variation')->get_gene_phenotype_info($id);
  return $phenotypes;
}

__PACKAGE__->meta->make_immutable;

1;
