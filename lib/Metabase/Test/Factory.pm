use 5.006;
use strict;
use warnings;

package Metabase::Test::Factory;
# ABSTRACT: Test::Routine role for testing Metabase::Index implementations
# VERSION

use Metabase::Fact;
use Metabase::Test::Fact;

use Moose::Role;
use MooseX::Types::Moose qw/Str ClassName/;
use MooseX::Types::Structured qw/Map/;
use Moose::Util::TypeConstraints;

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

1;
