package Test::Metabase::Util;
use MooseX::Singleton;

use lib 'lib';

my $temp_root = 'eg/store';
File::Path::mkpath( $temp_root );

has test_gateway => (
  is   => 'ro',
  isa  => 'CPAN::Metabase::Gateway',
  lazy => 1,
  default => sub {
    require CPAN::Metabase::Analyzer::Test;
    my $gateway = CPAN::Metabase::Gateway->new({
      # This ->new is stupid, but will be required until I implement the
      # coersion I want, here. -- rjbs, 2008-04-06
      analyzers => [ CPAN::Metabase::Analyzer::Test->new ],
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
        dist_author => 'JOHNDOE', 
        dist_file   => 'Foo-Bar-1.23.tar.gz', 
        content     => "I smell something fishy.",
    );
  },
);

has test_storage => (
  is   => 'ro',
  isa  => 'CPAN::Metabase::Storage::Filesystem',
  lazy => 1,
  default => sub {
    require CPAN::Metabase::Storage::Filesystem;
    CPAN::Metabase::Storage::Filesystem->new(root_dir => "eg/store");
  },
);

has test_index => (
  is   => 'ro',
  isa  => 'CPAN::Metabase::Index::FlatFile',
  lazy => 1,
  default => sub {
    require CPAN::Metabase::Index::FlatFile;
    CPAN::Metabase::Index::FlatFile->new(index_file => "eg/store/metabase.index");
  },
);

has test_librarian => (
  is   => 'ro',
  isa  => 'CPAN::Metabase::Librarian',
  lazy => 1,
  default => sub {
    require CPAN::Metabase::Librarian;
    CPAN::Metabase::Librarian->new(
        archive => Test::Metabase::Util->test_storage,
        'index' => Test::Metabase::Util->test_index,
    );
  },
);

1;
