package SEW::Request;

use MooseX::Singleton;
with 'SEW::Core';

use SEW::Response;

use Data::Dumper;
use JSON::XS;
use CGI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

has 'q' => (
	is => 'rw',
	isa => 'CGI',
	default => sub {
		return CGI->new();
	}
);

has 'controller_name' => (
	is => 'rw',
	isa => 'Str',
	default => 'Default'
);

has 'action' => (
	is => 'rw',
	isa => 'Str',
	default => 'test'
);

has 'parameters' => (
	is => 'rw',
	isa =>'HashRef',
	builder => '_loadParameters'
	#default => sub {
	#	return {named=>{},numerical=>[],posted=>{}};
	#}
);

has 'resp' => (
	is => 'rw',
	isa => 'SEW::Response',
	default => sub {
		return SEW::Response->instance();
	}
);


sub BUILD {
	my $self = shift;
	$self->dump("HERE!?");
	$self->parameters($self->_loadParameters());
	$self->controller_name($self->_findController());
}

sub _loadParameters {
	my $self = shift @_;
	
	if (! defined $self->q) {
		$self->q(CGI->new());
	}
	
	my $post_str = $self->q->param('request') || '{}';
	my $posted = decode_json($post_str);
	my $params = {
		'named' => {},
		'numerical' => [],
		'posted' => $posted
	};
	
	my $path = substr($ENV{REQUEST_URI}, 1);
	my $req_path = length($path) > 0 ? $path : 'Default/test';
	my @path_parts = split(/\//, $req_path);

	
	#my $path = $self->q->url_param('path') || '';
	#my $req_path = length($path) > 0 ? $path : 'Default/test';
	#my @path_parts = split(/\//, $req_path);
	#my @path_parts = split(/\//, $self->q->url_param('path') || '');
	      
	my $p_cnt = scalar @path_parts;
	
	if ($p_cnt == 0) {
		$self->error("You're giving me nothin' here: " . join('/', @path_parts));
	}
	      
	if ($path_parts[0] =~ m/[^A-Za-z_]/gi) {
		$path_parts[0] = 'Default';
		#$self->error("Invalid controller name: \"$path_parts[0]\"");
	}
				
	if ($p_cnt >= 1) {
		$self->controller_name($self->utoc($path_parts[0]));
	}
	  
	if ($p_cnt >= 2) {
		      $self->action($path_parts[1]);
		      my @prms = @path_parts[2 .. scalar @path_parts - 1];
		      
		      
		      foreach my $p (@prms) {
			      my $pn = '';
			      my $pv = $p;
			      if ($p =~ m/^([a-zA-Z_-]+):(.+?)$/) {
				      $pn = $1;
				      $pv = $2;
				      $params->{named}->{$pn} = $pv;
			      }
			      
			      push @{$params->{numerical}}, $pv;
		      }
	}
	$self->dump($params);
	
	return $params;
	
}

sub _findController {
	my $self = shift @_;
	
	my $ctl = 'Default';
	
	$self->dump(%ENV);
	
	my $path = substr($ENV{REQUEST_URI}, 1); #$self->q->param('path');                                                                                                                                                                  
	my $req_path = length($path) > 0 ? $path : 'Default/test';
	my @path_parts = split(/\//, $req_path);

	#my @path_parts = split(/\//, $self->q->url_param('path') || '');
	
	if (scalar @path_parts >= 1) {
		if ($path_parts[0] =~ m/^[A-Za-z][A-Za-z0-9_]*$/gi) {
			$ctl = $path_parts[0];
		}
	}
	
	return $ctl;
}

sub getParam {
	my $self = shift @_;
	my $key = shift @_;
}

sub error {
	my $self = shift @_;
	my $msg = shift @_;
	my $data = shift @_;
	
	$self->resp->sendError($msg, $data);
}

1;