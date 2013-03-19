use strict;
use warnings;

package Test::BDD::Cucumber::Ext::ScenarioAccessors;

our ($_c, $_accessors);
my $IMPORTED;

sub import {
	my ($class, @to_create) = @_;

	no strict   'refs';
	no warnings 'redefine';

	my $pkg = (caller)[0];

	foreach my $acc (@to_create) {
		die 'UNIMPLEMENTED' if ref $acc; # TODO cope with hash of subs described in synopsis!
		$_accessors->{$acc} = sub {
			my ($value) = @_;
			if ($value) {
				$_c->stash->{'scenario'}->{$acc} = $value;
			}
			return $_c->stash->{'scenario'}->{$acc};
		};

		# For compilation, we provide this empty sub, which agrees with the
		# prototype above
		*{ $pkg . '::' . $acc } = sub { };
	}

	# We needed to add the accessor above. But we don't need to redefine the
	# StepFile subs.
	return if $IMPORTED++;

	# We want to extend 4 step file methods: given when then step
	# We manually export our version of each of these to our calling package
	# Which wraps the originals
	# And 'simply' replace the provided sub with a wrapper sub
	# That wrapper sub captures the current step context
	# And puts our accessor functions into the package for the scope of the
	# call
	foreach my $method (qw/ Given When Then Step /) {
		# I prefer lowercase, so we actually have given and Given
		my $method_name = 'Test::BDD::Cucumber::StepFile::' . $method;
		my $orig = \&{ $method_name };
		*{ $method_name } = sub {
			my $sub = pop @_;
			# Call the original, method with our wrapped sub which takes the
			# first argument (the whole context) and then creates a local alias
			# for each accessor in the calling package. And then finally calls
			# the sub.
			$orig->(@_, sub {
					local $_c = shift;
					my @args = @_;

					foreach my $acc (keys %$_accessors) {
						*{ $pkg . '::' . $acc } = $_accessors->{$acc};
					}

					$sub->($_c, @args);

					undef *{ $pkg . '::' . $_ } foreach keys %$_accessors;
				});
		};
	}
}

1;
__END__

=head1 NAME

Test::BDD::Cucumber::ScenarioAccessors - define static accessors for your scenarios

=head1 SYNOPSIS

	use Test::BDD::Cucumber::ScenarioAccessors (
		qw/ foo bar /,
		{
			baz => sub { $::baz //= 0; $::baz++ } # NOT IMPLEMENTED YET
		}
	);

	given qr/.../ => sub {
		foo 'thing';
		baz; # 0
	};

	then qr/.../ => sub {
		say foo; # thing
		baz; # 1
	};

=head1 DESCRIPTION

This module exists simply to remove the C<<$c->stash->{'scenario'}->{'thing'}>>
boilerplate from given/when/then declarations.

=head1 WARNING

This module uses MUCH MAGIC. Please tread with care.

