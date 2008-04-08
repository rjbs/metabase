use strict;
use warnings;

use Test::More 'no_plan';

my $PA = 'CPAN::Metabase::Fact::PrereqAnalysis';

require_ok $PA;

my $sample = {
  'Meta::Meta'    => '0.001',
  'Mecha::Meta'   => '1.234',
  'Physics::Meta' => '9.1.12',
  'Physics::Pata' => '0.1_02',
};

sub new_pa {
  my ($content) = @_;

  return $PA->new(
    dist_name   => 'Test-Meta-1.00.tar.gz',
    dist_author => 'OPRIME',
    content     => $content,
  );
}

{
  # TODO: rewrite this to use preferred hashref style -- rjbs, 2008-04-08
  throws_ok { new_pa([ X => 1 ]) } "can't make prereq fact with bogus content";
}
