#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use SEW::Controller;


my $controller = new SEW::Controller();

$controller->dump('test');

eval {
	$controller->dispatch();
};

if ($@) {
	$controller->error("Error", $@);
}

