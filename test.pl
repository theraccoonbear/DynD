#!/usr/bin/env perl

BEGIN {
	my $user = 'theracco';
	my $home_dir = `echo ~$user`;
	chomp $home_dir;
	my $perl_dir= $home_dir . '/perl/';
	my $base_module_dir = (-d $perl_dir ? $perl_dir : ( getpwuid($>) )[7] . '/perl/');
	unshift @INC, map { $base_module_dir . $_ } @INC;
}

use strict;
use warnings;
use Data::Dumper;
use lib '.';
require 'dynd.pm';


#
print "Content-Type: text/plain\n\n";

my $dynd = DynD->new();
#print Dumper($dynd->config);
$dynd->login();

$dynd->manageDomain({
	base => 'bhffc.com',
	subdomain => 'dyntest',
	new_ip => '184.60.25.225',
	old_ip => $dynd->currentIP('dyntest.bhffc.com')
});
