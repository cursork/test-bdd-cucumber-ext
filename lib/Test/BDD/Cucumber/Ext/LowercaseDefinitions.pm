use strict;
use warnings;

package Test::BDD::Cucumber::Ext::LowercaseDefinitions;

our $IMPORTED = 0;

sub import {
	my ($class) = @_;

	return if $IMPORTED++;

	no strict 'refs';
	no warnings 'redefine';

	foreach my $method (qw/given when then step/) {
		*{ "Test::BDD::Cucumber::StepFile::$method"} = sub {
			return &{'Test::BDD::Cucumber::StepFile::' . ucfirst($method)}(@_);
		};
	}
}

1;

