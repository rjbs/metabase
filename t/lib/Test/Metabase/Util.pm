package Test::Metabase::Util;
use MooseX::Singleton;

use lib 'lib';

use File::Temp;
use Path::Class;

# This is ridiculous. -- rjbs, 2008-04-13
my $temp_dir  = File::Temp::tempdir(CLEANUP => 1);
my $store_dir = Path::Class::dir($temp_dir)->subdir('store');
$store_dir->mkpath;
close $store_dir->file('metabase.index')->openw;

has test_gateway => (
  is   => 'ro',
  isa  => 'CPAN::Metabase::Gateway',
  lazy => 1,
  default => sub {
    require CPAN::Metabase::Analyzer::Test;
    my $gateway = CPAN::Metabase::Gateway->new({
      fact_classes => [ 'CPAN::Metabase::Fact::TestFact' ],
    });
  }
);

has test_fact => (
  is   => 'ro',
  isa  => 'CPAN::Metabase::Fact',
  lazy => 1,
  default => sub {
    require CPAN::Metabase::Fact::TestFact;
    CPAN::Metabase::Fact::TestFact->new( 
      resource => 'JOHNDOE/Foo-Bar-1.23.tar.gz', 
      content  => "I smell something fishy.",
    );
  },
);

has test_archive => (
  is   => 'ro',
  isa  => 'CPAN::Metabase::Archive::SQLite',
  lazy => 1,
  default => sub {
    require CPAN::Metabase::Archive::SQLite;
    CPAN::Metabase::Archive::SQLite->new(filename => "$temp_dir/store.db", compressed => 0);
  },
);

has test_index => (
  is   => 'ro',
  isa  => 'CPAN::Metabase::Index::FlatFile',
  lazy => 1,
  default => sub {
    require CPAN::Metabase::Index::FlatFile;
    CPAN::Metabase::Index::FlatFile->new(index_file => "$temp_dir/store/metabase.index");
  },
);

has test_librarian => (
  is   => 'ro',
  isa  => 'CPAN::Metabase::Librarian',
  lazy => 1,
  default => sub {
    require CPAN::Metabase::Librarian;
    CPAN::Metabase::Librarian->new(
        archive => Test::Metabase::Util->test_archive,
        'index' => Test::Metabase::Util->test_index,
    );
  },
);

1;
