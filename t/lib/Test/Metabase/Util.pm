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
      fact_classes => [ 'CPAN::Metabase::Fact::TestFact' ],
    });
  }
);

has test_archive => (
  is   => 'ro',
  isa  => 'CPAN::Metabase::Archive::Filesystem',
  lazy => 1,
  default => sub {
    require CPAN::Metabase::Archive::Filesystem;
    CPAN::Metabase::Archive::Filesystem->new(root_dir => "eg/store");
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

1;
