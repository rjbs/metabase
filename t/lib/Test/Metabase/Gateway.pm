package Test::Metabase::Gateway;

use Moose;
use MooseX::Types::Path::Class qw/Dir/;
use Metabase::Archive::Filesystem;
use Metabase::Index::FlatFile;
use Metabase::Librarian;
use namespace::autoclean;

with 'Metabase::Gateway';

has 'data_dir' => (
  is => 'ro',
  isa => Dir,
  coerce => 1,
  required => 1,
);

has '_gateway_storage' => (
  is => 'ro',
  isa => Dir,
  coerce => 1,
  lazy_build => 1,
);

sub _build__gateway_storage {
  my $self = shift;
  my $store = $self->data_dir->subdir('gateway-store');
  $store->mkpath;
  return $store;
}
  
sub _build_public_librarian {
  my $self = shift;
  my $archive_store = $self->_gateway_storage->dir('public.archive');
  my $index_store = $self->_gateway_storage->file('public.index');
  $index_store->touch;
  return $self->__build_librarian($archive_store, $index_store);
}

sub _build_private_librarian {
  my $self = shift;
  my $archive_store = $self->_gateway_storage->dir('private.archive');
  my $index_store = $self->_gateway_storage->file('private.index');
  $index_store->touch;
  return $self->__build_librarian($archive_store, $index_store);
}

sub __build_librarian {
  my $self = shift;
  return Metabase::Librarian->new(
    archive => Metabase::Archive::Filesystem->new(
      root_dir => $_[0]->stringify
    ),
    index => Metabase::Index::FlatFile->new(
      index_file => $_[1]->stringify
    ),
  );
}

sub _build_fact_classes {
  return [qw/Metabase::Fact::String Metabase::Fact::Hash/];
}

__PACKAGE__->meta->make_immutable;
1;
