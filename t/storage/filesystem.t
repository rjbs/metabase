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
use Test::Metabase::StringFact;

#--------------------------------------------------------------------------#

my $dist_id = 'UNKNOWN/Foo-Bar-1.23.tar.gz';

#--------------------------------------------------------------------------#

plan tests => 10;

require_ok( 'Metabase::Archive::Filesystem' );

# die on missing or non-existing directory
my $re_bad_root_dir = qr/\QAttribute (root_dir)\E/;
throws_ok { Metabase::Archive::Filesystem->new() } $re_bad_root_dir;
throws_ok { 
    Metabase::Archive::Filesystem->new(root_dir => 'doesntexist') 
} $re_bad_root_dir;

# store into a temp directory
#my $temp_root = File::Temp->newdir() or die;
my $temp_root = 'eg/store';
File::Path::mkpath( $temp_root );

my $archive;
lives_ok { 
    $archive = Metabase::Archive::Filesystem->new(root_dir => "$temp_root");
} "created store at '$temp_root'";

my $fact = Test::Metabase::StringFact->new( 
    resource => $dist_id,
    content  => "I smell something fishy.",
);

isa_ok( $fact, 'Test::Metabase::StringFact' );

ok( my $guid = $archive->store( $fact->as_struct ), "stored a fact" );

is( $fact->guid, $guid, "GUID returned matched GUID in fact" );

my $copy_struct = $archive->extract( $guid );
my $class = Metabase::Fact->class_from_type($copy_struct->{metadata}{core}{type}[1]);

ok( my $copy = $class->from_struct( $copy_struct ),
    "got a fact from archive"
);

for my $p ( qw/type content/ ) {
    is_deeply( $copy->$p, $fact->$p, "second object has same $p" )
}



