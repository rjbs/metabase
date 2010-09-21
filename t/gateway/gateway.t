use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';
use Test::Metabase::Util;
my $TEST = Test::Metabase::Util->new;

my $gateway = $TEST->test_gateway;

isa_ok( $gateway, 'Test::Metabase::Gateway' );

# XXX really should test the API -- dagolden, 2010-03-03

done_testing;
