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

#--------------------------------------------------------------------------#
# tests
#--------------------------------------------------------------------------#

test "add and count" => sub {
  my $self = shift;

  my $fact1 = $self->get_test_fact("fact1");
  my $fact2 = $self->get_test_fact("fact2");

  is( $self->index->count, 0, "Index is empty" );

  # add()
  ok( $self->index->add( $fact1 ), "Indexed fact 1" );

  # count()
  is( $self->index->count, 1, "Index has one entry" );
  is( $self->index->count(-where => [ -eq => 'core.type' => 'CPAN-Testers-Report' ]),
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

  $self->clear_index;

  my $fact1 = $self->get_test_fact("fact1");
  my $fact2 = $self->get_test_fact("fact2");
  my $f2_string = $fact2->content;
  is( $self->index->count, 0, "Index is empty" );
  ok( $self->index->add( $fact1 ), "Indexed fact 1" );
  ok( $self->index->add( $fact2 ), "Indexed fact 2" );


  my $matches;
  $matches = $self->index->search( -where => [ -eq => 'core.guid' => $fact1->guid ] );
  is( scalar @$matches, 1, "Found one fact searching for guid" );

  $matches = $self->index->search( -where => [ -eq => 'resource.cpan_id' => 'UNKNOWN'] );
  is( scalar @$matches, 2, "Found two facts searching for resource cpan_id" );

  $matches = $self->index->search( -where => [ -eq => 'core.type' => $fact1->type ] ) ;
  is( scalar @$matches, 2, "Found two facts searching for fact type" );

  $matches = $self->index->search( -where => [ -eq => 'content.size' => length $f2_string ] ) ;
  is( scalar @$matches, 1, "Found one fact searching on content.size" );

  $matches = $self->index->search( 'content.size' => length $f2_string ) ;
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

  $matches = $self->index->search( -where => [ -eq => 'resource.author' => "asdljasljfa" ]);
  is( scalar @$matches, 0, "Found no facts searching for bogus dist_author" );

  $matches = $self->index->search( -where => [ -eq => bogus_key => "asdljasljfa"] );
  is( scalar @$matches, 0, "Found no facts searching on bogus key" );
};


#
## search with order and limit
#
#$matches = $index->search(
#  -where => [ -eq => 'core.type' => $fact->type ],
#  -order => [ -asc => 'core.guid' ],
#) ;
#is( scalar @$matches, 2, "Ran ordered search" );
#ok( $matches->[0] lt $matches->[1], "Facts in correct order" );
#
#$matches = $index->search(
#  -where => [ -eq => 'core.type' => $fact->type ],
#  -order => [ -desc => 'core.guid' ],
#) ;
#is( scalar @$matches, 2, "Ran ordered search (reversed)" );
#ok( $matches->[0] gt $matches->[1], "Facts in correct order" ) or
#  diag explain $matches;
#
#$matches = $index->search( -limit => 1 );
#is( scalar @$matches, 1, "Querying with limit 1 returns 1 result" );
#
## exists()
#ok( $index->exists( $fact->guid ), "Checked exists( guid )" );
#ok( $index->exists( uc $fact->guid ), "Checked exists( GUID )" );
#ok( ! $index->exists( '2475e04a-a8e7-11e0-bcb0-5f47df37754e' ),
#  "Checked exists( fakeguid ) - false"
#);
#
#
## delete()
#ok( $index->delete( $fact->guid ), "Deleted fact 1 from index" );
#is( $index->count, 1, "Index has one entry" );
#ok( $index->delete( $fact2->guid ), "Deleted fact 2 from index" );
#is( $index->count, 0, "Index is empty" );
#
#test "store and retrieve" => sub {
#  my $self = shift;
#  $self->clear_archive;
#
#  my $fact = $self->get_test_fact('fact1');
#  my $guid = $self->archive->store( $fact->as_struct );
#
#  is( $fact->guid, $guid, "GUID returned matched GUID in fact" );
#
#  my $copy_struct = $self->archive->extract( $guid );
#  my $class = Metabase::Fact->class_from_type($copy_struct->{metadata}{core}{type});
#
#  ok( my $copy = $class->from_struct( $copy_struct ),
#      "got a fact from archive"
#  );
#
#  cmp_deeply( $copy, $fact, "Extracted fact matches original" );
#};
#
#test "iteration" => sub {
#  my $self = shift;
#  $self->clear_archive;
#  my $n_facts = $self->store_all;
#
#  my $iter = $self->archive->iterator;
#  my @facts;
#  while( my $block = $iter->next ) {
#      foreach my $item ( @$block ) {
#          push @facts, $item;
#      }
#  }
#
#  is( scalar @facts, $n_facts, "iterator found all facts" );
#};
#
#
#test "deletion" => sub {
#  my $self = shift;
#  $self->clear_archive;
#  my $n_facts = $self->store_all;
#
#  my $fact = $self->get_test_fact('fact1');
#
#  ok( $self->archive->delete( $fact->guid ), "deleted fact1" );
#
#  my $iter = $self->archive->iterator;
#  my @facts;
#  while( my $block = $iter->next ) {
#      foreach my $item ( @$block ) {
#          push @facts, $item;
#      }
#  }
#
#  is( scalar @facts, $n_facts-1, "iterator found one less fact" );
#};

1;

