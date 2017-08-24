=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Model::BiotypeGroup;

use Moose;
use Catalyst::Exception qw(throw);
use Scalar::Util qw/weaken/;
use Bio::EnsEMBL::Variation::Utils::Constants qw(%OVERLAP_CONSEQUENCES);
extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';
has 'context' => (is => 'ro', weak_ref => 1);

sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

sub getBiotypesBySpecificGroup {
  my ($self) = @_;

  my $c = $self->context();
  my $biotypeGroup = $c->stash->{biotypeGroup};

  my $db_type = undef;
  my $object_type = undef;
  my $is_current = undef;

  $db_type = $c->request->param('db_type');
  $object_type = $c->request->param('object_type');
  $is_current = $c->request->param('is_current');

# These are the default values found in the ORM definition of the table Biotype
# from /ensembl-orm/modules/ORM/EnsEMBL/DB/Production/Object/Biotype.pm
  my @is_current = qw(0 1);
  my @object_type = qw(gene transcript);
  my @biotype_group = qw(coding pseudogene snoncoding lnoncoding mnoncoding LRG no_group undefined);
  my @db_type =qw(cdna core coreexpressionatlas coreexpressionest coreexpressiongnfv funcgen otherfeatures presite rnaseq sangervega variation vega);

  if ((defined $db_type) and ($self->_validate($c, $c->request->param('db_type'), \@db_type))) {

    $db_type = $c->request->param('db_type');
  }
  if ((defined $object_type) and ($self->_validate($c, $c->request->param('object_type'), \@object_type))) {

    $object_type = $c->request->param('object_type');
  }
  if ((defined $is_current) and ($self->_validate($c, $c->request->param('is_current'), \@is_current))) {

    $is_current = $c->request->param('is_current');
  }
  if ((defined $biotypeGroup) and ($self->_validate($c, $biotypeGroup, \@biotype_group))) {

    $is_current = $c->request->param('is_current');
  }

  $db_type = 'core' if not defined $db_type;
  $object_type = 'gene' if not defined $object_type;
  $is_current = '1' if not defined $is_current;

  my $dbAdaptor = $c->model('Registry')->get_DBAdaptor("multi",'production');

  $c->go('ReturnError', 'custom', ["Could not fetch adaptor"]) unless $dbAdaptor;

  my $managerBiotype = $dbAdaptor->get_biotype_manager();

  my $biotypeGroupsMembersHashRef;
  my %members;
  map { $members{$_->{name}}++ }
    @{$managerBiotype->get_objects(select => ['name'],
		query => [
				 biotype_group => $biotypeGroup,
				 db_type => { like =>"%$db_type%"},
				 object_type => "$object_type",
				 is_current => "$is_current"
				],
		distinct => 1)};

  my @keysArray = keys %members;
  if(@keysArray){

  $biotypeGroupsMembersHashRef->{$biotypeGroup} = \@keysArray;
  }

  if (not defined $biotypeGroupsMembersHashRef) {

  $biotypeGroupsMembersHashRef = {};
  }

return $biotypeGroupsMembersHashRef;
}

sub _validate {
  my ($self, $c, $inputParameter, $existingValues) = @_;

  my %parameters = map { $_ => 1 } @{$existingValues};
  if(exists($parameters{$inputParameter})) {

   return 1;
  }else{

    $c->go('ReturnError', 'custom', ["Invalid input: $inputParameter"]);
  }
}

with 'EnsEMBL::REST::Role::Content';

__PACKAGE__->meta->make_immutable;

1;

