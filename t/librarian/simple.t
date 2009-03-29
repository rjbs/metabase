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

plan tests => 10;

#-------------------------------------------------------------------------#

require_ok( 'CPAN::Metabase::Librarian' );

ok( my $librarian = Test::Metabase::Util->test_librarian, 'created librarian' );

ok( my $fact = Test::Metabase::Util->test_fact, "created a fact" );
isa_ok( $fact, 'CPAN::Metabase::Fact::TestFact' );

ok(
  my $guid = $librarian->store($fact, { user_id => 'Larry' }),
  "stored a fact"
);

my $matches;
TODO: {
  local $TODO = 'resource analysis not implemented';
  $matches = $librarian->search( 'resource.author' => 'JOHNDOE' );
  ok( scalar @$matches >= 1, "found guid searching for fact dist_author" );
}

$matches = $librarian->search( 'core.guid' => $guid );
is( scalar @$matches, 1, "found guid searching for guid" );

ok(
  my $new_fact = $librarian->extract( $matches->[0] ),
  "extracted object from guid from search"
);

is( $new_fact->content, $fact->content, "fact content matches" );

is( $new_fact->resource, $fact->resource, "dist name was indexed as expected" );
