package CPAN::Metabase::Gateway;
use Moose;

use CPAN::Metabase::Archive; # XXX: will be Librarian
use Data::GUID;

has fact_classes => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  auto_deref => 1,
  required   => 1,
);

has archive => (
  is       => 'ro',
  isa      => 'CPAN::Metabase::Archive', # XXX: will be Librarian
  required => 1,
);

sub _validate_dist {
  my ($self, $request) = @_;

  # XXX Well... yeah, eventually we'll want to reject reports for dists that
  # don't, you know, exist. -- rjbs, 2008-04-06
  1;
}

my %USER = map {; $_ => 1 } qw(rjbs dagolden);

sub handle {
  my ($self, $request) = @_;

  # XXX Yeah, uh, in the future this won't be a hashref. -- rjbs, 2008-04-06
  # ... or will it?  If this is being passed in by a Catalyst controller,
  # that's just fine. -- rjbs, 2008-04-06
  $request ||= {};

  die "unknown user" unless my $user = $USER{ $request->{user_id} };
  die "unknown dist" unless $self->_validate_dist($request);

  my $fact;
  FACT_CLASS: for my $fact_class ($self->fact_classes) {
    eval "require $fact_class; 1" or die;
    next FACT_CLASS unless $fact_class->type eq $request->{type};
    $fact = eval { $fact_class->new($request) };
    die $@ unless $fact;
  }

  $request->{guid} = Data::GUID->new;

  my $guid = $self->archive->store($fact);
}

1;
