# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a
# copy of the License from http://dev.perl.org/licenses/

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

