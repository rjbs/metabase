
use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use CPAN::Metabase::Analyzer;
use CPAN::Metabase::Injector;
use CPAN::Metabase::Report;
use CPAN::Metabase::Gateway;

use CPAN::Metabase::Analyzer::Test;

my $root = $ENV{CPAN_METABASE_ROOT} = './eg';

my $gateway = CPAN::Metabase::Gateway->new({
  # This ->new is stupid, but will be required until I implement the coersion I
  # want, here. -- rjbs, 2008-04-06
  analyzers => [ CPAN::Metabase::Analyzer::Test->new ],
});

$gateway->handle({
  'auth.key'  => 'xyzzy',
  dist_name   => 'Foo-Bar-2.345.tar.gz',
  dist_author => 'KWIJIBO',
  type        => 'CPAN::Metabase::Test',
  content     => "eyBvZG9yID0+ICJhd2Z1bCIgfQ==",
});

1;
