use 5.006;
use strict;
use warnings;
package Metabase::Test::Archive;
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

requires '_build_archive';

#--------------------------------------------------------------------------#
# fixtures
#--------------------------------------------------------------------------#

my $dist_id = 'cpan:///distfile/UNKNOWN/Foo-Bar-1.23.tar.gz';
my %fact_content = (
  fact1 => "Hello World",
  fact2 => "Everything is fine",
);

has test_fact => (
  traits => ['Hash'],
  is => 'ro',
  isa => Map[Str, class_type('Metabase::Test::Fact')],
  default => sub {
    my %hash;
    for my $k ( keys %fact_content ) {
      $hash{$k} = Metabase::Test::Fact->new(
        resource => $dist_id,
        content => $fact_content{$k},
      );
    };
    return \%hash;
  },
  handles => {
    get_test_fact => 'get',
    keys_test_fact => 'keys',
  },
);

has archive => (
  is => 'ro',
  does => 'Metabase::Archive',
  lazy_build => 1,
);

sub store_all {
  my $self = shift;
  my @keys = $self->keys_test_fact;
  for my $k ( @keys ) {
    ok( $self->archive->store( $self->get_test_fact($k)->as_struct ),
      "stored $k"
    );
  }
  return scalar @keys;
}

#--------------------------------------------------------------------------#
# tests
#--------------------------------------------------------------------------#

test "store and retrieve" => sub {
  my $self = shift;
  $self->clear_archive;

  my $fact = $self->get_test_fact('fact1');
  my $guid = $self->archive->store( $fact->as_struct );

  is( $fact->guid, $guid, "GUID returned matched GUID in fact" );

  my $copy_struct = $self->archive->extract( $guid );
  my $class = Metabase::Fact->class_from_type($copy_struct->{metadata}{core}{type});

  ok( my $copy = $class->from_struct( $copy_struct ),
      "got a fact from archive"
  );

  cmp_deeply( $copy, $fact, "Extracted fact matches original" );
};

test "iteration" => sub {
  my $self = shift;
  $self->clear_archive;
  my $n_facts = $self->store_all;

  my $iter = $self->archive->iterator;
  my @facts;
  while( my $block = $iter->next ) {
      foreach my $item ( @$block ) {
          push @facts, $item;
      }
  }

  is( scalar @facts, $n_facts, "iterator found all facts" );
};


test "deletion" => sub {
  my $self = shift;
  $self->clear_archive;
  my $n_facts = $self->store_all;

  my $fact = $self->get_test_fact('fact1');

  ok( $self->archive->delete( $fact->guid ), "deleted fact1" );

  my $iter = $self->archive->iterator;
  my @facts;
  while( my $block = $iter->next ) {
      foreach my $item ( @$block ) {
          push @facts, $item;
      }
  }

  is( scalar @facts, $n_facts-1, "iterator found one less fact" );
};

1;

# ABSTRACT: Test::Routine role for testing Metabase::Archive implementations

