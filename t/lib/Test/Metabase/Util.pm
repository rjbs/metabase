package Test::Metabase::Util;
use Moose;

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
  isa  => 'Metabase::Gateway',
  lazy => 1,
  default => sub {
    require Metabase::Analyzer::Test;
    my $gateway = Metabase::Gateway->new({
      fact_classes => [ 'Test::Metabase::StringFact' ],
    });
  }
);

has test_fact => (
  is   => 'ro',
  isa  => 'Metabase::Fact',
  lazy => 1,
  default => sub {
    require Test::Metabase::StringFact;
    Test::Metabase::StringFact->new( 
      resource => 'JOHNDOE/Foo-Bar-1.23.tar.gz', 
      content  => "I smell something fishy.",
    );
  },
);

has test_report => (
  is   => 'ro',
  isa  => 'Metabase::Report',
  lazy => 1,
  default => sub {
    require Test::Metabase::Report;
    my $report = Test::Metabase::Report->open(
      resource => 'JOHNDOE/Foo-Bar-1.23.tar.gz'
    );
    $report->add( 'Test::Metabase::StringFact' => "I smell something fishy.");
    $report->add( 'Test::Metabase::StringFact' => "Fish is brain food.");
    $report->close;
    return $report
  },
);

has test_archive => (
  is   => 'ro',
  isa  => 'Metabase::Archive::SQLite',
  lazy => 1,
  default => sub {
    require Metabase::Archive::SQLite;
    Metabase::Archive::SQLite->new(
      filename   => "$temp_dir/store.db",
      compressed => 0,
    );
  },
);

has test_index => (
  is   => 'ro',
  isa  => 'Metabase::Index::FlatFile',
  lazy => 1,
  default => sub {
    require Metabase::Index::FlatFile;
    Metabase::Index::FlatFile->new(
      index_file => "$temp_dir/store/metabase.index",
    );
  },
);

has test_librarian => (
  is   => 'ro',
  isa  => 'Metabase::Librarian',
  lazy => 1,
  default => sub {
    require Metabase::Librarian;
    Metabase::Librarian->new(
        archive => $_[0]->test_archive,
        'index' => $_[0]->test_index,
    );
  },
);

no Moose;
1;
