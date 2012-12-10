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

sub setup {
	my $self = shift @_;
	
}

sub test {
	my $self = shift @_;
	my $params = shift @_;
	$self->error("Test!", {params => $params});
}

sub index {
	my $self = shift @_;
	
	$self->error("Hey!");
}


1;