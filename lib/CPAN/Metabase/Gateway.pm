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

sub _validate_dist {
  my ($self, $request) = @_;

  # XXX Well... yeah, eventually we'll want to reject reports for dists that
  # don't, you know, exist. -- rjbs, 2008-04-06
  1;
}

my %IS_USER = map {; $_ => 1 } qw(rjbs dagolden);

sub handle {
  my ($self, $request) = @_;

  $request ||= {};

  use Data::Dumper;
  local $SIG{__WARN__} = sub { warn "@_: " . Dumper($request); };
  die "unknown user: $request->{user_id}" unless $IS_USER{$request->{user_id}};
  die "unknown dist" unless $self->_validate_dist($request);

  my $user_id = delete $request->{user_id};
  my $type    = delete $request->{type};

  my $fact;
  FACT_CLASS: for my $fact_class ($self->fact_classes) {
    eval "require $fact_class; 1" or die;
    next FACT_CLASS unless $fact_class->type eq $type;
    $fact = eval { $fact_class->new($request) };
    die $@ unless $fact;
  }

  # $fact->mark_submitted(user_id => $user_id);

  my $guid = $self->librarian->store($fact, { user_id => $user_id });
}

1;
