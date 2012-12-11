package SEW::Controller::Default;

use strict;
use warnings;
use Moose;
use CGI;

extends 'SEW::Controller';

has 'exposed' => (
	is => 'ro',
	isa => 'ArrayRef',
	default => sub { return ['test','debug']; }
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

sub debug {
	my $self = shift @_;
	
	my $cgi = CGI->new();
	
	my $params = $cgi->Vars();
	$self->error("Debug", $params->{path});
	
}

1;