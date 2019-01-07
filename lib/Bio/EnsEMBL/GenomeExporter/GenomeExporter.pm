#!/usr/bin/env perl
=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

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

use warnings;
use strict;

package Bio::EnsEMBL::GenomeExporter::GenomeExporterApi;

sub export_genes {
  my ($self, $dba, $biotypes) = @_;
  my @genes;
  my $ga = $dba->get_GeneAdaptor();
  my $xa = $dba->get_DBEntryAdaptor();
  if (defined $biotypes) {
	for my $biotype (@{$biotypes}) {
	  @genes = (@genes, @{$ga->fetch_all_by_biotype($biotype)});
	}
  }
  else {
	@genes = @{$ga->fetch_all()};
  }
  my @output = ();
  for my $gene (@genes) {
	my $gene_out = $self->_hash_gene($xa, $gene);
	push @output, $gene_out;
  }
  return \@output;
}

sub _hash_gene {
  my ($self, $xa, $gene) = @_;
  my $gene_out = {id       => $gene->stable_id(),
				  name     => $gene->external_name(),
				  biotype  => $gene->biotype(),
				  description     => $gene->description(),
				  start           => $gene->seq_region_start(),
				  end             => $gene->seq_region_end(),
				  strand          => $gene->seq_region_strand(),
				  seq_region_name => $gene->seq_region_name(),
				  transcripts     => []};
  if(defined                   $gene->display_xref()) {
      $gene_out->{synonyms} = $gene->display_xref()->get_all_synonyms();
  }
  for my $dbentry (@{$xa->fetch_all_by_Gene($gene)}) {
	push @{$gene_out->{xrefs}}, $self->_hash_xref($dbentry);
  }
  for my $transcript (@{$gene->get_all_Transcripts()}) {
	push @{$gene_out->{transcripts}},
	  $self->_hash_transcript($xa, $transcript);
  }
  return $gene_out;
}

sub _hash_transcript {
  my ($self, $xa, $transcript) = @_;
  my $transcript_out = {
					   id          => $transcript->stable_id(),
					   name        => $transcript->external_name(),
					   biotype     => $transcript->biotype(),
					   description => $transcript->description(),
					   start       => $transcript->seq_region_start(),
					   end         => $transcript->seq_region_end(),
					   strand      => $transcript->seq_region_strand(),
					   seq_region_name => $transcript->seq_region_name()
  };
  for my $dbentry (@{$xa->fetch_all_by_Transcript($transcript)}) {
	push @{$transcript_out->{xrefs}}, $self->_hash_xref($dbentry);
  }
  my $translation = $transcript->translation();
  if (defined $translation) {
	push @{$transcript_out->{translations}},
	  $self->_hash_translation($xa, $translation);
	for my $alt_translation (
					 @{$transcript->get_all_alternative_translations()})
	{
	  push @{$transcript_out->{translations}},
		$self->_hash_translation($xa, $alt_translation);
	}
  }
  return $transcript_out;
} ## end sub _hash_transcript

sub _hash_translation {
  my ($self, $xa, $translation) = @_;
  my $translation_out = {id => $translation->stable_id()};
  for my $dbentry (@{$xa->fetch_all_by_Translation($translation)}) {
	push @{$translation_out->{xrefs}}, $self->_hash_xref($dbentry);
  }
  for my $protein_feature (@{$translation->get_all_ProteinFeatures()}) {
	push @{$translation_out->{protein_features}},
	  $self->_hash_protein_feature($protein_feature);
  }
  return $translation_out;
}

sub _hash_protein_feature {
  my ($self, $protein_feature) = @_;
  return {start       => $protein_feature->start(),
		  end         => $protein_feature->end(),
		  name        => $protein_feature->display_id(),
		  dbname      => $protein_feature->analysis()->db(),
		  description => $protein_feature->hdescription(),
		  interpro_ac => $protein_feature->interpro_ac()};
}

sub _hash_xref {
  my ($self, $xref) = @_;
  my $xref_out = {primary_id => $xref->primary_id(),
				  display_id => $xref->display_id(),
				  dbname     => $xref->dbname()};
  if (ref($xref) eq 'Bio::EnsEMBL::OntologyXref') {
	for my $linkage_type (@{$xref->get_all_linkage_info()}) {
	  push @{$xref_out->{linkage_types}},
		{evidence => $linkage_type->[0],
		 source   => $self->_hash_xref($linkage_type->[1])};
	}
  }
  return $xref_out;
}

1;
