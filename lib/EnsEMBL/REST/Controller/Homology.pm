=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Controller::Homology;
use Moose;
use namespace::autoclean;
use Try::Tiny;
require EnsEMBL::REST;

EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
  map => {
    'text/x-orthoxml+xml' => [qw/View OrthoXML_homology/],
  }
);

#We want to find every "non-special" format. To generate the regex used then invoke this command:
#perl -MRegexp::Assemble -e 'my $ra = Regexp::Assemble->new; $ra->add($_) for qw(application\/json text\/javascript text\/xml ); print $ra->re, "\n"'
my $CONTENT_TYPE_REGEX = qr/(?^:(?:text\/(?:javascript|xml)|application\/json))/;


my $FORMAT_LOOKUP = { full => '_full_encoding', condensed => '_condensed_encoding' };
my $TYPE_TO_COMPARA_TYPE = { orthologues => 'ENSEMBL_ORTHOLOGUES', paralogues => 'ENSEMBL_PARALOGUES', projections => 'ENSEMBL_PROJECTIONS', all => ''};

has default_compara => ( is => 'ro', isa => 'Str', default => 'multi' );

sub get_adaptors :Private {
  my ($self, $c) = @_;

  try {
    my $species = $c->stash()->{species};
    my $compara_dba = $c->model('Registry')->get_best_compara_DBAdaptor($species, $c->request()->param('compara'), $self->default_compara());
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
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
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
  } catch {
    $c->log->fatal(qq{No genes found for external id: $gene_symbol});
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
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
      $s->{gene_member_adaptor}->fetch_by_stable_id( $stable_id );
    } catch {
      $c->log->error(qq{Stable Id not found id db: $stable_id});
      $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
      $c->go('ReturnError', 'custom', [qq{$_}]);
    };

    if(! defined $member) {
      $c->log->debug('The ID '.$stable_id.' produced no member in compara');
      next;
    }

    my $all_homologies;
    try {
      my $ha = $s->{homology_adaptor};
      $all_homologies = $ha->fetch_all_by_Member($member,
          -TARGET_TAXON     => ($c->request->param('target_taxon')   ? [$c->request->param('target_taxon')]   : undef),
          -TARGET_SPECIES   => ($c->request->param('target_species') ? [$c->request->param('target_species')] : undef),
          -METHOD_LINK_TYPE => ($method_link_type || undef),
      );
    } catch {
      $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
      $c->go('ReturnError', 'custom', [qq{$_}]);
    };
    push(@final_homologies, {
      id => $stable_id,
      homologies => $all_homologies,
    });
  }
  
  $c->stash(homology_data => \@final_homologies);
}

sub _full_encoding {
  my ($self, $c, $homologies, $stable_id) = @_;
  my @output;
  
  my $seq_type = $c->request->param('sequence') || 'protein';
  my $aligned = $c->request->param('aligned');
  $aligned = 1 unless defined $aligned;
  my $cigar_line = $c->request->param('cigar_line');
  $cigar_line = 1 unless defined $cigar_line;
  
  my $encode = sub {
    my ($member) = @_;
    my $gene = $member->gene_member();
    my $genome_db = $gene->genome_db();
    my $taxon_id = $genome_db->taxon_id();
    my $result = {
      id => $gene->stable_id(),
      species => $genome_db->name(),
      perc_id => ($member->perc_id()*1),
      perc_pos => ($member->perc_pos()*1),
      protein_id => $gene->get_canonical_SeqMember()->stable_id(),
    };
    $result->{cigar_line} = $member->cigar_line() if $cigar_line;
    $result->{taxon_id} = ($taxon_id+0) if defined $taxon_id;
    if($aligned && $member->cigar_line()) {
      if($seq_type eq 'protein') {
        $result->{align_seq} = $member->alignment_string();
      }
      elsif($seq_type eq 'cdna') {
       $result->{align_seq} = $member->alignment_string('cds');
       $result->{align_seq} =~ s/\s//g;
      }
    }
    else {
      if($seq_type eq 'protein') {
        $result->{seq} = $member->sequence();
      }
      elsif($seq_type eq 'cdna') {
        $result->{seq} = $member->other_sequence('cds');
      }
    }
    return $result;
  };
  
  while(my $h = shift @{$homologies}) {
    my ($src, $trg) = $self->_decode_members($h, $stable_id);
    my $e = {
      type => $h->description(),
      taxonomy_level => $h->taxonomy_level(),
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
      taxonomy_level => $h->taxonomy_level(),
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

sub get_orthologs_GET {
  my ( $self, $c ) = @_;

  if($self->is_content_type($c, $CONTENT_TYPE_REGEX)) {
    my $format = $c->request->param('format') || 'full';
    my $target = $FORMAT_LOOKUP->{$format};
    foreach my $ref (@{$c->stash->{homology_data}}) {
        $ref->{homologies} = $self->$target($c, $ref->{homologies}, $ref->{id});
    }
    return $self->status_ok( $c, entity => { data => $c->stash->{homology_data} } );

  } else {
    # Let's use the OrthoXML writer
    my @homologies;
    foreach my $ref (@{$c->stash->{homology_data}}) {
      push @homologies, @{$ref->{homologies}};
    }
    return $self->status_ok($c, entity => \@homologies);
  }
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
