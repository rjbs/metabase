use 5.006;
use strict;
use warnings;

package Metabase::Test::Index;
# ABSTRACT: Test::Routine role for testing Metabase::Index implementations
# VERSION

use Metabase::Fact;
use Metabase::Test::Fact;
use Test::Deep qw/cmp_deeply/;
use Test::More 0.92;

use Test::Routine; # a Moose::Role
use MooseX::Types::Moose qw/Str ClassName/;
use MooseX::Types::Structured qw/Map/;
use Moose::Util::TypeConstraints;

#--------------------------------------------------------------------------#
# requirements from composing class
#--------------------------------------------------------------------------#

requires '_build_index';

#--------------------------------------------------------------------------#
# fixtures
#--------------------------------------------------------------------------#

with 'Metabase::Test::Factory';

has index => (
  is => 'ro',
  does => 'Metabase::Index',
  lazy_build => 1,
);

#--------------------------------------------------------------------------#
# methods
#--------------------------------------------------------------------------#

sub reset {
  my $self = shift;
  $self->clear_index;
  is( $self->index->count, 0, "Index is empty" );
  my @facts = (
    $self->get_test_fact("fact1"),
    $self->get_test_fact("fact2"),
  );

  $self->index->add($_) for @facts;
  is( $self->index->count, scalar @facts, "All test facts added" );

  return @facts;
}

#--------------------------------------------------------------------------#
# tests
#--------------------------------------------------------------------------#

test "add and count" => sub {
  my $self = shift;
  $self->clear_index;
  my ($fact1, $fact2) = map { $self->get_test_fact("fact$_") } 1..2;

  is( $self->index->count, 0, "Index is empty" );

  # add()
  ok( $self->index->add( $fact1 ), "Indexed fact 1" );

  # count()
  is( $self->index->count, 1, "Index has one entry" );
  is( $self->index->count(-where => [ -eq => 'core.guid' => '0' ]),
    0, "Count with (false) query condition is 0"
  );
  is( $self->index->count(-where => [ -eq => 'core.type' => 'Metabase-Test-Fact']),
    1, "Count with (true) query condition is 1"
  );

  ok( $self->index->add( $fact2 ), "Indexed fact 2" );
  is( $self->index->count, 2, "Index has two entries" );

  is( $self->index->count(-where => [ -eq => 'core.guid' => $fact1->guid]),
    1, "Count with (limited) query condition is 1"
  );

};

test "search" => sub {
  my $self = shift;

  my ($fact1, $fact2) = $self->reset;
  my $f2_string = $fact2->content;

  my $matches;
  $matches = $self->index->search( -where => [ -eq => 'core.guid' => $fact1->guid ] );
  is( scalar @$matches, 1, "Found one fact searching for guid" );

  $matches = $self->index->search( -where => [
      -and =>
        [-eq => 'resource.type' => 'Metabase-Resource-cpan-distfile'],
        [-eq => 'resource.cpan_id' => 'UNKNOWN']
    ]
  );
  is( scalar @$matches, 2, "Found two facts searching for resource cpan_id" );

  $matches = $self->index->search( -where => [
    -eq => 'core.type' => $fact1->type
  ] ) ;
  is( scalar @$matches, 2, "Found two facts searching for fact type" );

  $matches = $self->index->search( -where => [
    -and =>
      [-eq => 'content.size' => length $f2_string],
      [-eq => 'core.type' => 'Metabase-Test-Fact'],
  ] ) ;
  is( scalar @$matches, 1, "Found one fact searching on content.size" );

  $matches = $self->index->search( 'core.guid' => $fact2->guid ) ;
  is( scalar @$matches, 1, "Found one fact searching on content.size (old API)" );

  $matches = $self->index->search(
    'content.size' => length $f2_string, 'core.type' => $fact2->type
  ) ;
  is( scalar @$matches, 1,
    "Found one fact searching on two fields (old API test 2)"
  );

  $matches = $self->index->search(
    -where => [ -eq => 'core.guid' => $fact2->guid ],
    'content.size' => length $f2_string, 'core.type' => $fact2->type
  ) ;
  is( scalar @$matches, 1,
    "Found one fact searching on three fields (mixed API test)"
  );

  is( $matches->[0], $fact2->guid, "Result GUID matches expected fact GUID" );

  $matches = $self->index->search( -where => [
    -and =>
      [-eq => 'resource.type' => 'Metabase-Resource-cpan-distfile'],
      [-eq => 'resource.cpan_id' => "asdljasljfa" ],
  ]);
  is( scalar @$matches, 0, "Found no facts searching for bogus dist_author" );

  $matches = $self->index->search( -where => [ -eq => bogus_key => "asdljasljfa"] );
  is( scalar @$matches, 0, "Found no facts searching on bogus key" );

  $matches = $self->index->search(
    -where => [ -and =>
      [ -eq => 'core.type' => $fact1->type ],
      [ -gt => 'content.size' => 0 ]
    ]
  );
  is( scalar @$matches, 2, "Found two facts on compound query" );

  $matches = $self->index->search(
    -where => [ -and =>
      [ -eq => 'core.type' => $fact1->type ],
      [ -ne => 'core.guid' => 0 ]
    ],
    -order => [ -asc => 'core.guid' ],
  ) ;
  is( scalar @$matches, 2, "Ran ordered search" );
  ok( $matches->[0] lt $matches->[1], "Facts in correct order" );

  $matches = $self->index->search(
    -where => [ -and =>
      [ -eq => 'core.type' => $fact1->type ],
      [ -ne => 'core.guid' => 0 ]
    ],
    -order => [ -desc => 'core.guid' ],
  ) ;
  is( scalar @$matches, 2, "Ran ordered search (reversed)" );
  ok( $matches->[0] gt $matches->[1], "Facts in correct order" ) or
  diag explain $matches;

  $matches = $self->index->search(
    -where => [ -ne => 'core.guid' => 0 ],
    -order => [ -desc => 'core.guid' ],
    -limit => 1
  );
  is( scalar @$matches, 1, "Querying with limit 1 returns 1 result" );

};

test "exists()" => sub {
  my $self = shift;

  my ($fact1, $fact2) = $self->reset;
  my $f2_string = $fact2->content;

  ok( $self->index->exists( $fact1->guid ), "Checked exists( guid )" );
  ok( $self->index->exists( uc $fact1->guid ), "Checked exists( GUID )" );
  ok( ! $self->index->exists( '2475e04a-a8e7-11e0-bcb0-5f47df37754e' ),
    "Checked exists( fakeguid ) - false"
  );
};

test "delete()" => sub {
  my $self = shift;
  my ($fact1, $fact2) = $self->reset;
  ok( $self->index->delete( $fact1->guid ), "Deleted fact 1 from index" );
  is( $self->index->count, 1, "Index has one entry" );
  ok( $self->index->delete( $fact2->guid ), "Deleted fact 2 from index" );
  is( $self->index->count, 0, "Index is empty" );
};

1;

