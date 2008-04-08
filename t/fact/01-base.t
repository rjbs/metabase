# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

use strict;
use warnings;

use Test::More;
use Test::Exception;

plan tests => 3;

require_ok( 'CPAN::Metabase::Fact' );

my $obj = bless {}, 'CPAN::Metabase::Fact';

for my $m ( qw/as_string from_string/ ) {
    throws_ok { $obj->$m } qr/$m\(\) not implemented by CPAN::Metabase::Fact/;
}

