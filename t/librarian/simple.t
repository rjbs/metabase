# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

use strict;
use warnings;

use Test::More;

use Test::Exception;
use File::Temp ();
use File::Path ();

use lib 't/lib';
use Test::Metabase::Util;
my $TEST = Test::Metabase::Util->new;

plan tests => 10;

#-------------------------------------------------------------------------#

require_ok( 'Metabase::Librarian' );

ok( my $librarian = $TEST->test_librarian, 'created librarian' );

ok( my $fact = $TEST->test_fact, "created a fact" );
isa_ok( $fact, 'Test::Metabase::StringFact' );

ok(
  my $guid = $librarian->store($fact),
  "stored a fact"
);

my $matches = $librarian->search( 'resource.cpan_id' => 'JOHNDOE' );
ok( scalar @$matches >= 1, "found guid searching for resource cpan_id" );

$matches = $librarian->search( 'core.guid' => $guid );
is( scalar @$matches, 1, "found guid searching for guid" );

ok(
  my $new_fact = $librarian->extract( $matches->[0] ),
  "extracted object from guid from search"
);

is( $new_fact->content, $fact->content, "fact content matches" );

is( $new_fact->resource, $fact->resource, "dist name was indexed as expected" );
