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

package EnsEMBL::REST::Controller::GenomicAlignment;
use Moose;
use namespace::autoclean;
use Try::Tiny;
require EnsEMBL::REST;

BEGIN { extends 'Catalyst::Controller::REST'; }

has 'default_compara' => ( is => 'ro', isa => 'Str', default => 'vertebrates' );
has 'compara_base_dir_location' => ( is => 'ro', isa => 'Str' );
has 'max_slice_length' => ( isa => 'Num', is => 'ro', default => 1e6);

__PACKAGE__->config(
  default => 'text/html',
  map => {
    'text/html'           => [qw/View PhyloXMLHTML/],
    'text/x-phyloxml+xml' => [qw/View PhyloXML/],
    'text/x-phyloxml'     => [qw/View PhyloXML/], #naughty but needs must
    'text/xml'            => [qw/View PhyloXML/],
  }
);

EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);

#We want to find every "non-special" format. To generate the regex used then invoke this command:
#perl -MRegexp::Assemble -e 'my $ra = Regexp::Assemble->new; $ra->add($_) for qw(application\/json text\/javascript text\/x-yaml); print $ra->re, "\n"'
my $CONTENT_TYPE_REGEX = qr/(?^:(?:text\/(?:javascript|x-yaml)|application\/json))/;

sub get_adaptors :Private {
  my ($self, $c) = @_;

  try {
    my $species = $c->stash()->{species};
    my $compara_dba = $c->model('Registry')->get_best_compara_DBAdaptor($species, $c->request()->param('compara'), $self->default_compara());

    my $ma = $compara_dba->get_MethodAdaptor();
    my $mlssa = $compara_dba->get_MethodLinkSpeciesSetAdaptor();
    my $gdba = $compara_dba->get_GenomeDBAdaptor();
    my $asa = $compara_dba->get_AlignSliceAdaptor();
    my $gata = $compara_dba->get_GenomicAlignTreeAdaptor();
    my $gaba = $compara_dba->get_GenomicAlignBlockAdaptor();

    $mlssa->base_dir_location($self->compara_base_dir_location());
    
    $c->stash(
      compara_dba => $compara_dba,
      method_adaptor => $ma,
      method_link_species_set_adaptor => $mlssa,
      genome_db_adaptor => $gdba,
      align_slice_adaptor => $asa,
      genomic_align_tree_adaptor => $gata,
      genomic_align_block_adaptor => $gaba,
    );
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
}


sub get_species : Chained("/") PathPart("alignment/region") CaptureArgs(1) {
  my ( $self, $c, $species ) = @_;
  $c->stash->{species} = $species;
}

sub region_GET { }

sub region : Chained("get_species") PathPart("") Args(1) ActionClass('REST') {
    my ( $self, $c, $region ) = @_;

    #getting GenomicAlignBlock or GenomicAlignTree alignments
    my $alignments;
    try {
      my ($sr_name) = $c->model('Lookup')->decode_region( $region, 1, 1 );
      my $slice = $c->model('Lookup')->find_slice($region);

      #Check for maximum slice length
      $self->assert_slice_length($c, $slice);

      $alignments = $c->model('GenomicAlignment')->get_alignment($slice);
    } catch {
      $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
      $c->go('ReturnError', 'custom', [qq{$_}]);
    };

    #Set aligned option (default from config)
    my $compara_defaults = $c->config->{'Model::Compara'};
    if ( defined $c->request()->param('aligned') ) {
        $c->stash->{"aligned"} = $c->request()->param('aligned');
    } else {
        $c->stash->{"aligned"} = $compara_defaults->{aligned};
    }

    #Set compact option (default from config)
    if ( defined $c->request->param('compact') ) {
        $c->stash->{"compact"} = $c->request->param('compact');
    } else {
        $c->stash->{"compact"} = $compara_defaults->{compact};
    }

    #Set no branch lengths option (default 0, ie display branch lengths)
    if ( defined $c->request->param('no_branch_lengths') ) {
        $c->stash->{"no_branch_lengths"} = $c->request->param('no_branch_lengths');
    } else {
        $c->stash->{"no_branch_lengths"} = $compara_defaults->{no_branch_lengths};
    }

    #Never give branch lengths for pairwise, even if requested
    $c->go("ReturnError", "custom", ["no alignment available for this region"]) if !$alignments;
    my $mlss = $alignments->[0]->method_link_species_set;
    if ($mlss->method->class eq "GenomicAlignBlock.pairwise_alignment") {
      $c->stash->{"no_branch_lengths"} = 0;
    } 

    if($self->is_content_type($c, $CONTENT_TYPE_REGEX)) {
       my $tree_hash = $c->model('GenomicAlignment')->get_tree_as_hash($alignments);
      $self->status_ok($c, entity => $tree_hash);
      return;
    }

    $self->status_ok($c, entity => $alignments);
    return;
}

#This is deprecated. 
sub get_slice_species : Chained("/") PathPart("alignment/slice/region") CaptureArgs(1) {
  my ( $self, $c, $species ) = @_;
  #$c->stash->{species} = $species;

   $c->go( 'ReturnError', 'custom',
        [qq{/alignment/slice/region is deprecated. See http://rest.ensembl.org/alignment/region for alternative}] );

}

#This is deprecated and will be forwarded to alignment/region
sub get_block_species : Chained("/") PathPart("alignment/block/region") CaptureArgs(1) {
  my ( $self, $c, $species ) = @_;

  $c->stash->{species} = $species;
}

sub block_region_GET { }

sub block_region : Chained("get_block_species") PathPart("") Args(1) ActionClass('REST') {
    my ( $self, $c, $region ) = @_;

    $c->detach('EnsEMBL::REST::Controller::GenomicAlignment','region', $region);
}

with 'EnsEMBL::REST::Role::SliceLength';
with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;
