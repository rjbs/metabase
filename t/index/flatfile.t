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

plan tests => 14;

#-------------------------------------------------------------------------#

require_ok( 'CPAN::Metabase::Index::FlatFile' );

ok( my $archive = Test::Metabase::Util->test_archive, 'created archive' );
isa_ok( $archive, 'CPAN::Metabase::Archive::SQLite' );

ok( my $index = Test::Metabase::Util->test_index, 'created an index' );
isa_ok( $index, 'CPAN::Metabase::Index::FlatFile' );

ok( my $fact = Test::Metabase::Util->test_fact, "created a fact" );
isa_ok( $fact, 'CPAN::Metabase::Fact::TestFact' );

ok( my $guid = $archive->store( $fact ), "stored a fact" );

ok( $index->add( $fact ), "indexed fact" );

my $matches;
$matches = $index->search( 'core.guid' => $guid );
is( scalar @$matches, 1, "found guid searching for guid" );

TODO: {
  local $TODO = 'resource indexing';
  $matches = $index->search( 'resource.author' => 'JOHNDOE' );
  ok( scalar @$matches >= 1, "found guid searching for fact dist_author" );
}

$matches = $index->search( 'core.type' => $fact->type );
ok( scalar @$matches >= 1, "found guid searching for fact type" );

$matches = $index->search( 'resource.author' => "asdljasljfa" );
is( scalar @$matches, 0, "found no guids searching for bogus dist_author" );

$matches = $index->search( bogus_key => "asdljasljfa" );
is( scalar @$matches, 0, "found no guids searching on bogus key" );

