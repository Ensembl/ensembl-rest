=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::REST::View::HTML;
use Moose;
use namespace::autoclean;
use File::Spec;
use Template::Stash::XS;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    RENDER_DIE => 1,
    WRAPPER => 'wrapper.tt',
    COMPILE_DIR => File::Spec->catdir(File::Spec->tmpdir(), $ENV{USER}, 'ensrest', 'template_cache'),
    STASH => Template::Stash::XS->new(),
);

1;
