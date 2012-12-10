package SEW::Core;

use Moose::Role;

use Data::Dumper;


has 'context' => (
	is => 'rw',
	isa => 'Str',
	default => sub {
		return exists $ENV{'GATEWAY_INTERFACE'} ? 'www' : 'tty';
	}
);




sub underscoreToCamelCase {
	my $self = shift @_;
	my $name = shift @_;
	
	$name =~ s/_([a-z])/\U$1/gi;
	
	return ucfirst($name);
}

sub utoc {
	my $self = shift @_;
	my $name = shift @_;
	return $self->underscoreToCamelCase($name);
}

1