package CPAN::Metabase::Gateway;
use Moose;

use CPAN::Metabase::Librarian;
use Data::GUID;

has fact_classes => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  auto_deref => 1,
  required   => 1,
);

has librarian => (
  is       => 'ro',
  isa      => 'CPAN::Metabase::Librarian',
  required => 1,
);

sub _validate_resource {
  my ($self, $request) = @_;

  # XXX Well... yeah, eventually we'll want to reject reports for dists that
  # don't, you know, exist. -- rjbs, 2008-04-06
  1;
}

my %IS_USER = map {; $_ => 1 } qw(74B9A2EA-1D1A-11DE-BE21-DD62421C7A0A);
sub _validate_user {
  my $user = $_[1]; 
  return $IS_USER{ $user->{metadata}{core}{guid}[1] };
}

sub handle {
  my ($self, $struct) = @_;

  my $fact_struct = $struct->{fact};
  my $user_struct = $struct->{submitter};

  use Data::Dumper;
  local $SIG{__WARN__} = sub { warn "@_: " . Dumper($struct); };

  die "unknown user" unless $self->_validate_user($user_struct);
  die "unknown dist" unless $self->_validate_resource($struct);
  die "submissions must not include resource or content metadata"
    if $fact_struct->{metadata}{content} or $fact_struct->{metadata}{resource};

  my $type = $fact_struct->{metadata}{core}{type}[1];

  my $fact;
  FACT_CLASS: for my $fact_class ($self->fact_classes) {
    eval "require $fact_class; 1" or die;
    next FACT_CLASS unless $fact_class->type eq $type;
    $fact = eval { $fact_class->from_struct($fact_struct) };
    die $@ unless $fact;
  }

  return $self->enqueue( $fact, $user );
}

sub enqueue {
  my ($self, $fact, $credential) = @_;
  return $self->librarian->store($fact, $credential);
}

1;
