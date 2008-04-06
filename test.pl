
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
  analyzers => [ qw(CPAN::Metabase::Analyzer::Test) ],
});

$gateway->handle({
  'auth.key'  => 'xyzzy',
  dist_name   => 'Foo-Bar-2.345.tar.gz',
  dist_author => 'KWIJIBO',
  type        => 'CPAN::Metabase::Test',
  content     => "This...\n\t...is...\n\t\t...CPANtown!\n",
});

1;
