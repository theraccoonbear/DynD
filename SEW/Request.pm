package SEW::Request;

use MooseX::Singleton;
with 'SEW::Common';
with 'SEW::Core';

use Data::Dumper;
use JSON::XS;

has 'controller_name' => (
	is => 'rw',
	isa => 'Str',
	default => 'Default'
);

has 'action' => (
	is => 'rw',
	isa => 'Str',
	default => 'index'
);

has 'parameters' => (
	is => 'rw',
	isa =>'HashRef',
	default => sub {
		return {named=>{},numerical=>[],posted=>{}};
	}
);

sub BUILD {
	my $self = shift;
	
	$self->parameters($self->_loadParameters());
	$self->controller_name($self->_findController());
}

sub _loadParameters {
	my $self = shift @_;
	
	my $post_str = $self->q->param('request') || '{}';
	my $posted = decode_json($post_str);
	my $params = {
		'named' => {},
		'numerical' => [],
		'posted' => $posted
	};
	
  my @path_parts = split(/\//, $self->q->url_param('path') || '');
	
  my $p_cnt = scalar @path_parts;
  
  if ($p_cnt == 0) {
		$self->error("You're giving me nothin' here: " . join('/', @path_parts));
  }
	
#	if ($p_cnt >= 1) {
#		$self->model($self->utoc($path_parts[0]));
#  }
#  
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
	
	return $params;
}

sub _findController {
	my $self = shift @_;
	
	my $ctl = 'Default';
	
	my @path_parts = split(/\//, $self->q->url_param('path') || '');
	
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

1;