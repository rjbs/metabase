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

require_ok( 'CPAN::Metabase::Storage::Filesystem' );

# die on missing or non-existing directory
my $re_bad_root_dir = qr/\QAttribute (root_dir)\E/;
throws_ok { CPAN::Metabase::Storage::Filesystem->new() } $re_bad_root_dir;
throws_ok { 
    CPAN::Metabase::Storage::Filesystem->new(root_dir => 'doesntexist') 
} $re_bad_root_dir;

