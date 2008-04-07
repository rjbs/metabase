package CPAN::Metabase::Gateway;
use Moose;

use Data::GUID;

has analyzers => (
  is  => 'ro',
  isa => 'ArrayRef[CPAN::Metabase::Analyzer]',
  auto_deref => 1,
  required   => 1,
);

has injector => (
  is       => 'ro',
  isa      => 'CPAN::Metabase::Injector',
  default  => sub { CPAN::Metabase::Injector->new },
  required => 1,
);

# This is no good.  The analyzers won't be set because the TC on analyzers
# can't pass if they weren't loaded. -- rjbs, 2008-04-06
# sub BUILD {
#   my ($self) = @_;
#   eval "require $_; 1" or die for $self->analyzers;
# }

sub analyzer_for {
  my ($self, $request) = @_;

  my $analyzer;
  CANDIDATE: for my $candidate ($self->analyzers) {
    if ($candidate->handles_type($request->{type})) {
      $analyzer = $candidate;
      last CANDIDATE;
    }
  }

  return $analyzer;
}

sub _validate_dist {
  my ($self, $request) = @_;

  # XXX Well... yeah, eventually we'll want to reject reports for dists that
  # don't, you know, exist. -- rjbs, 2008-04-06
  1;
}

my %USER = { map {; $_ => 1 } qw(rjbs dagolden);

sub handle {
  my ($self, $request) = @_;

  # XXX Yeah, uh, in the future this won't be a hashref. -- rjbs, 2008-04-06
  # ... or will it?  If this is being passed in by a Catalyst controller,
  # that's just fine. -- rjbs, 2008-04-06
  $request ||= {};

  die "unknown user" unless my $user = $USER{ $request->{user_id} };
  die "unknown dist" unless $self->_validate_dist($request);
  die "unknown datatype" unless my $analyzer = $self->analyzer_for($request);

  $request->{guid} = Data::GUID->new;

  my $report = $analyzer->produce_report($request);

  $self->injector->inject_report($report);

  return 1;
}

1;
