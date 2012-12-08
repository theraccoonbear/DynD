#!/usr/bin/perl

BEGIN {
	my $base_module_dir = (-d '/home2/theracco/perl' ? '/home2/theracco/perl' : ( getpwuid($>) )[7] . '/perl/');
	unshift @INC, map { $base_module_dir . $_ } @INC;
}


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
use DynD;
use CGI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser); 

my $cgi = CGI->new();
my $dns = new DynD();

my $base = $cgi->param('base');
my $subd = $cgi->param('subdomain');
my $pass = $cgi->param('pass');
my $ip = $cgi->param('ip');

$dns->setAccount('bhffc.com','george','123');
$dns->saveDNS();

if ($dns->validPass($base, $subd, $pass)) {
	
} else {
	
}