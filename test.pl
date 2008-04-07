
use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More 'no_plan';
use File::Temp qw(tempdir);
my $root = $ENV{CPAN_METABASE_ROOT} = tempdir(CLEANUP => 1);

use CPAN::Metabase::Analyzer;
use CPAN::Metabase::Injector;
use CPAN::Metabase::Report;
use CPAN::Metabase::Gateway;

use Test::Metabase::Util;

my $gateway = Test::Metabase::Util->test_gateway;

$gateway->handle({
  'auth.key'  => 'xyzzy',
  dist_name   => 'Foo-Bar-2.345.tar.gz',
  dist_author => 'KWIJIBO',
  type        => 'CPAN::Metabase::Test',
  content     => "eyBvZG9yID0+ICJhd2Z1bCIgfQ==",
});

diag $_ for map { s/\Q$root//g; $_ } `find $root`;

1;
