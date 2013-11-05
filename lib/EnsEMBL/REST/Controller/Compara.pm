package EnsEMBL::REST::Controller::Compara;
use Moose;
use namespace::autoclean;
use Try::Tiny;
require EnsEMBL::REST;

EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

BEGIN { extends 'Catalyst::Controller::REST'; }

my $FORMAT_LOOKUP = { full => '_full_encoding', condensed => '_condensed_encoding' };
my $TYPE_TO_COMPARA_TYPE = { orthologues => 'ENSEMBL_ORTHOLOGUES', paralogues => 'ENSEMBL_PARALOGUES', projections => 'ENSEMBL_PROJECTIONS', all => ''};

has default_compara => ( is => 'ro', isa => 'Str', default => 'multi' );

sub get_adaptors :Private {
  my ($self, $c) = @_;

  try {
    my $species = $c->stash()->{species};
    my $compara_dba = $c->model('Registry')->get_best_compara_DBAdaptor($species, $c->request()->param('compara'));
    my $gma = $compara_dba->get_GeneMemberAdaptor();
    my $sma = $compara_dba->get_SeqMemberAdaptor();
    my $ha = $compara_dba->get_HomologyAdaptor();
    my $mlssa = $compara_dba->get_MethodLinkSpeciesSetAdaptor();
    my $ma = $compara_dba->get_MethodAdaptor();
    my $gdba = $compara_dba->get_GenomeDBAdaptor();
    my $asa = $compara_dba->get_AlignSliceAdaptor();
    my $gata = $compara_dba->get_GenomicAlignTreeAdaptor();
    my $gaba = $compara_dba->get_GenomicAlignBlockAdaptor();
    
    $c->stash(
      gene_member_adaptor => $gma,
      homology_adaptor => $ha,
      method_link_species_set_adaptor => $mlssa,
      genome_db_adaptor => $gdba,
      align_slice_adaptor => $asa,
      genomic_align_tree_adaptor => $gata,
      genomic_align_block_adaptor => $gaba,
      method_adaptor => $ma,
    );
  }
  catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };
}

sub fetch_by_ensembl_gene : Chained("/") PathPart("homology/id") Args(1)  {
  my ( $self, $c, $id ) = @_;
  my $lookup = $c->model('Lookup');
  my ($species) = $lookup->find_object_location($id);
  $c->go('ReturnError', 'custom', ["Could not find the ID '${id}' in any database. Please try again"]) if ! $species;
  $c->stash(stable_ids => [$id], species => $species);
  $c->detach('get_orthologs');
}

sub fetch_by_gene_symbol : Chained("/") PathPart("homology/symbol") Args(2)  {
  my ( $self, $c, $species, $gene_symbol ) = @_;
  my $genes;
  try {
    $c->stash(species => $species);
    $c->request->param('object', 'gene');
    my $local_genes = $c->model('Lookup')->find_objects_by_symbol($gene_symbol);
    $genes = [grep { $_->slice->is_reference() } @{$local_genes}];
    # my $adaptor = $c->model('Registry')->get_adaptor( $species, 'Core', 'Gene' );
    # $c->go('ReturnError', 'custom', ["No core gene adaptor found for $species"]) unless $adaptor;
    # $c->stash->{gene_adaptor} = $adaptor;
    # my $external_db = $c->request->param('external_db');
    # $genes = $adaptor->fetch_all_by_external_name($gene_symbol, $external_db);
  }
  catch {
    $c->log->fatal(qq{No genes found for external id: $gene_symbol});
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };
  unless ( defined $genes ) {
      $c->log->fatal(qq{Nothing found in DB for : [$gene_symbol]});
      $c->go( 'ReturnError', 'custom', [qq{No content for [$gene_symbol]}] );
  }
  my @gene_stable_ids = map { $_->stable_id } @$genes;
  if(! @gene_stable_ids) {
    $c->go('ReturnError','custom', "Cannot find a suitable gene for the symbol '${gene_symbol}' and species '${species}");
  }
  $c->stash->{stable_ids} = \@gene_stable_ids;
  $c->detach('get_orthologs');
}

sub get_orthologs : Args(0) ActionClass('REST') {
  my ($self, $c) = @_;
  my $s = $c->stash();
  
  #Get the compara DBAdaptor
  $c->forward('get_adaptors');
  
  # Sort out the encoder
  my $format = $c->request->param('format') || 'full';
  my $target = $FORMAT_LOOKUP->{$format};
  $c->go('ReturnError', 'custom', [qq{The format '$format' is not an understood encoding}]) unless $target;
  
  #Sort out the type of response
  my $user_type = $c->request->param('type') || 'all';
  my $method_link_type= $TYPE_TO_COMPARA_TYPE->{lc($user_type)};
  $c->go('ReturnError', 'custom', [qq{The type '$user_type' is not a known available type}]) unless defined $method_link_type;
  $c->stash(method_link_type => $method_link_type);
  
  my @final_homologies;
  
  #Loop for stable IDs
  foreach my $stable_id ( @{ $s->{stable_ids} } ) {
    my $member = try { 
      $c->log->debug('Searching for gene member linked to ', $stable_id);
      $s->{gene_member_adaptor}->fetch_by_source_stable_id( "ENSEMBLGENE", $stable_id );
    }
    catch {
      $c->log->error(qq{Stable Id not found id db: $stable_id});
      $c->go( 'ReturnError', 'custom', [qq{stable id '$stable_id' not found}] );
    };

    if(! defined $member) {
      $c->log->debug('The ID '.$stable_id.' produced no member in compara');
      next;
    }

    my $all_homologies;
    try {
      my $ha = $s->{homology_adaptor};
      
      if($c->request->param('target_species') || $c->request->param('target_taxon')) {
        $c->log->debug('Limiting on species/taxons');
        $all_homologies = [];
        my $mlss_array = $self->_method_link_species_sets($c, $member);
        foreach my $mlss (@{$mlss_array}) {
          $c->log->debug('Searching for ', $method_link_type, ' with MLSS ID ', $mlss->dbID(), ' (', ($mlss->name() || q{-}), ')');
	  my $r = $ha->fetch_all_by_Member($member, -METHOD_LINK_SPECIES_SET => $mlss);
          push(@{$all_homologies}, @{$r});
        }
      }
      elsif($method_link_type) {
	$all_homologies = $ha->fetch_all_by_Member($member, -METHOD_LINK_TYPE => $method_link_type);
      }
      else {
        $all_homologies = $ha->fetch_all_by_Member($member);
      }
    }
    catch {
      $c->go('ReturnError', 'from_ensembl', [$_] );
    };
    my $encoded_homologies = $self->$target($c, $all_homologies, $stable_id);
    push(@final_homologies, {
      id => $stable_id,
      homologies => $encoded_homologies,
    });
  }
  
  $c->stash(homology_data => \@final_homologies);
}

sub _method_link_species_sets {
  my ($self, $c, $member) = @_;
  
  my $mlssa = $c->stash->{method_link_species_set_adaptor};
  my $gdba = $c->stash->{genome_db_adaptor};
  
  my @mlss;
  
  #Types
  my @types;
  if($c->stash->{method_link_type}) {
    @types = ($c->stash->{method_link_type});
  }
  else {
    @types = qw/ENSEMBL_ORTHOLOGUES ENSEMBL_PARALOGUES/;
  }
  
  #If someone has requested species then limit by MLSS
  my @target_species = $c->request->param('target_species');
  my $source_name = $member->genome_db()->name();  
  foreach my $target (@target_species) {
    foreach my $ml_type (@types) {
      my $r = $mlssa->fetch_by_method_link_type_registry_aliases($ml_type, [$source_name, $target]);
      push(@mlss, $r);
    }
  }
  
  #Could be taxon identifiers though
  my @target_taxons = $c->request->param('target_taxon');
  my $source_gdb = $member->genome_db();
  foreach my $taxon (@target_taxons) {
    my $gdb = $gdba->fetch_by_taxon_id($taxon);
    foreach my $ml_type (@types) {
      my $gdbs = [$source_gdb, $gdb];
      my $r = $mlssa->fetch_by_method_link_type_GenomeDBs($ml_type, $gdbs);
      if(! $r) {
        $c->log->info('Cannot get a MLSS for ', $ml_type, ' and [', map({$_->name()} @{$gdbs}), ']');
        next;
      }
      push(@mlss, $r);
    }
  }
  
  return \@mlss;
}

sub get_orthologs_GET {
  my ( $self, $c ) = @_;
  $self->status_ok( $c, entity => { data => $c->stash->{homology_data} } );
}

sub _full_encoding {
  my ($self, $c, $homologies, $stable_id) = @_;
  my @output;
  
  my $seq_type = $c->request->param('sequence') || 'protein';
  my $aligned = $c->request->param('aligned');
  $aligned = 1 unless defined $aligned;
  
  my $encode = sub {
    my ($member) = @_;
    my $gene = $member->gene_member();
    my $result = {
      id => $gene->stable_id(),
      species => $gene->genome_db()->name(),
      perc_id => ($member->perc_id()*1),
      perc_pos => ($member->perc_pos()*1),
      cigar_line => $member->cigar_line(),
      protein_id => $gene->get_canonical_SeqMember()->stable_id(),
    };
    if($aligned && $member->cigar_line()) {
      if($seq_type eq 'protein') {
        $result->{align_seq} = $member->alignment_string();
      }
      elsif($seq_type eq 'cdna') {
       $result->{align_seq} = $member->cdna_alignment_string();
       $result->{align_seq} =~ s/\s//g;
      }
    }
    else {
      if($seq_type eq 'protein') {
        $result->{seq} = $member->sequence();
      }
      elsif($seq_type eq 'cdna') {
        $result->{seq} = $member->sequence_cds();
      }
    }
    return $result;
  };
  
  while(my $h = shift @{$homologies}) {
    my ($src, $trg) = $self->_decode_members($h, $stable_id);
    my $type = $h->description();
    my $e = {
      type => $type,
      subtype => $h->subtype(),
      dn_ds => $h->dnds_ratio(),
      source => $encode->($src),
      target => $encode->($trg),
      method_link_type => $h->method_link_species_set()->method()->type(),
    };
    $e->{dn_ds} = $e->{dn_ds}*1 if defined $e->{dn_ds};
    push(@output, $e);
  }
  return \@output;
}

sub _condensed_encoding {
  my ($self, $c, $homologies, $stable_id) = @_;
  $c->log()->debug('Starting condensed encoding');
  my @output;
  while(my $h = shift @{$homologies}) {
    my ($src, $trg) = $self->_decode_members($h, $stable_id);
    my $gene_member = $trg->gene_member();
    my $e = {
      type => $h->description(),
      subtype => $h->subtype(),
      id => $gene_member->stable_id(),
      protein_id => $gene_member->get_canonical_SeqMember()->stable_id(),
      species => $gene_member->genome_db->name(),
      method_link_type => $h->method_link_species_set()->method()->type(),
    };
    push(@output, $e);
  }
  $c->log()->debug('Finished condensed encoding');
  return \@output;
}

sub _decode_members {
  my ($self, $h, $stable_id) = @_;
  my ($src, $trg);
  foreach my $m (@{$h->get_all_Members()}) {
    if($m->gene_member()->stable_id() eq $stable_id) {
      $src = $m;
    }
    else {
      $trg = $m;
    }
  }
  return ($src, $trg);
}

__PACKAGE__->meta->make_immutable;

1;
