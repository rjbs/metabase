# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

use strict;
use warnings;

use Test::More;
use Test::Exception;

plan tests => 9;

require_ok( 'CPAN::Metabase::Fact' );

#--------------------------------------------------------------------------#
# fixtures
#--------------------------------------------------------------------------#    

my ($obj, $err);

#--------------------------------------------------------------------------#
# required parameters missing
#--------------------------------------------------------------------------#

eval { $obj = CPAN::Metabase::Fact->new() };
$err = $@;
like( $err, qr/Mandatory parameters/, "new() without params throws error" );
for my $p ( qw/ dist_author dist_file content / ) {
    like( $err, qr/$p/, "... '$p' noted missing" );
}

#--------------------------------------------------------------------------#
# fake an object and test unimplemented
#--------------------------------------------------------------------------#

$obj = bless {}, 'CPAN::Metabase::Fact';

for my $m ( qw/type as_string from_string validate_content/ ) {
    throws_ok { $obj->$m } qr/$m\(\) not implemented by CPAN::Metabase::Fact/;
}


