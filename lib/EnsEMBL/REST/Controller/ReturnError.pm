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

package EnsEMBL::REST::Controller::ReturnError;
use Moose;
use namespace::autoclean;
use Carp::Clan qw(^EnsEMBL::REST::Controller::);
BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
    'default'   => 'application/json',
    'stash_key' => 'rest',
    'map'       => {
        'text/x-yaml'       => 'YAML::XS',
        'application/json'  => 'JSON::XS',
        'text/plain'        => 'JSON::XS',
        'text/html'         => 'YAML::HTML',
    }
);

sub index : Path : Args(0) : ActionClass('REST') {
    my ( $self, $c, $raw_error ) = @_;

    $c->log->error($raw_error);


    #     #     $error =~ s/\n/\\x/g;
    #     $error = "thist!";
    #     $error =~ s/s/\n/g;
    #     $c->log->warn( 'ERROR: ', $error );
    # my $raw_msg = $c->stash->{error};
    my ($error_cleaned) = $raw_error =~ m/MSG:\s(.*?)STACK/s;
    $error_cleaned ||= 'something bad has happened';
    $error_cleaned =~ s/\n//g;
    $self->status_bad_request( $c, message => $error_cleaned );
}

sub index_GET { }
sub index_POST { }

sub from_ensembl : Path : Args(0) : ActionClass('REST') {
    my ( $self, $c, $raw_error ) = @_;
    my $error_no_linebreak = $raw_error;
    $error_no_linebreak =~ s/\n//g;
    $c->log->error($error_no_linebreak);
    my ($error_cleaned) = $raw_error =~ m/MSG:\s(.*?)STACK/s;
    $error_cleaned ||= 'something bad has happened';
    $error_cleaned =~ s/\n//g;
    $self->status_bad_request( $c, message => $error_cleaned );
}

sub from_ensembl_GET { }
sub from_ensembl_POST { }

sub custom : Path : Args(0) : ActionClass('REST') {
    my ( $self, $c, $error_msg ) = @_;
    $c->log->error($error_msg);
    
    $self->status_bad_request( $c, message => $error_msg );
}

sub custom_GET { }
sub custom_POST { }

sub no_content: Path : Args(0) : ActionClass('REST') {
    my ( $self, $c, $error_msg ) = @_;
    $c->log->error($error_msg);
    $self->status_no_content( $c, message => $error_msg );
}

sub no_content_GET { }
sub no_content_POST { }

sub not_found: Path : Args(0) : ActionClass('REST') {
    my ( $self, $c, $error_msg ) = @_;
    $self->status_not_found($c, message => $error_msg);
}

sub not_found_GET { }
sub not_found_POST { }
__PACKAGE__->meta->make_immutable;

1;
