package Test::Metabase::Util;
use MooseX::Singleton;

use CPAN::Metabase::Analyzer::Test;

has test_gateway => (
  is   => 'ro',
  isa  => 'CPAN::Metabase::Gateway',
  lazy => 1,
  default => sub {
    my $gateway = CPAN::Metabase::Gateway->new({
      # This ->new is stupid, but will be required until I implement the
      # coersion I want, here. -- rjbs, 2008-04-06
      analyzers => [ CPAN::Metabase::Analyzer::Test->new ],
    });
  }
);

1;
