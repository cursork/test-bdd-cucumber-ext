#!perl

use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;
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
   my $method = { base64 => 'b64digest', 'hex' => 'hexdigest' }->{ $digest } ||
       do { fail("Unknown output type $digest"); return };
   is( object->$method, $output );
};

