#!/usr/bin/perl

BEGIN {
    my $b__dir = (-d '/home2/theracco/perl'?'/home2/theracco/perl':( getpwuid($>) )[7].'/perl');
    unshift @INC,$b__dir.'5/lib/perl5',$b__dir.'5/lib/perl5/x86_64-linux-thread-multi',map { $b__dir . $_ } @INC;
}

use strict;
use warnings;
use Data::Dumper;
use SEW::Controller;
#use CGI qw(-no_debug :standard);

#print "Content-Type: text/plain\n\n"; print Dumper(%ENV);exit;

my $controller = new SEW::Controller();

eval {
	$controller->dispatch();
};

if ($@) {
	$controller->error("Error", $@);
}

