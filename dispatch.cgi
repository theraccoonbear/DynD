#!/usr/bin/perl

BEGIN {
	my $base_module_dir = (-d '/home2/theracco/perl' ? '/home2/theracco/perl' : ( getpwuid($>) )[7] . '/perl/');
	unshift @INC, map { $base_module_dir . $_ } @INC;
}

use strict;
use warnings;
use Data::Dumper;
use SEW::Controller;

my $controller = new SEW::Controller();

eval {
	$controller->dispatch();
};

if ($@) {
	$controller->error("Error", $@);
}

