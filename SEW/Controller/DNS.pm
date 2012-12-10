package SEW::Controller::DNS;

use strict;
use warnings;
use Moose;
use lib('../..');
use DynD;

extends 'SEW::Controller';

has 'exposed' => (
	is => 'ro',
	isa => 'ArrayRef',
	default => sub { return ['update']; }
);

has 'dns' => (
	is => 'rw',
	isa => 'DynD',
	default => sub { return DynD->new(); }
);


sub update {
	my $self = shift @_;
	my $params = shift @_;
	
	my $base = $params->{named}->{base} || $self->error("No base provided", {base=>undef});
	my $subd = $params->{named}->{subd} || $self->error("No subdomain provided", {subd=>undef});
	my $pass = $params->{named}->{pass} || $self->error("No password provided", {pass=>undef});
	my $new_ip = $params->{named}->{new_ip} || $self->error("No IP provided", {new_ip=>undef});
	
	if ($self->dns->validPass($base, $subd, $pass)) {
		$self->send("Hooray!");
	} else {
		$self->error('bad pass');
	}
	
	#$self->resp->send('Update', {p=>$params});
}


1;