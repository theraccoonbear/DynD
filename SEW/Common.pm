package SEW::Common;

use Moose::Role;
use SEW::Response;
use Cwd qw(abs_path cwd);

has 'respObj' => (
	is => 'rw',
	isa => 'SEW::Response',
	default => sub {
		return SEW::Response->instance();
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
	
	$self->respObj->sendError($msg, $data);
}

1;