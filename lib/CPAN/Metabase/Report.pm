package CPAN::Metabase::Report;
use Moose;

has guid => (
  is  => 'ro',
  isa => 'Data::GUID',
  handles => { guid_string => 'as_string' },
);

has type => (is => 'ro');
has fact => (
  is => 'ro',
);

has dist_author => (is => 'ro');
has dist_name   => (is => 'ro');
has summary     => (is => 'ro');

sub as_string {
  my ($self) = @_;
  $self->{content};
}

sub metadata {
  my ($self) = @_;

  return {
    map { $_ => $self->$_ } qw(dist_author dist_name type),
  };
}

1;
