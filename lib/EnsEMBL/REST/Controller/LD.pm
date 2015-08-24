








package EnsEMBL::REST::Controller::LD;
use Moose;
use namespace::autoclean;


require EnsEMBL::REST;

EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);
BEGIN {
  extends 'Catalyst::Controller::REST';
	
}

# /ld/:species

# /ld/:species/population_ids

# /ld/:species/id/:id/:d_prime/:r_square/:population_ids

# /ld/:species/region/:region/:d_prime/:r_square/:population_ids




