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
	default => sub { return ['update','getPublicIP']; }
);

has 'dns' => (
	is => 'rw',
	isa => 'DynD',
	default => sub { return DynD->new(); }
);

sub getPublicIP {
	my $self = shift @_;
	my $ip = $ENV{REMOTE_ADDR};
	
	$self->send("Your public IP is: $ip", {ip=>$ip});
}


sub update {
	my $self = shift @_;
	my $params = shift @_;
	
	my $base = $params->{named}->{base} || $self->error("No base provided", {base=>undef});
	my $subd = $params->{named}->{subd} || $self->error("No subdomain provided", {subd=>undef});
	my $pass = $params->{named}->{pass} || $self->error("No password provided", {pass=>undef});
	my $new_ip = $params->{named}->{new_ip} || $self->error("No IP provided", {new_ip=>undef});
	
	if ($self->dns->validPass($base, $subd, $pass)) {
		my $cur_ip = $self->dns->currentIP($subd . '.' . $base);
		my $changes = {old_ip=>$cur_ip,new_ip=>$new_ip,domain=>$subd . '.' . $base};
		if ($cur_ip ne $new_ip) {
			$self->dns->updateRecord($base, $subd, $cur_ip, $new_ip);
			if ($self->dns->anyFatals) {
				$self->error("Update failed", $self->dns->event_log);
			} else {
				$self->send("Success!", $changes);
			}
		} else {
			$self->send("IP is already up to date", $changes);
		}
	} else {
		$self->error('Invalid password');
	}
}


1;