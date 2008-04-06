
use strict;
use warnings;
use lib 'lib';
use CPAN::Metabase::Injector;
use CPAN::Metabase::Report;
use CPAN::Metabase::Gateway;

my $root = $ENV{CPAN_METABASE_ROOT} = './eg';

CPAN::Metabase::Gateway->handle({
  'auth.key'  => 'xyzzy',
  dist_name   => 'Foo-Bar-2.345.tar.gz',
  dist_author => 'KWIJIBO',
  type        => 'CPAN::Metabase::Test',
  content     => "This...\n\t...is...\n\t\t...CPANtown!\n",
});

1;
