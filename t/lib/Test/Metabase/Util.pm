package Test::Metabase::Util;
use Moose;

use lib 'lib';

use File::Temp;
use Path::Class;

# This is ridiculous. -- rjbs, 2008-04-13
my $temp_dir = File::Temp::tempdir( CLEANUP => 1 );
my $store_dir = Path::Class::dir($temp_dir)->subdir('store');
$store_dir->mkpath;
close $store_dir->file('metabase.index')->openw;

has test_fact => (
    is      => 'ro',
    isa     => 'Metabase::Fact',
    lazy    => 1,
    default => sub {
        require Test::Metabase::StringFact;
        Test::Metabase::StringFact->new(
            resource => 'cpan:///distfile/JOHNDOE/Foo-Bar-1.23.tar.gz',
            content  => "I smell something fishy.",
        );
    },
);

has test_report => (
    is      => 'ro',
    isa     => 'Metabase::Report',
    lazy    => 1,
    default => sub {
        require Test::Metabase::Report;
        my $report = Test::Metabase::Report->open(
            resource => 'cpan:///distfile/JOHNDOE/Foo-Bar-1.23.tar.gz' );
        $report->add(
            'Test::Metabase::StringFact' => "I smell something fishy." );
        $report->add( 'Test::Metabase::StringFact' => "Fish is brain food." );
        $report->close;
        return $report;
    },
);

has test_archive_class => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'Metabase::Archive::SQLite',
);

has test_archive_args => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
    default  => sub { [filename => "$temp_dir/store.db", compressed => 0] },
);

has test_archive => (
    is      => 'ro',
    does    => 'Metabase::Archive',
    lazy    => 1,
    builder => '_build_test_archive',
);

sub _build_test_archive {
    my ($self) = @_;
    my $archive_class = $self->test_archive_class;
    Class::MOP::load_class($archive_class);
    return $archive_class->new(@{ $self->test_archive_args });
}

has test_index_class => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'Metabase::Index::FlatFile',
);

has test_index_args => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
    default  => sub { [index_file => "$temp_dir/store/metabase.index"] },
);

has test_index => (
    is      => 'ro',
    does    => 'Metabase::Index',
    lazy    => 1,
    builder => '_build_test_index',
);

sub _build_test_index {
    my ($self) = @_;
    my $index_class = $self->test_index_class;
    Class::MOP::load_class($index_class);
    return $index_class->new(@{ $self->test_index_args });
}

has test_librarian => (
    is      => 'ro',
    isa     => 'Metabase::Librarian',
    lazy    => 1,
    default => sub {
        require Metabase::Librarian;
        Metabase::Librarian->new(
            archive => $_[0]->test_archive,
            'index' => $_[0]->test_index,
        );
    },
);

has test_gateway => (
    is      => 'ro',
    does    => 'Metabase::Gateway',
    lazy    => 1,
    default => sub {
        require Test::Metabase::Gateway;
        return Test::Metabase::Gateway->new(
          data_dir => $temp_dir,
        );
    }
);

no Moose;
1;
