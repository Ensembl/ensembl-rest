=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::Model::Biotype;

use Moose;
use Try::Tiny;
use Catalyst::Exception qw(throw);
use Scalar::Util qw/weaken/;
use List::MoreUtils qw(uniq);

use Bio::EnsEMBL::Utils::Scalar qw/assert_ref/;


extends 'Catalyst::Model';

with 'Catalyst::Component::InstancePerContext';

has 'context' => (is => 'ro', weak_ref => 1);


sub build_per_context_instance {
  my ($self, $c, @args) = @_;
  weaken($c);
  return $self->new({ context => $c, %$self, @args });
}

=head fetch_by_name_object_type

Fetches Biotype object by name and object_pype

=cut

sub fetch_by_name_object_type {

  my ($self, $name, $object_type) = @_;

  my $biotype_adaptor = $self->context->model('Registry')->get_adaptor( 'Homo_sapiens', 'Core', 'Biotype' );
  my $biotype = $biotype_adaptor->fetch_by_name_object_type( $name, $object_type );

  return $biotype;
}

=head fetch_biotype_groups

Retrieves list of biotype groups

=cut

sub fetch_biotype_groups {
  my ($self) = @_;

  my $dbc = $self->context->model('Registry')->get_adaptor( 'Homo_sapiens', 'Core', 'Biotype' )->db->dbc();

  my $sql = "SELECT DISTINCT biotype_group FROM biotype WHERE biotype_group IS NOT NULL ORDER BY biotype_group";
  my $biotypes = $dbc->sql_helper->execute_simple(-SQL => $sql);

  return $biotypes;
}

=head fetch_biotypes_by_group

Retrieves list of biotypes part of a provided biotype group

=cut

sub fetch_biotypes_by_group {
  my ($self, $group) = @_;

  my $dbc = $self->context->model('Registry')->get_adaptor( 'Homo_sapiens', 'Core', 'Biotype' )->db->dbc();

  my $sql = "SELECT name, biotype_group, object_type, so_acc FROM biotype WHERE biotype_group = \"$group\" ORDER BY object_type, name";

  my @biotypes;

  $dbc->sql_helper->execute_no_return(-SQL => $sql, -CALLBACK => sub {
    my ($row) = @_;

    my $biotype = {
      'name'          => $row->[0],
      'biotype_group' => $row->[1],
      'object_type'   => $row->[2],
      'so_acc'        => $row->[3]
    };

    push @biotypes, $biotype;
  });

  return \@biotypes;
}




=head fetch_biotypes_by_name

Retrieves biotypes with the provided name

=cut

sub fetch_biotypes_by_name {
  my ($self, $name) = @_;

  my $dbc = $self->context->model('Registry')->get_adaptor( 'Homo_sapiens', 'Core', 'Biotype' )->db->dbc();

  my $sql = "SELECT name, biotype_group, object_type, so_acc FROM biotype WHERE name = \"$name\" ORDER BY object_type, name";

  my @biotypes;

  $dbc->sql_helper->execute_no_return(-SQL => $sql, -CALLBACK => sub {
    my ($row) = @_;

    my $biotype = {
      'name'          => $row->[0],
      'biotype_group' => $row->[1],
      'object_type'   => $row->[2],
      'so_acc'        => $row->[3]
    };

    push @biotypes, $biotype;
  });

  return \@biotypes;
}

1;
