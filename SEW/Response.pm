package SEW::Response;

use MooseX::Singleton;
#with 'SEW::Common';
with 'SEW::Core';

use Data::Dumper;
use JSON::XS;

has 'headers' => (
	is => 'rw',
	isa => 'HashRef',
	default => sub {
		return {
			'content-type' => 'text/plain'	
		}
	}
);

sub setHeader {
	my $self = shift @_;
	my $name = lc(shift @_);
	my $val = shift @_;
	
	$self->headers->{$name} = $val;
}

sub rmHeader {
	my $self = shift @_;
	my $name = lc(shift @_);
	my $val = shift @_;
	
	delete $self->headers->{$name};
}

sub clearHeaders {
	my $self = shift @_;
	$self->headers({'content-type'=>'text/plain'});
}

sub outputHeaders {
	my $self = shift @_;
	
	if (! defined $self->headers->{'content-type'}) {
		$self->headers->{'content-type'} = 'text/plain';
	}
	
	#print "HTTP/1.1 200 OK\n";
	
	foreach my $h_key (keys %{$self->headers}) {
		print "$h_key: " . $self->headers->{$h_key} . "\n";
	}
	print "\n";
	
}

sub send { 
	my $self = shift @_;
	my $message = shift @_;
	my $payload = shift @_;
	my $success = shift @_;
	
	$success = $success || ! defined $success ? JSON::XS::true : JSON::XS::false;
	
	$self->outputHeaders();
	
	print encode_json({success=>$success,message=>$message,payload=>$payload});
	exit;
}

sub sendError {
	my $self = shift @_;
	my $error = shift @_;
	my $data = shift @_;
	
	$self->send($error, $data, JSON::XS::false);
}

1;