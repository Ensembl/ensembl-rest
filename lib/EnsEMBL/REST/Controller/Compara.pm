package EnsEMBL::REST::Controller::Compara;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use EnsEMBL::REST;

EnsEMBL::REST->turn_on_jsonp(__PACKAGE__);

BEGIN { extends 'Catalyst::Controller::REST'; }

my $FORMAT_LOOKUP = { full => '_full_encoding', condensed => '_condensed_encoding' };
my $TYPE_TO_COMPARA_TYPE = { orthologues => 'ENSEMBL_ORTHOLOGUES', paralogues => 'ENSEMBL_PARALOGUES', all => ''};

sub get_adaptors :Private {
  my ($self, $c) = @_;
  
  my $reg = $c->model('Registry');
  my $default_compara = EnsEMBL::REST->config()->{Compara}->{default_compara};
  my $compara_name = $c->request()->param('compara') || $default_compara;
  
  try {
    my $ma = $reg->get_adaptor($compara_name, 'compara', 'member');
    $c->go('ReturnError', 'custom', ["No MemberAdaptor found for $compara_name"]) unless $ma;
    $c->stash(member_adaptor => $ma);
  
    my $ha = $reg->get_adaptor($compara_name, 'compara', 'homology');
    $c->go('ReturnError', 'custom', ["No HomologyAdaptor found for $compara_name"]) unless $ha;
    $c->stash(homology_adaptor => $ha);
    
    my $mlssa = $reg->get_adaptor($compara_name, 'compara', 'methodlinkspeciesset');
    $c->go('ReturnError', 'custom', ["No MethodLinkSpeciesSetAdaptor found for $compara_name"]) unless $mlssa;
    $c->stash(method_link_species_set_adaptor => $mlssa);
    
    my $gdba = $reg->get_adaptor($compara_name, 'compara', 'genomedb');
    $c->go('ReturnError', 'custom', ["No GenomeDB found for $compara_name"]) unless $gdba;
    $c->stash(genome_db_adaptor => $gdba);
  }
  catch {
    $c->go('ReturnError', 'from_ensembl', [$_]);
  };
}

sub fetch_by_ensembl_gene : Chained("/") PathPart("homology/id") Args(1)  {
  my ( $self, $c, $id ) = @_;
  $c->forward('get_adaptors');
  my $lookup = $c->model('Lookup');
  my ($species) = $lookup->find_object_location($c, $id);
  $c->stash(stable_ids => [$id], species => $species);
  $c->detach('get_orthologs');
}

sub fetch_by_gene_symbol : Chained("/") PathPart("homology/symbol") Args(2)  {
  my ( $self, $c, $species, $gene_symbol ) = @_;
  $c->forward('get_adaptors');
  my $genes;
  try {
    $c->stash(species => $species);
    my $adaptor = $c->model('Registry')->get_adaptor( $species, 'Core', 'Gene' );
    $c->go('ReturnError', 'custom', ["No core gene adaptor found for $species"]) unless $adaptor;
    $c->stash->{gene_adaptor} = $adaptor;
    my $external_db = $c->request->param('external_db');
    $genes = $adaptor->fetch_all_by_external_name($gene_symbol, $external_db);
  }
  catch {
    $c->log->fatal(qq{No genes found for external id: $gene_symbol});
    $c->go( 'ReturnError', 'no content', [$_] );
  };
  unless ( defined $genes ) {
      $c->log->fatal(qq{Nothing found in DB for : [$gene_symbol]});
      $c->go( 'ReturnError', 'no_content', [qq{No content for [$gene_symbol]}] );
  }
  my @gene_stable_ids = map { $_->stable_id } @$genes;
  $c->stash->{stable_ids} = \@gene_stable_ids;
  $c->detach('get_orthologs');
}

sub get_orthologs : Args(0) ActionClass('REST') {
  my ($self, $c) = @_;
  my $s = $c->stash();
  
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
      $s->{member_adaptor}->fetch_by_source_stable_id( "ENSEMBLGENE", $stable_id );
    }
    catch {
      $c->log->error(qq{Stable Id not found id db: $stable_id});
      $c->go( 'ReturnError', 'custom', [qq{stable id '$stable_id' not found}] );
    };
    my $all_homologies;
    try {
      if($c->request->param('target_species') || $c->request->param('target_taxon')) {
        $c->log->debug('Limiting on species/taxons');
        $all_homologies = [];
        my $mlss_array = $self->_method_link_speices_sets($c, $member);
        my $ha = $s->{homology_adaptor};
        foreach my $mlss (@{$mlss_array}) {
          $c->log->debug('Searching for ', $method_link_type, ' with MLSS ID ', $mlss->dbID(), ' (', ($mlss->name() || q{-}), ')');
          my $r = $ha->fetch_all_by_Member_MethodLinkSpeciesSet($member, $mlss);
          push(@{$all_homologies}, @{$r});
        }
      }
      elsif($method_link_type) {
        $all_homologies = $s->{homology_adaptor}->fetch_all_by_Member_method_link_type($member, $method_link_type);
      }
      else {
        $all_homologies = $s->{homology_adaptor}->fetch_all_by_Member($member);
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

sub _method_link_speices_sets {
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
  my $target_species = $c->request->param('target_species') || [];
  my $ts_ref = ref($target_species);
  $target_species = [$target_species] if ! $ts_ref|| $ts_ref ne 'ARRAY';
  my $source_name = $member->genome_db()->name();
  
  foreach my $target (@{$target_species}) {
    foreach my $ml_type (@types) {
      my $r = $mlssa->fetch_by_method_link_type_registry_aliases($ml_type, [$source_name, $target]);
      push(@mlss, $r);
    }
  }
  
  #Could be taxon identifiers though
  my $target_taxons = $c->request->param('target_taxon') || [];
  my $tt_ref = ref($target_taxons);
  $target_taxons = [$target_taxons] if ! $tt_ref|| $tt_ref ne 'ARRAY';
  my $source_gdb = $member->genome_db();
  
  foreach my $taxon (@{$target_taxons}) {
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
  
  my $encode = sub {
    my ($member) = @_;
    my $gene = $member->gene_member();
    return {
      id => $gene->stable_id(),
      species => $gene->genome_db()->name(),
      perc_id => $member->perc_id(),
      perc_pos => $member->perc_pos(),
      cigar_line => $member->cigar_line(),
      protein_id => $gene->get_canonical_Member()->stable_id(),
      align_seq => $member->alignment_string()
    };
  };
  
  while(my $h = shift @{$homologies}) {
    my ($src, $trg) = $self->_decode_members($h, $stable_id);
    my $e = {
      type => $h->description(),
      subtype => $h->subtype(),
      dn_ds => $h->dnds_ratio(),
      source => $encode->($src),
      target => $encode->($trg),
    };
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
      protein_id => $gene_member->get_canonical_Member()->stable_id(),
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
