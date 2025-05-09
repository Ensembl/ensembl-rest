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

package EnsEMBL::REST::EnsemblModel::ExternalDB;

=pod

=head1 NAME

EnsEMBL::REST::EnsemblModel::ExternalDB
 
=head1 DESCRIPTION

Provides access to all external DBs in a given database. Please use the
C<EnsEMBL::REST::EnsemblModel::ExternalDB::get_ExternalDBs()> method
to populate the object.

=cut

use Moose;
use Bio::EnsEMBL::Utils::Scalar qw/assert_ref/;

=head2 ATTRIBUTES

=over 8

=item id - Integer Internal ID of the ExternalDB

=item name - String Name for the ExternalDB. Used in any endpoint when an external_db param is requested

=item release - Maybe[String] Optional release information of the ExternalDB

=item display_name - String Human readable name of the ExternalDB

=item description - Maybe[String] Verbose description of the ExternalDB

=back

=cut

has 'id'            => ( isa => 'Int', is => 'ro', required => 1);
has 'name'          => ( isa => 'Str', is => 'ro', required => 1 );
has 'release'       => ( isa => 'Maybe[Str]', is => 'ro', required => 1 );
has 'display_name'  => ( isa => 'Str', is => 'ro', required => 1 );
has 'description'   => ( isa => 'Maybe[Str]', is => 'ro', required => 1 );

=head2 get_ExternalDBs

  Args [1]    : DBAdaptor DBAdaptor to lookup external dbs in. Must be a core-like schema
  Args [2]    : String Filter pattern to apply to the query. Supports SQL like statements
  Example     : my $external_dbs = EnsEMBL::REST::EnsemblModel::ExternalDB->get_ExternalDBs($dba);
                my $go_external_dbs = EnsEMBL::REST::EnsemblModel::ExternalDB->get_ExternalDBs($dba, 'GO%');
  Description : Finds all external DBs in the given species' core database
  Returntype  : ArrayRef of ExternalDB objects
  Exceptions  : SQL based exceptions

=cut

sub get_ExternalDBs {
  my ($class, $dba, $filter, $feature) = @_;
  assert_ref($dba, 'Bio::EnsEMBL::DBSQL::DBAdaptor', 'DBAdaptor');
  $filter ||= '%';
  my $sql = <<'SQL';
select distinct e.external_db_id, e.db_name, e.db_release, e.db_display_name, e.description
from external_db e where db_name like ?
SQL
  if ($feature) {
    my @dbis = @{ $dba->dbc->sql_helper->execute_simple(-SQL => "select distinct external_db_id from $feature where external_db_id is not null") };
    my $list = join( ',', @dbis );
    $sql .= " and e.external_db_id in ($list)";
  }
  my $results = $dba->dbc->sql_helper->execute(-SQL => $sql, -PARAMS => [$filter], -CALLBACK => sub {
    my ($row) = @_;
    my ($id, $name, $release, $display_name, $description) = @{$row};
    return $class->new(
      id => $id, name => $name, release => $release, 
      display_name => $display_name, description => $description
    );
  });
  return $results;
}

=head2 summary_as_hash

  Example     : my $hash = $obj->summary_as_hash();
  Description : Converts the current object into an unblessed hash fit for
                serialisation purposes
  Returntype  : HashRef Basic representation of the current object

=cut

sub summary_as_hash {
  my ($self) = @_;
  return { 
    name          => $self->name(), 
    release       => $self->release(), 
    display_name  => $self->display_name(), 
    description   => $self->description() 
  };
}

1;
