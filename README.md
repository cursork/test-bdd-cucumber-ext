# Test::BDD::Cucumber::Ext

Convenience packages for use in Test::BDD::Cucumber files. The aim is to remove
boilerplate and/or make Cucumber step definition files more aesthetically
appealing.

Simply use them at the top of your step definition .pl file, and they will take
effect.

The combination of all of them allows the Digest example to be adapted to the
below. Whether or not this appeals to you more is probably a matter of personal
taste.

    use Test::More;
    use Test::BDD::Cucumber::Ext::StepFile;
    use Test::BDD::Cucumber::Ext::ScenarioAccessors qw/ object /;
    use Test::BDD::Cucumber::Ext::LowercaseDefinitions;
    use Test::BDD::Cucumber::Ext::MatchesAsArguments;
    use Method::Signatures;

    given qr/a usable "(\S+)" class/, func ($c, $class) { use_ok( $class ); };
    given qr/a Digest (\S+) object/, func ($c, $type) {
       ok object(Digest->new($type)), "Object created";
    };

    when qr/I've added "(.+)" to the object/, func ($c, $data) {
       object->add( $data );
    };

    when "I've added the following to the object", func ($c) {
       object->add( $c->data );
    };

    then qr/the (.+) output is "(.+)"/, func ($c, $digest, $output) {
       my $method = {base64 => 'b64digest', 'hex' => 'hexdigest' }->{ $digest } ||
           do { fail("Unknown output type $digest"); return };
       is( object->$method, $output );
    };

## Test::BDD::Cucumber::Ext::LowercaseDefinitions

Simply wraps `Given`, `When` and `Then` with their all-lowercase equivalents.

## Test::BDD::Cucumber::Ext::MatchesAsArguments

Intended for use with `Method::Signatures` to remove the need to refer to the
regular expression matches through `$1`, `$2`, etc. For example:

    Given qr/an object of type  '(.+)'/ => func($c, $type) {
        my $class = "Foo::$type";
        $c->stash->{'scenario'}->{'my_object'} = $class->new;
    }

... instead of:

    Given qr/an object of type  '(.+)'/ => sub {
        my ($c) = @_;
        my $type = $1;
        my $class = "Foo::$type";
        $c->stash->{'scenario'}->{'my_object'} = $class->new;
    }

## Test::BDD::Cucumber::Ext::ScenarioAccessors

Given that one almost always wants to stash a 'something' value inside
`$c->stash->{'scenario'}->{'something'}`, this module introduces a static
accessor for the task.

    use Test::BDD::Cucumber::Ext::ScenarioAccessors qw/something/;

    Given qr/I've got a new thing/ => sub {
        something( MyThing->new );
    };

    When qr/I do something to the thing/ => sub {
        something->do_it();
    };
