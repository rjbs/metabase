# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

use strict;
use warnings;

use Test::More;

use JSON 2 ();
use Test::Exception;
use File::Temp ();
use File::Path ();

use lib 't/lib';
use Test::Metabase::Util;
my $TEST = Test::Metabase::Util->new;

plan tests => 12;

#-------------------------------------------------------------------------#

require_ok( 'Metabase::Librarian' );

ok( my $librarian = $TEST->test_librarian, 'created librarian' );

ok( my $report = $TEST->test_report, "created a report" );
isa_ok( $report, 'Test::Metabase::Report' );

ok(
  my $guid = $librarian->store($report, { user_id => 'Larry' }),
  "stored a report"
);

for my $f ( $report, $report->facts ) {
  ok( $librarian->exists( $f->guid ), "$f was stored" );
}

my $matches;

$matches = $librarian->search( 'core.guid' => $guid );
is( scalar @$matches, 1, "found guid searching for guid" );

ok(
  my $new_fact = $librarian->extract( $matches->[0] ),
  "extracted object from guid from search"
);

# XXX comparison has issues with update_time not matching -- dagolden, 2010-04-25
my $update_time = $new_fact->{metadata}{core}{update_time};
for ( $new_fact, $new_fact->facts, $report, $report->facts ) {
  $_->{metadata}{core}{update_time} = $update_time;
}

my $JSON = JSON->new;
is_deeply(
  $JSON->decode( $new_fact->content_as_bytes ),
  $JSON->decode( $report->content_as_bytes   ),
  "fact content matches",
);

is( $new_fact->resource, $report->resource, "dist name was indexed as expected" );
