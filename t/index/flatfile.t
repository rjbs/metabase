# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

use strict;
use warnings;

use Test::More 0.92;
use Test::Moose;

use Test::Exception;
use File::Temp ();
use File::Path ();

use lib 't/lib';
use Test::Metabase::StringFact;
use Test::Metabase::Util;
my $TEST = Test::Metabase::Util->new;

#-------------------------------------------------------------------------#
# Setup
#--------------------------------------------------------------------------#

my $fact = Test::Metabase::StringFact->new(
  resource => 'cpan:///distfile/JOHNDOE/Foo-Bar-1.23.tar.gz',
  content  => "Hello World",
);

my $string = "Everything is fine"; # we need length later

my $fact2 = Test::Metabase::StringFact->new(
  resource => 'cpan:///distfile/JOHNDOE/Foo-Bar-1.23.tar.gz',
  content  => $string,
);

#-------------------------------------------------------------------------#

require_ok( 'Metabase::Index::FlatFile' );

ok( my $index = $TEST->test_index, 'created an index' );
does_ok( $index, 'Metabase::Index' );
does_ok( $index, 'Metabase::Query' );

is( $index->count, 0, "Index is empty" );

# add()
ok( $index->add( $fact ), "Indexed fact 1" );

# count()
is( $index->count, 1, "Index has one entry" );
is( $index->count(-where => [ -eq => 'core.type' => 'CPAN-Testers-Report' ]),
  0, "Count with (false) query condition is 0"
);
is( $index->count(-where => [ -eq => 'core.type' => 'Test-Metabase-StringFact']),
  1, "Count with (true) query condition is 1"
);

ok( $index->add( $fact2 ), "Indexed fact 2" );
is( $index->count, 2, "Index has two entries" );

is( $index->count(-where => [ -eq => 'core.guid' => $fact->guid]),
  1, "Count with (limited) query condition is 1"
);

# search()
my $matches;
$matches = $index->search( -where => [ -eq => 'core.guid' => $fact->guid ] );
is( scalar @$matches, 1, "Found one fact searching for guid" );

$matches = $index->search( -where => [ -eq => 'resource.cpan_id' => 'JOHNDOE'] );
is( scalar @$matches, 2, "Found two facts searching for resource cpan_id" );

$matches = $index->search( -where => [ -eq => 'core.type' => $fact->type ] ) ;
is( scalar @$matches, 2, "Found two facts searching for fact type" );

$matches = $index->search( -where => [ -eq => 'content.size' => length $string ] ) ;
is( scalar @$matches, 1, "Found one fact searching on content.size" );

$matches = $index->search( 'content.size' => length $string ) ;
is( scalar @$matches, 1, "Found one fact searching on content.size (old API)" );

$matches = $index->search(
  'content.size' => length $string, 'core.type' => $fact2->type
) ;
is( scalar @$matches, 1,
  "Found one fact searching on two fields (old API test 2)"
);

$matches = $index->search(
  -where => [ -eq => 'core.guid' => $fact2->guid ],
  'content.size' => length $string, 'core.type' => $fact2->type
) ;
is( scalar @$matches, 1,
  "Found one fact searching on three fields (mixed API test)"
);

is( $matches->[0], $fact2->guid, "Result GUID matches expected fact GUID" );

$matches = $index->search( -where => [ -eq => 'resource.author' => "asdljasljfa" ]);
is( scalar @$matches, 0, "Found no facts searching for bogus dist_author" );

$matches = $index->search( -where => [ -eq => bogus_key => "asdljasljfa"] );
is( scalar @$matches, 0, "Found no facts searching on bogus key" );

# search with order and limit

$matches = $index->search(
  -where => [ -eq => 'core.type' => $fact->type ],
  -order => [ -asc => 'core.guid' ],
) ;
is( scalar @$matches, 2, "Ran ordered search" );
ok( $matches->[0] lt $matches->[1], "Facts in correct order" );

$matches = $index->search(
  -where => [ -eq => 'core.type' => $fact->type ],
  -order => [ -desc => 'core.guid' ],
) ;
is( scalar @$matches, 2, "Ran ordered search (reversed)" );
ok( $matches->[0] gt $matches->[1], "Facts in correct order" ) or
  diag explain $matches;

$matches = $index->search( -limit => 1 );
is( scalar @$matches, 1, "Querying with limit 1 returns 1 result" );

# exists()
ok( $index->exists( $fact->guid ), "Checked exists( guid )" );
ok( $index->exists( uc $fact->guid ), "Checked exists( GUID )" );
ok( ! $index->exists( '2475e04a-a8e7-11e0-bcb0-5f47df37754e' ),
  "Checked exists( fakeguid ) - false"
);


# delete()
ok( $index->delete( $fact->guid ), "Deleted fact 1 from index" );
is( $index->count, 1, "Index has one entry" );
ok( $index->delete( $fact2->guid ), "Deleted fact 2 from index" );
is( $index->count, 0, "Index is empty" );

done_testing;
