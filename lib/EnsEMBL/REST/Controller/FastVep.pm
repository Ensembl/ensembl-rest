package EnsEMBL::REST::Controller::FastVep;
use Moose;
use Bio::EnsEMBL::Variation::VariationFeature;
use namespace::autoclean;
use Bio::EnsEMBL::Variation::Utils::VEP qw(get_all_consequences parse_line);
use Data::Dumper;
use Bio::EnsEMBL::Funcgen::MotifFeature;
use Bio::EnsEMBL::Funcgen::RegulatoryFeature;
use Bio::EnsEMBL::Funcgen::BindingMatrix;
use Bio::DB::Fasta;
use Modern::Perl;
require EnsEMBL::REST;
EnsEMBL::REST->turn_on_jsonp(__PACKAGE__);

BEGIN {
    extends 'Catalyst::Controller::REST';

    eval {
        package Bio::EnsEMBL::Slice;

        {

            # don't want a redefine warning spat out, thanks
            no warnings 'redefine';
            our $fasta_db = Bio::DB::Fasta->new(
                '/mnt/Homo_sapiens.GRCh37.69.dna.primary_assembly.fa');

            # overwrite seq method to read from FASTA DB
            sub seq {
                my $self = shift;

                my $seq = $fasta_db->seq( $self->seq_region_name, $self->start => $self->end );
                reverse_comp( \$seq ) if $self->strand < 0;

                # default to a string of Ns if we couldn't get sequence
                $seq ||= 'N' x $self->length();

                return $seq;
            }
        }

        1;
    };

    #         # spoof a coordinate system
    #         $config->{coord_system} = Bio::EnsEMBL::CoordSystem->new(
    #             -NAME => 'chromosome',
    #             -RANK => 1,
    #         );

}

use Try::Tiny;
__PACKAGE__->config( 'map' => { 'text/javascript' => ['JSONP'] } );

sub get_species : Chained("/") PathPart("fastvep") CaptureArgs(1) {
    my ( $self, $c, $species ) = @_;
    $c->stash->{species} = $species;

    $c->stash->{config} = {
        'whole_genome'           => 1,
        'cache_region_size'      => 1000000,
        'strip'                  => 1,
        'buffer_size'            => 5000,
        'compress'               => 'gzip -dc',
        'cache_polyphen_version' => '2.2.2',
        'plugins'                => [],
        'cache_sift'             => 'b',
        'tmpdir'                 => '/tmp',
        'custom'                 => [],
        'terms'                  => 'SO',
        'failed'                 => 0,
        'cache_cell_types' =>
'HeLa-S3,GM06990,U2OS,CD4,IMR90,HL-60,HepG2,Lymphoblastoid,CD133,CD36,K562,GM12878,HUVEC,NHEK,H1ESC,MultiCell,K562b,NH-A,HSMM,HMEC,A549,AG04449,AG04450,AG09309,AG09319,AG10803,Caco-2,Chorion,CMK,GM10847,GM12801,GM12864,GM12865,GM12872,GM12873,GM12874,GM12875,GM12891,GM12892,GM15510,GM18505,GM18507,GM18526,GM18951,GM19099,GM19193,GM19238,GM19239,GM19240,H7ESC,H9ESC,HAEpiC,HCF,HCM,HCPEpiC,HCT116,HEEpiC,HEK293b,HEK293,HepG2b,HGF,HIPEpiC,HNPCEpiC,HRCEpiC,HRE,HRPEpiC,Jurkat,LHSR,MCF7,Medullo,Melano,NB4,NHBE,NHDF-neo,NHLF,NT2-D1,Panc1,PanIslets,PFSK1,SAEC,SKMC,SKNMC,SKNSHRA,Th1,Th2,WERIRB1,RPTEC,ProgFib,HSMMtube,Osteobl,MCF10A-Er-Src,HPAEpiC,Fibrobl,GM12878-XiMat,BJ',
        'dir'                => '/dev/shm/homo_sapiens/69',
        'toplevel_dir'       => '/dev/shm',
        'offline'            => 1,
        'core_type'          => 'core',
        'cache_user'         => 'ensro',
        'plugin'             => [],
        'chunk_size'         => '50000',
        'cache_sift_version' => '4.0.5',
        'species'            => 'homo_sapiens',
        'cache_polyphen'     => 'b',
        'prefetch'           => 1,
        'cache_regulatory'   => '1',
        'fields'             => [
            'Uploaded_variation', 'Location',         'Allele',      'Gene',
            'Feature',            'Feature_type',     'Consequence', 'cDNA_position',
            'CDS_position',       'Protein_position', 'Amino_acids', 'Codons',
            'Existing_variation', 'Extra'
        ],
        'force_overwrite' => 1,
        'format'          => 'vcf',
        'no_slice_cache'  => 1,
        'cell_type'       => [],
        'cache'           => 1,
        'quiet'           => 0,
        'hgvs'            => 1,
        'sift'            => 'b',
        polyphen          => 'b',
        ccds              => 1,
        hgnc              => 1,
        numbers           => 1,
        domains           => 1,
        regulatory        => 1,
        cell_type         => [],
        canonical         => 1,
        protein           => 1,
        gmaf              => 1,
        fasta             => '/mnt/Homo_sapiens.GRCh37.69.dna.primary_assembly.fa'
    };

}

sub get_consequences : Chained('get_species') PathPart('consequences') Args(0) ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub get_consequences_POST {
    my ( $self, $c ) = @_;
    my $post_data = $c->req->data;

    #            $c->log->debug(Dumper $post_data);
    my $config = $c->stash->{config};
    my @vfs;
    foreach my $line (@$post_data) {
        chomp $line;
        next if $line =~ /^#/;

        $config->{line_number}++;

        # header line?
        if ( $line =~ /^\#/ ) {
            push @{ $config->{headers} }, $_;
            next;
        }

        # some lines (pileup) may actually parse out into more than one variant
        foreach my $vf ( @{ &parse_line( $config, $line ) } ) {
            $vf->{_line} = $line;    #if defined($config->{vcf}) || defined($config->{original});
            push @vfs, $vf;
        }
    }
    if ( !@vfs ) {
        $c->log->fatal(qq{no variant features found in post data});
        $c->go( 'ReturnError', 'no_content', [qq{no variant features found in post data}] );
    }
    try {

        my $consequences = get_all_consequences( $config, \@vfs );
        $c->stash->{consequences} = $consequences;
        $self->status_ok( $c, entity => { data => $c->stash->{consequences} } );

    }
    catch {
        $c->log->fatal(qw{Problem Getting Consequences});
        $c->log->fatal($_);
        $c->log->fatal(Dumper $post_data);
        $c->go( 'ReturnError', 'custom', [ qq{Problem entry within this batch: } . Dumper $post_data] );
    }
}

sub get_consequences_GET {
    my ( $self, $c ) = @_;

    my $s  = $c->stash();
    my $vf = try {
        Bio::EnsEMBL::Variation::VariationFeature->new_fast(
            {
                start         => $s->{start},
                end           => $s->{end},
                strand        => $s->{strand},
                allele_string => $s->{allele_string},
                variation_name => 'test',
                mapped_weight  => 1,
                chr            => 1
            }
        );
    }
    catch {
        $c->log->fatal(qq{problem making Bio::EnsEMBL::Variation::VariationFeature object});
        $c->go( 'ReturnError', 'from_ensembl', [$_] );
    };
    $s->{variation_features} = [$vf];
    $c->forward('calc_consequences');
    $self->status_ok( $c, entity => { data => $c->stash->{consequences} } );
}
1;
