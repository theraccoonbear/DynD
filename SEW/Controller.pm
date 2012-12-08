package SEW::Controller;

use Moose;
extends 'SEW';
with 'SEW::Common';
with 'SEW::Core';

use JSON::XS;

has 'exposed' => (
	is => 'ro',
	isa => 'ArrayRef',
	default => sub { return []; }
);

sub getController {
	my $self = shift @_;
	my $controller = shift @_;
	
	if ($controller =~ m/[^A-Za-z_]/gi) {
		$self->error("Invalid controller name: $controller");
	}
	
	
	my $tfp = __FILE__;
	
	$tfp =~ s/\/[^\/]+$//gi;
	
	my $fq_class_name = "SEW::Controller::$controller";
	my $controller_path = "$tfp/Controller/$controller.pm";
	
	my $ci = {};
	
	
	if (-f $controller_path) {
		require $controller_path;
		$ci = new $fq_class_name();
		
		if (!$ci->isa($fq_class_name)) {
			$self->error("Unable to instantiate: $fq_class_name");
		}
		
		$ci->req($self->req);
	} else {
		$self->error("Could not find controller: $controller");
	}
	
	return $ci;
}

sub init {
	my $self = shift @_;
	
	my $post_str = $self->q->param('request') || '{"provider":{"name":"providername","host":{"pass":"p4s5w0rD","user":"guest","name":"medac-provider.hostname.com","path":"/path/to/video/","port":22}},"account":{"username":"localuser","password":"localpass","host":{"name":"medac-provider.hostname.com","port":80}},"resource":{"md5":"b00d64cd31665414f6b5ebd47c2d0fba","path":"TV/Band of Brothers/Season 1/01 - Curahee.avi"}}';
	
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
#		#$self->controller($self->utoc($path_parts[0]));
#  }
  
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
  
  
  push @INC, $self->root_path;
  
  my $pl = {
		'controller' => $self->req->controller_name,
		'action' => $self->req->action,
		'params' => $params
	};
  
	#$self->req($pl);
} # init()

sub exposedAction {
	my $self = shift @_;
	my $action = shift @_;
	
	foreach my $act (@{$self->exposed}) {
		if ($act eq $action) {
			return 1;
		}
	}
	
	return 0;
}

sub action {
  my $self = shift @_;
  my $action = shift @_;
  my $params = shift @_;
  
	$action =~ s/-/_/gi;
	
	
	if ($action =~ m/[^A-Za-z_]/gi) {
		$self->error("Invalid action: $action");
	}
	
	if ($self->can($action)) {
		if ($self->exposedAction($action)) {
			$self->init();
			$self->$action(@{$params->{numerical}});
		} else {
			$self->error("Unexposed action: $action");
		}
  } else {
    $self->error("Unimplemented action: $action");
  }
}
	

sub dispatch {
  my $self = shift @_;	
	my $controller = $self->getController($self->req->controller_name());
  
  $controller->action($self->req->action(), $self->req->{params});
} # dispatch()


1;