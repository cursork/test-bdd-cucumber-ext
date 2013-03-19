use strict;
use warnings;

package Test::BDD::Cucumber::Ext::ScenarioConstraints;

use Carp;
use Test::More ();

my $IMPORTED;

sub import {
	no strict   'refs';
	no warnings 'redefine';

	return if $IMPORTED++;

	foreach my $method_name (map { "Test::BDD::Cucumber::StepFile::$_" } qw/ Given When Then /) {
		my $orig = \&{ $method_name };
		*{ $method_name } = sub {
			my ($regex, $sub) = (shift(@_), pop(@_));

			# Hold on to any other arguments, and default to just using the
			# same sub.
			my @args = @_;
			my $new_sub = $sub;

			if (@_ && scalar @_ % 2 == 0) {
				my %arguments = @_;
				if (my $constraints = delete $arguments{'constraints'}) {
					if (! grep { ref $constraints eq $_ } qw/ARRAY HASH/) {
						croak 'Constraints must be array or hash reference';
					}

					# Remove the constraints from the arguments and create our
					# wrapper sub
					@args = %arguments;

					$new_sub = sub {
						my ($c) = @_;
						if (ref $constraints eq 'ARRAY') {
							foreach my $k (@$constraints) {
								if (!$c->stash->{'scenario'}->{$k}) {
									Test::More::fail("Constraint on $k unsatisfied");
									return;
								}
							}
						} elsif (ref $constraints eq 'HASH') {
							foreach my $k (keys %$constraints) {
								my $desired = $constraints->{$k};
								if (ref $desired eq 'CODE') {
 									if (!$desired->($c->stash->{'scenario'}->{$k})) {
										Test::More::fail("Constraint on $k unsatisfied.");
										return;
									}
								} elsif ($c->stash->{'scenario'}->{$k} ne $desired) {
									Test::More::fail("Constraint on $k unsatisfied. Expected " . $constraints->{$k});
									return;
								}
							}
						}

						$sub->(@_);
					};
				}
			}

			# Note we pass args through again, as we might be wrapping another
			# wrapper
			$orig->($regex, @args, $new_sub);
		};
	}
}

1;

__END__

=head1 NAME

Test::BDD::Cucumber::Ext::ScenarioConstraints - constraints for your given/when/thens

=head1 SYNOPSIS

	use Test::BDD::Cucumber::Ext::ScenarioConstraints;

	Given qr/I have submitted the registration form/ => sub {
		shift->stash->{'scenario'}->{'on_post_registration'} = 1;
	};

	# Check stashed value is true-ish:

	When qr/I have agreed to the junk mail option/,
		constraints => [qw/ on_post_registration /], sub {
			my ($c) = @_;
			...
		};

	# ...or check for specific values:

	When qr/I have agreed to the junk mail option/,
		constraints => { on_post_registration => 1 }, sub {
			my ($c) = @_;
			...
		};

=head1 DESCRIPTION

This module allows you to apply constraints on scenario steps, using the
scenario stash.

That is, in the above, agreeing to junk mail can not happen unless you have
just submitted the registration form.

This is a replacement for this boilerplate:

	When qr/I have agreed to the junk mail option/ => sub {
		my ($c) = @_;
		if (!$c->stash->{'scenario'}->{'on_post_registration'}) {
			fail('Constraint on on_post_registration');
			return;
		}
		...
	};
