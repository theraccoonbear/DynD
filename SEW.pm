package SEW;

use Moose;
use Data::Dumper;
use SEW::Request;
use SEW::Response;

has 'resp' => (
	is => 'rw',
	isa => 'SEW::Response',
	default => sub {
		return SEW::Response->instance(); #new();
		
	}
);

has 'req' => (
	is => 'rw',
	isa => 'SEW::Request',
	default => sub {
		return SEW::Request->instance();
	}
);




1;