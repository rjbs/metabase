# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp ();
use File::Path ();

use lib 't/lib';
use CPAN::Metabase::Fact::TestFact;

#--------------------------------------------------------------------------#

my $dist_author = 'UNKNOWN';
my $dist_file = 'Foo-Bar-1.23.tar.gz';

#--------------------------------------------------------------------------#

plan tests => 10;

require_ok( 'CPAN::Metabase::Storage::Filesystem' );

# die on missing or non-existing directory
my $re_bad_root_dir = qr/\QAttribute (root_dir)\E/;
throws_ok { CPAN::Metabase::Storage::Filesystem->new() } $re_bad_root_dir;
throws_ok { 
    CPAN::Metabase::Storage::Filesystem->new(root_dir => 'doesntexist') 
} $re_bad_root_dir;

# store into a temp directory
#my $temp_root = File::Temp->newdir() or die;
my $temp_root = 'eg/store';
File::Path::mkpath( $temp_root );

my $storage;
lives_ok { 
    $storage = CPAN::Metabase::Storage::Filesystem->new(root_dir => "$temp_root");
} "created store at '$temp_root'";

my $fact = CPAN::Metabase::Fact::TestFact->new( 
    dist_author => $dist_author, 
    dist_file   => $dist_file, 
    content     => "I smell something fishy.",
);

isa_ok( $fact, 'CPAN::Metabase::Fact::TestFact' );

$fact->mark_submitted(user_id => 'Larry');

ok( my $guid = $storage->store( $fact ), "stored a fact" );

is( $fact->guid, $guid, "GUID returned matched GUID in fact" );

ok( my $copy = $storage->extract( $guid ),
    "got a fact from storage"
);

for my $p ( qw/type content/ ) {
    is_deeply( $copy->$p, $fact->$p, "second object has same $p" )
}



