=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::EnsemblModel::Endpoint;

use Moose;

has 'description' => ( isa => 'Str', is => 'ro', required => 1 );
has 'endpoint'    => ( isa => 'Str', is => 'ro', required => 1 );
has 'method'      => ( isa => 'Str', is => 'ro', required => 1 );
has 'group'       => ( isa => 'Str', is => 'ro', required => 1 );
has 'output'      => ( isa => 'EnsRESTValueList', is => 'ro', required => 1, coerce => 1);
has 'params'      => ( isa => 'HashRef', is => 'ro', required => 0 );
has 'examples'    => ( isa => 'HashRef', is => 'ro', required => 0 );

sub has_required_params {
  my ($self) = @_;
  my $p = $self->params();
  return 0 unless $p;
  foreach my $key (keys %{$p}) {
    my $value = $p->{$key};
    return 1 if $value->{required};
  }
  return 0;
}

sub has_optional_params {
  my ($self) = @_;
  my $p = $self->params();
  return 0 unless $p;
  foreach my $key (keys %{$p}) {
    my $value = $p->{$key};
    return 1 if ! $value->{required};
  }
  return 0;
}

1;