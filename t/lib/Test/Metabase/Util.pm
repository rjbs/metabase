package Test::Metabase::Util;
use MooseX::Singleton;

use CPAN::Metabase::Analyzer::Test;
use File::Temp qw(tempdir);

has test_gateway => (
  is   => 'ro',
  isa  => 'CPAN::Metabase::Gateway',
  lazy => 1,
  default => sub {
    my $root = tempdir(CLEANUP => 1);
    my $gateway = CPAN::Metabase::Gateway->new({
      # This ->new is stupid, but will be required until I implement the
      # coersion I want, here. -- rjbs, 2008-04-06
      analyzers => [ CPAN::Metabase::Analyzer::Test->new ],
    });
  }
);

1;
