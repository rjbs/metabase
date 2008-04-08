# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 't/lib';
use CPAN::Metabase::Fact::TestFact;

plan tests => 16;

require_ok( 'CPAN::Metabase::Fact' );

#--------------------------------------------------------------------------#
# fixtures
#--------------------------------------------------------------------------#    

my ($obj, $err);

#--------------------------------------------------------------------------#
# required parameters missing
#--------------------------------------------------------------------------#

eval { $obj = CPAN::Metabase::Fact->new() };
$err = $@;
like( $err, qr/Mandatory parameters/, "new() without params throws error" );
for my $p ( qw/ dist_author dist_file content / ) {
    like( $err, qr/$p/, "... '$p' noted missing" );
}

#--------------------------------------------------------------------------#
# fake an object and test methods
#--------------------------------------------------------------------------#

$obj = bless {}, 'CPAN::Metabase::Fact';

# schema version default
can_ok( $obj, 'schema_version' );
is( $obj->schema_version, 1, "schema_version() defaults to 1");

# type is class munged from "::" to "-"
can_ok( $obj, 'type' );
is( $obj->type, "CPAN-Metabase-Fact", "type() is ok" );

# unimplemented
for my $m ( qw/content_as_string content_from_string validate_content/ ) {
    throws_ok { $obj->$m } qr/$m\(\) not implemented by CPAN::Metabase::Fact/;
}

#--------------------------------------------------------------------------#
# new should take either hashref or list
#--------------------------------------------------------------------------#

my $args = {
    dist_author => "JOHNDOE",
    dist_file   => "Foo-Bar-1.23.tar.gz",
    content     => "Who am I?",
};

lives_ok{ $obj = CPAN::Metabase::Fact::TestFact->new( $args ) } 
    "new( <hashref> ) doesn't die";

is( ref $obj, 'CPAN::Metabase::Fact::TestFact', "object created with correct type" );

lives_ok{ $obj = CPAN::Metabase::Fact::TestFact->new( %$args ) } 
    "new( <list> ) doesn't die";

is( ref $obj, 'CPAN::Metabase::Fact::TestFact', "object created with correct type" );

