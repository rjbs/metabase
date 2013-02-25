use Test::More;
use Test::Routine;
use Test::Routine::Util;
use File::Temp ();

use Metabase::Index::FlatFile;

has tempfile => (
  is => 'ro',
  isa => 'File::Temp',
  lazy_build => 1,
);

sub _build_tempfile {
  return File::Temp->new( EXLOCK => 0 );
}

after clear_index => sub { shift->clear_tempfile };

sub _build_index {
  my $self = shift;
  return Metabase::Index::FlatFile->new(
    index_file => $self->tempfile->filename,
  );
}

run_tests(
  "Run Index tests on Metabase::Index::Filesystem",
  ["main", "Metabase::Test::Index"]
);

done_testing;
