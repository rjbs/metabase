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

has secret_librarian => (
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

sub __submitter_profile {
  my ($self, $profile_struct) = @_;

  my $profile_guid = $profile_struct->{metadata}{core}{guid}[1];
  my $profile_fact = eval {
    $self->secret_librarian->extract($profile_guid);
  };

  return unless $profile_fact;

  my $given  = $profile_struct->{metadata}{core}{secret}[1];
  my $secret = $profile_fact->core_metadata->{secret}[1];

  return unless defined $given and defined $secret and $given eq $secret;

  return $profile_fact;
}

sub _validate_fact_struct {
  my ($self, $struct) = @_;

  die "no resource provided" unless $struct->{metadata}{core}{resource};

  die "submissions must not include resource or content metadata"
    if $struct->{metadata}{content} or $struct->{metadata}{resource};
}

sub _check_permissions {
  my ($self, $profile, $action, $fact) = @_;

  # The devil may care, but we don't. -- rjbs, 2009-03-30
  return 1;
}

sub handle_submission {
  my ($self, $struct) = @_;

  my $fact_struct    = $struct->{fact};
  my $profile_struct = $struct->{submitter};

  use Data::Dumper;
  local $SIG{__WARN__} = sub { warn "@_: " . Dumper($struct); };

  die "unknown submitter profile"
    unless my $profile = $self->__submitter_profile($profile_struct);

  $self->_validate_fact_struct($fact_struct);

  my $type = $fact_struct->{metadata}{core}{type}[1];

  my $fact;
  FACT_CLASS: for my $fact_class ($self->fact_classes) {
    eval "require $fact_class; 1" or die;
    next FACT_CLASS unless $fact_class->type eq $type;
    $fact = eval { $fact_class->from_struct($fact_struct) };
    die $@ unless $fact;
  }

  $self->_check_permissions($profile => submit => $fact);

  return $self->enqueue($fact, $profile);
}

sub enqueue {
  my ($self, $fact, $profile) = @_;
  return $self->librarian->store($fact, $profile);
}

1;
