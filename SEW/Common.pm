package SEW::Common;

use Moose::Role;
use lib('..');
use SEW::Request;
use SEW::Response;
use Data::Dumper;
use Cwd qw(abs_path cwd);

has 'resp' => (
	is => 'rw',
	isa => 'SEW::Response',
	default => sub {
		return SEW::Response->instance();
	}
);

has 'req' => (
	is => 'rw',
	isa => 'SEW::Request',
	default => sub {
		return SEW::Request->instance();
	}
);

has 'root_path' => (
	is => 'ro',
	isa => 'Str',
	default => sub {
		my $path = abs_path(__FILE__);
		$path =~ s/\/[^\/]+$/\//gi;
		return $path;
	}
);

sub error {
	my $self = shift @_;
	my $msg = shift @_;
	my $data = shift @_;
	
	$self->resp->sendError($msg, $data);
}

sub send {
	my $self = shift @_;
	my $msg = shift @_;
	my $data = shift @_;
	my $success = shift @_;
	
	$self->resp->send($msg, $data, $success);
}


sub dump {
	my $self = shift @_;
	my $dat = shift @_;
	print "Content-Type: text/plain\n\n";
	print "DUMP:\n";
	print Dumper($dat);
	exit;
}

1;