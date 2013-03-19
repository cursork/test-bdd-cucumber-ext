use strict;
use warnings;

package Test::BDD::Cucumber::Ext::MatchesAsArguments;

our $IMPORTED = 0;

sub import {
	my ($class) = @_;

	return if $IMPORTED++;

	no strict   'refs';
	no warnings 'redefine';

	foreach my $method (qw/Given When Then Step/) {
		my $method_name = "Test::BDD::Cucumber::StepFile::$method";
		my $orig = \&{$method_name};
		*{$method_name} = sub {
			# Ensure we can wrap other wrappers by preserving the arguments
			my $sub = pop @_;
			$orig->(@_, sub {
					my ($c) = @_;

					# TODO - this is rather quick and nasty
					my @args;
					for (1..9) {
						if (my $match = eval "\$$_") {
							push @args, $match;
						} else {
							last;
						}
					}
					return $sub->($c, @args);
				});
		};
	}
}

1;
