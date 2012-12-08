package SEW::Controller::Default;

use strict;
use warnings;
use Moose;

extends 'SEW::Controller';

has 'exposed' => (
	is => 'ro',
	isa => 'ArrayRef',
	default => sub { return ['index','test']; }
);

sub test {
	my $self = shift @_;
	$self->error("Test!", {});
}

sub index {
	my $self = shift @_;
	
	$self->error("Hey!");
}


1;