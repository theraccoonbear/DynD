package DynD;

BEGIN {
	my $base_module_dir = (-d '/home2/theracco/perl' ? '/home2/theracco/perl' : ( getpwuid($>) )[7] . '/perl/');
	unshift @INC, map { $base_module_dir . $_ } @INC;
}

use Moose;

use strict;
use warnings;
use Web::Scraper;
use HTTP::Cookies;
use HTML::Entities;
use Data::Dumper;
use WWW::Mechanize;
use JSON::XS;
use Socket;
use File::Slurp;
use Digest::SHA1 qw(sha1_hex);
use Cwd qw(abs_path);
use File::Basename;

has 'config_file' => (
	is => 'rw',
	isa => 'Str',
	default => sub {
		
		return dirname(abs_path(__FILE__)) . '/config.json';
	}
);

has 'config' => (
	is => 'rw',
	isa => 'HashRef',
	builder => '_loadConfig'
);

has 'dns' => (
	is => 'rw',
	isa => 'ArrayRef',
	default => sub {
		my $json = read_file('managed.json');
		return decode_json($json);
		
	}
);

has 'logged_in' => (
	is => 'rw',
	isa => 'Bool',
	default => 0
);

has 'ua_string' => (
	is => 'rw',
	isa => 'Str',
	default => 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/525.13 (KHTML, like Gecko) Chrome/0.A.B.C Safari/525.13'
);

has 'cookie_jar' => (
	is => 'rw',
	isa => 'HTTP::Cookies',
	default => sub {
		return HTTP::Cookies->new();
	}
);

has 'mech' => (
	is => 'rw',
	isa => 'WWW::Mechanize',
	default => sub {
		return WWW::Mechanize->new();
	}
);

has 'salt' => (
	is => 'rw',
	isa => 'Str',
	default => 'DynD-SALT-29103801wmdio12'
);

has 'event_log' => (
	is => 'rw',
	isa => 'ArrayRef',
	default => sub {
		return [];
	}
);

sub _loadConfig {
	my $self = shift @_;
	
	if (-e $self->config_file) {
		my $json = read_file($self->config_file);
		return decode_json($json);
	} else {
		$self->logMsg("Couldn't find config file: " . $self->config_file);
		return {};
	}
}

sub saveDNS {
	my $self = shift @_;
	write_file('managed.json', encode_json($self->dns));
}

sub setAccount {
	my $self = shift @_;
	my $base = shift @_;
	my $subd = shift @_;
	my $pass = shift @_;
	
	my $domain = $self->getDomain($base);
	print Dumper($domain);
	my $found = undef;
	foreach my $sd (@{$domain}) {
		if ($sd->{subdomain} eq $subd) {
			$sd->{pass} = $self->hashPass($pass);
			$found = 1;
		}
	}
	
	if (!$found) {
		push @{$domain}, {'subdomain'=>$subd,'pass'=>$pass};
	}
}

sub updateRecord {
	my $self = shift @_;
	my $base_domain = shift @_;
	my $subdomain = shift @_;
	my $cur_ip = shift @_;
	my $new_ip = shift @_;
	
	if (! $self->logged_in) {
		my $suc = $self->login();
		if (!$suc) { return undef; }
	}
	
	return $self->manageDomain({
		base => $base_domain,
		subdomain => $subdomain,
		new_ip => $new_ip,
		old_ip => $cur_ip
	});	
}

sub hashPass {
	my $self = shift @_;
	my $pass = shift @_;
	return sha1_hex($pass . $self->salt);
}

sub getBaseDomain {
	my $self = shift @_;
	
	my $sd = shift @_;
	
	if ($sd =~ m/\.([^\.]+\..+?)$/gi) {
		return $1;
	}
	
	return 'google.com';
}

sub getSubPortion {
	my $self = shift @_;
	
	my $sd = shift @_;
	
	if ($sd =~ m/^(.+?)\.([^\.]+\..+?)$/gi) {
		return $1;
	}
	
	return 'undefined';
}

sub login {
	my $self = shift @_;
	my $login_url = 'https://my.hostmonster.com/cgi-bin/cplogin';	

	$self->logMsg("Logging in...");
	$self->mech->get($login_url);
	$self->mech->submit_form(
		form_number => 1,
		fields      => {
			'ldomain' => $self->config->{username},
			'lpass' => $self->config->{password},
		},
	);
	if (!$self->mech->success) {
		return $self->logFatal("Load error", 'error');
	}
	
	$self->mech->submit_form(form_number => 1);
	
	$self->logMsg("OK; logged in.");
	$self->logged_in(1);
} 

sub openDomainManager {
	my $self = shift @_;
	my $opts = shift @_;
	
	$self->logMsg("Opening domain manager...");
	$self->mech->get('https://host414.hostmonster.com:2083/frontend/dm.cgi?step=dm');
	if (!$self->mech->success) {
		return $self->logFatal("Load error");
	}
	$self->logMsg("OK. Loading account...");
	
	$self->mech->get('https://my.hostmonster.com/cgi/account/dm?ldomain=theracco');
	if (!$self->mech->success) {
		return $self->logFatal("Load error");
	}
	$self->logMsg("OK. Retrieving current DNS config...");
	
	my $state_url = 'https://my.hostmonster.com/cgi/dm/zoneedit/ajax';
	
	my $req = {
		op => 'getzonerecords',
		domain => $opts->{base}
	};
	
	$self->mech->post($state_url, $req);
	
	if (!$self->mech->success) {
		return $self->logFatal("Load error");
	}
	
	my $json = $self->mech->{content};
	my $obj = decode_json($json);

	my $dns_rec = undef;
	foreach my $dns_entry (@{$obj->{data}}) {
		if (lc($dns_entry->{name}) eq $opts->{subdomain}) {
			$dns_rec = $dns_entry;
			last;
		}
	}
	
	if (! defined $dns_rec) {
		return $self->logFatal("Couldn't find record");
	}
	
	return $dns_rec;
}

sub manageDomain {
	my $self = shift @_;
	my $opts = shift @_;

	my $dmgr = 'https://my.hostmonster.com/cgi/dm/zoneedit?domain=' . $opts->{base};

	my $current = $self->openDomainManager($opts);
	
	$self->logMsg("Updating DNS records...");
	$self->mech->get($dmgr);
	if (!$self->mech->success) {
		$self->logFatal("Load error", {dmgr=>$dmgr});
		return undef;
	}
	
	my $content = $self->mech->{content};
	
	$self->logMsg("Locating subdomain...");
	
	my $api_url = 'https://my.hostmonster.com/cgi/dm/zoneedit/ajax';
	
	my $req = {
		op => 'editzonerecord',
		domain => $opts->{base},
		name => $opts->{subdomain},
		orig__name => $opts->{subdomain},
		address => $opts->{new_ip},
		orig__address => $opts->{old_ip},
		ttl => 14400,
		orig__ttl => 14400,
		Line => $current->{Line},
		type => 'A'
	};
	
	$self->mech->post($api_url, $req);
	if (!$self->mech->success) {
		return $self->logFatal("Load error", {api_url=>$api_url,req=>$req});
	}
	
	my $json = $self->mech->{content};
	my $obj = decode_json($json);
	
	if ($obj->{result} == 1) {
		$self->logMsg("Records updated, $opts->{subdomain}.$opts->{base} now points at $opts->{new_ip}");
	} else {
		$self->logFatal('Something went wrong', {obj=>$obj});
	}
}

sub getDomain {
	my $self = shift @_;
	my $domain = shift @_;
	
	for my $dns_sec (@{$self->dns}) {
		my $base = $dns_sec->{base};
		if ($base eq $domain) {
			return $dns_sec->{subs};
		}
	}
	
	return [];
}

sub currentIP {
	my $self = shift @_;
	my $subdomain = shift @_;
	my @CUR_IP = gethostbyname($subdomain);
	my $cur_ip = join('.', map { inet_ntoa($_) } @CUR_IP[4 .. $#CUR_IP]);
	return $cur_ip;
}

sub validPass {
	my $self = shift @_;
	my $domain = shift @_;
	my $subd = shift @_;
	my $hashed_pass = sha1_hex((shift @_) . $self->salt);
	
	my $drec = $self->getDomain($domain);
	
	if (scalar @{$drec} < 1) { return undef; };
	my $record = undef;
	
	for my $subrec (@{$drec}) {
		if ($subrec->{subdomain} eq $subd) {
			$record = $subrec;
			last;
		}
	}
	
	if (! defined $record) { return undef; }
	return $hashed_pass eq $record->{pass};
}

sub logFatal {
	my $self = shift @_;
	my $msg = shift @_;
	my $meta = shift @_;
	
	push @{$self->event_log}, {message=>$msg,meta=>$meta,type=>'fatal'};
	
	return undef;
}

sub logWarning {
	my $self = shift @_;
	my $msg = shift @_;
	my $meta = shift @_;
	
	push @{$self->event_log}, {message=>$msg,meta=>$meta,type=>'warning'};
}

sub logMsg {
	my $self = shift @_;
	my $msg = shift @_;
	my $meta = shift @_;
	
	push @{$self->event_log}, {message=>$msg,meta=>$meta,type=>'status'};
}

sub anyFatals {
	my $self = shift @_;
	foreach my $event (@{$self->event_log}) {
		if ($event->{type} eq 'fatal') {
			return 1;
		}
	}
	
	return 0;
}


1;