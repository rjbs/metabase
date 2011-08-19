use strict;
use warnings;

use Test::More;
use Test::Routine;
use Test::Routine::Util;
use File::Temp ();

use Metabase::Archive::Filesystem;

sub _build_archive {
  return Metabase::Archive::Filesystem->new(
    root_dir => File::Temp::tempdir( CLEANUP => 1 ),
  );
}

run_tests(
  "Run Archive tests on Metabase::Archive::Filesystem",
  ["main", "Metabase::Test::Archive"]
);

done_testing;

